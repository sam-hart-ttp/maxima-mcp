;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; maxima-subprocess.lisp - Subprocess-based Maxima backend for testing
;;;
;;; This module provides an alternative backend that communicates with
;;; Maxima as a subprocess. Used for testing when Maxima isn't available
;;; as a library.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Variables
;;; ------------------------------------------------------------------

(defvar *maxima-process* nil
  "The Maxima subprocess.")

(defvar *maxima-input* nil
  "Input stream to Maxima subprocess.")

(defvar *maxima-output* nil
  "Output stream from Maxima subprocess.")

;;; ------------------------------------------------------------------
;;; Low-level Process Functions
;;; ------------------------------------------------------------------

(defun launch-maxima-process ()
  "Launch Maxima as a subprocess. Returns (process input-stream output-stream)."
  #+sbcl
  (let ((process (sb-ext:run-program "maxima"
                                      nil  ; No args - we'll configure inline
                                      :input :stream
                                      :output :stream
                                      :error :output
                                      :wait nil
                                      :search t)))
    (values process
            (sb-ext:process-input process)
            (sb-ext:process-output process)))
  #-sbcl
  (error "Subprocess backend only implemented for SBCL"))

;;; ------------------------------------------------------------------
;;; Low-level I/O Functions
;;; ------------------------------------------------------------------

(defun read-maxima-line ()
  "Read a single line from Maxima output."
  (read-line *maxima-output* nil ""))

(defun write-to-maxima (input)
  "Write INPUT string to Maxima (without checking if process is running)."
  (write-string input *maxima-input*)
  (terpri *maxima-input*)
  (finish-output *maxima-input*))

(defun skip-until-prompt ()
  "Skip lines until we see an input prompt (%iN)."
  (loop for line = (read-maxima-line)
        until (and (>= (length line) 3)
                   (string= (subseq line 0 3) "(%i"))
        finally (return line)))

(defun read-maxima-result ()
  "Read the result from Maxima (the (%oN) line) and return just the value.
   Skips to the next input prompt."
  (let ((result-line (read-maxima-line)))
    ;; Result line looks like: (%oN) value  or just empty
    ;; Skip to next prompt
    (skip-until-prompt)
    ;; Extract value from result line
    (if (and (>= (length result-line) 5)
             (string= (subseq result-line 0 3) "(%o"))
        ;; Find the closing ) and space, extract the rest
        (let ((paren-pos (position #\) result-line :start 3)))
          (if paren-pos
              (string-trim '(#\Space #\Tab #\Newline #\Return)
                           (subseq result-line (1+ paren-pos)))
              result-line))
        (string-trim '(#\Space #\Tab #\Newline #\Return) result-line))))

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
    #+sbcl
    (ignore-errors
      (sb-ext:process-close *maxima-process*))
    (setf *maxima-process* nil
          *maxima-input* nil
          *maxima-output* nil)))

(defun ensure-maxima-subprocess ()
  "Ensure the Maxima subprocess is running."
  (unless (and *maxima-process*
               #+sbcl (sb-ext:process-alive-p *maxima-process*))
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
        (ensure-maxima-subprocess)
        ;; Send expression (ensure it ends with ; or $)
        (let ((trimmed (string-trim '(#\Space #\Tab #\Newline) expr-string)))
          (when (zerop (length trimmed))
            (return-from subprocess-eval (values "" nil)))
          (unless (or (char= (char trimmed (1- (length trimmed))) #\;)
                      (char= (char trimmed (1- (length trimmed))) #\$))
            (setf trimmed (concatenate 'string trimmed ";")))
          (write-to-maxima trimmed))
        ;; Read result
        (let ((output (read-maxima-result)))
          ;; Check for error markers in output
          (if (or (search "error" output :test #'char-equal)
                  (search "incorrect" output :test #'char-equal))
              (values nil output)
              (values output nil))))
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
