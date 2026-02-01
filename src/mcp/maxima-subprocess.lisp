;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; maxima-subprocess.lisp - Subprocess-based Maxima backend for testing
;;;
;;; This module provides an alternative backend that communicates with
;;; Maxima as a subprocess. Used for testing when Maxima isn't available
;;; as a library.

(in-package :maxima-mcp)

;; Ensure UIOP is available for portable process management
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf))

;;; ------------------------------------------------------------------
;;; Variables
;;; ------------------------------------------------------------------

(defvar *maxima-process* nil
  "The Maxima subprocess.")

(defvar *maxima-input* nil
  "Input stream to Maxima subprocess.")

(defvar *maxima-output* nil
  "Output stream from Maxima subprocess.")

(defvar *maxima-subprocess-debug*
  (uiop:getenv "MAXIMA_MCP_SUBPROCESS_DEBUG")
  "When set, logs raw subprocess output for debugging.")

(defvar *maxima-subprocess-mode*
  (or (uiop:getenv "MAXIMA_MCP_SUBPROCESS_MODE") "batch")
  "Subprocess mode: \"batch\" (default) or \"interactive\".")

;;; ------------------------------------------------------------------
;;; Low-level Process Functions
;;; ------------------------------------------------------------------

(defun launch-maxima-process ()
  "Launch Maxima as a subprocess. Returns (process input-stream output-stream)."
  (let ((process (uiop:launch-program
                  '("maxima")
                  :input :stream
                  :output :stream
                  :error-output :output
                  :wait nil)))
    (values process
            (uiop:process-info-input process)
            (uiop:process-info-output process))))

;;; ------------------------------------------------------------------
;;; Low-level I/O Functions
;;; ------------------------------------------------------------------

(defun string-suffix-p (suffix str)
  "Return true if STR ends with SUFFIX."
  (let ((ls (length suffix))
        (l (length str)))
    (and (>= l ls)
         (string= suffix (subseq str (- l ls))))))

(defun read-until-prompt (&key (count 1))
  "Read from Maxima output until COUNT prompts are seen. Returns all output."
  (let ((buf (make-string-output-stream))
        (tail "")
        (seen 0))
    (loop for ch = (read-char *maxima-output* nil nil)
          while ch do
            (write-char ch buf)
            (setf tail (concatenate 'string tail (string ch)))
            (when (> (length tail) 32)
              (setf tail (subseq tail (- (length tail) 32))))
            (when (and (search "(%i" tail)
                       (or (string-suffix-p ") " tail)
                           (string-suffix-p ")~%" tail)
                           (string-suffix-p ")" tail)))
              (incf seen)
              (when (>= seen count)
                (return (get-output-stream-string buf)))))
    (get-output-stream-string buf)))

(defun write-to-maxima (input)
  "Write INPUT string to Maxima (without checking if process is running)."
  (write-string input *maxima-input*)
  (terpri *maxima-input*)
  (finish-output *maxima-input*))

(defun skip-until-prompt ()
  "Skip output until we see an input prompt (%iN)."
  (read-until-prompt :count 1))

(defun read-maxima-result ()
  "Read output until the next prompt and return the last (%oN) value."
  (let* ((output (read-until-prompt :count 2))
         (prompt-pos (search "(%i" output :from-end t))
         (body (if prompt-pos (subseq output 0 prompt-pos) output))
         (o-pos (search "(%o" body :from-end t)))
    (when *maxima-subprocess-debug*
      (format *error-output* "~%[maxima-subprocess] raw output:~%~A~%" output))
    (if o-pos
        (let* ((paren-pos (position #\) body :start (+ o-pos 3))))
          (if paren-pos
              (string-trim '(#\Space #\Tab #\Newline #\Return)
                           (subseq body (1+ paren-pos)))
              (string-trim '(#\Space #\Tab #\Newline #\Return)
                           (subseq body (+ o-pos 3)))))
        (string-trim '(#\Space #\Tab #\Newline #\Return) body))))

;;; ------------------------------------------------------------------
;;; Subprocess Management
;;; ------------------------------------------------------------------

(defun start-maxima-subprocess ()
  "Start the Maxima subprocess."
  (unless *maxima-process*
    (multiple-value-bind (process input output)
        (launch-maxima-process)
      (setf *maxima-process* process
            *maxima-input* input
            *maxima-output* output)
      ;; Wait for initial prompt (skip banner)
      (skip-until-prompt)
      ;; Configure Maxima for batch operation
      (write-to-maxima "display2d:false$")
      (skip-until-prompt)
      (write-to-maxima "linel:10000$")
      (skip-until-prompt))))

(defun stop-maxima-subprocess ()
  "Stop the Maxima subprocess."
  (when *maxima-process*
    (ignore-errors
      (write-to-maxima "quit();"))
    (ignore-errors
      (uiop:terminate-process *maxima-process*))
    (ignore-errors
      (uiop:wait-process *maxima-process*))
    (setf *maxima-process* nil
          *maxima-input* nil
          *maxima-output* nil)))

(defun ensure-maxima-subprocess ()
  "Ensure the Maxima subprocess is running."
  (unless (and *maxima-process*
               (uiop:process-alive-p *maxima-process*))
    (start-maxima-subprocess)))

;;; ------------------------------------------------------------------
;;; High-level Communication
;;; ------------------------------------------------------------------

(defun send-to-maxima (input)
  "Send INPUT string to Maxima (ensures subprocess is running)."
  (ensure-maxima-subprocess)
  (write-to-maxima input))

;;; ------------------------------------------------------------------
;;; Evaluation via Subprocess
;;; ------------------------------------------------------------------

(defun subprocess-eval (expr-string)
  "Evaluate EXPR-STRING via the Maxima subprocess.
   Returns (values result-string error-string)."
  (handler-case
      (progn
        (let ((trimmed (string-trim '(#\Space #\Tab #\Newline) expr-string)))
          (when (zerop (length trimmed))
            (return-from subprocess-eval (values "" nil)))
          (unless (or (char= (char trimmed (1- (length trimmed))) #\;)
                      (char= (char trimmed (1- (length trimmed))) #\$))
            (setf trimmed (concatenate 'string trimmed ";")))
          (if (string= *maxima-subprocess-mode* "interactive")
              (progn
                (ensure-maxima-subprocess)
                (write-to-maxima trimmed)
                (let ((output (read-maxima-result)))
                  (if (or (search "error" output :test #'char-equal)
                          (search "incorrect" output :test #'char-equal))
                      (values nil output)
                      (values output nil))))
              (let* ((batch-expr (format nil "display2d:false$~A" trimmed))
                     (cmd (list "maxima" "-q" "--batch-string" batch-expr))
                     (out (uiop:run-program cmd :output :string :error-output :string :ignore-error-status t))
                     (o-pos (search "(%o" out :from-end t)))
                (when *maxima-subprocess-debug*
                  (format *error-output* "~%[maxima-subprocess] batch output:~%~A~%" out))
                (if (or (search "error" out :test #'char-equal)
                        (search "incorrect" out :test #'char-equal))
                    (values nil out)
                    (if o-pos
                        (let* ((paren-pos (position #\) out :start (+ o-pos 3))))
                          (if paren-pos
                              (values (string-trim '(#\Space #\Tab #\Newline #\Return)
                                                   (subseq out (1+ paren-pos)))
                                      nil)
                              (values (string-trim '(#\Space #\Tab #\Newline #\Return) out) nil)))
                        (values (string-trim '(#\Space #\Tab #\Newline #\Return) out) nil)))))))
    (error (e)
      (values nil (format nil "Subprocess error: ~A" e)))))

;;; ------------------------------------------------------------------
;;; Test Function
;;; ------------------------------------------------------------------

(defun test-subprocess ()
  "Test the subprocess backend."
  (format t "Testing Maxima subprocess backend...~%~%")

  (handler-case
      (progn
        (start-maxima-subprocess)

        ;; Test 1: Simple arithmetic
        (format t "1. Testing 2+2...~%")
        (multiple-value-bind (result err) (subprocess-eval "2+2")
          (format t "   Result: ~A~%   Error: ~A~%~%" result err))

        ;; Test 2: Differentiation
        (format t "2. Testing diff(x^3, x)...~%")
        (multiple-value-bind (result err) (subprocess-eval "diff(x^3, x)")
          (format t "   Result: ~A~%   Error: ~A~%~%" result err))

        ;; Test 3: Integration
        (format t "3. Testing integrate(x^2, x)...~%")
        (multiple-value-bind (result err) (subprocess-eval "integrate(x^2, x)")
          (format t "   Result: ~A~%   Error: ~A~%~%" result err))

        ;; Test 4: Solve
        (format t "4. Testing solve(x^2-4=0, x)...~%")
        (multiple-value-bind (result err) (subprocess-eval "solve(x^2-4=0, x)")
          (format t "   Result: ~A~%   Error: ~A~%~%" result err))

        ;; Test 5: Factor
        (format t "5. Testing factor(x^2-1)...~%")
        (multiple-value-bind (result err) (subprocess-eval "factor(x^2-1)")
          (format t "   Result: ~A~%   Error: ~A~%~%" result err))

        ;; Test 6: TeX output
        (format t "6. Testing tex1(integrate(x^2,x))...~%")
        (multiple-value-bind (result err) (subprocess-eval "tex1(integrate(x^2,x))")
          (format t "   Result: ~A~%   Error: ~A~%~%" result err))

        (format t "Tests complete!~%")
        (stop-maxima-subprocess))
    (error (e)
      (format t "Test failed: ~A~%" e)
      (stop-maxima-subprocess))))
