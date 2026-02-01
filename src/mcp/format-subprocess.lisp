;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; format-subprocess.lisp - Output formatting for subprocess-based testing
;;;
;;; Standalone formatting that uses Maxima subprocess for conversions.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Text Format (default from subprocess)
;;; ------------------------------------------------------------------

(defun format-as-text (expr)
  "Return expression as-is (already text from subprocess)."
  (if (stringp expr)
      expr
      (format nil "~A" expr)))

;;; ------------------------------------------------------------------
;;; LaTeX Format
;;; ------------------------------------------------------------------

(defun format-as-latex (expr)
  "Convert to LaTeX using Maxima's tex() function."
  (multiple-value-bind (result err)
      (subprocess-eval (format nil "tex1(~A)" expr))
    (if err
        (format-as-text expr)
        result)))

;;; ------------------------------------------------------------------
;;; MathML Format
;;; ------------------------------------------------------------------

(defun format-as-mathml (expr)
  "Convert to MathML. Falls back to LaTeX if not available."
  ;; Try loading mathml and using it
  (multiple-value-bind (result err)
      (subprocess-eval (format nil "(load(mathml), mathml(~A, false))" expr))
    (if (or err (string= result "false"))
        (format-as-latex expr)
        result)))

;;; ------------------------------------------------------------------
;;; Lisp Format
;;; ------------------------------------------------------------------

(defun format-as-lisp (expr)
  "Return the Lisp representation."
  (if (stringp expr)
      expr
      (format nil "~S" expr)))

;;; ------------------------------------------------------------------
;;; Main Format Function
;;; ------------------------------------------------------------------

(defun format-result (expr format)
  "Format expression EXPR according to FORMAT."
  (handler-case
      (ecase format
        (:text (format-as-text expr))
        (:latex (format-as-latex expr))
        (:mathml (format-as-mathml expr))
        (:lisp (format-as-lisp expr)))
    (error (e)
      (declare (ignore e))
      (format-as-text expr))))

;;; ------------------------------------------------------------------
;;; Expression Type Detection (simplified for subprocess)
;;; ------------------------------------------------------------------

(defun maxima-list-p (expr)
  (and (stringp expr) (search "[" expr)))

(defun maxima-matrix-p (expr)
  (and (stringp expr) (search "matrix" expr)))

(defun maxima-equation-p (expr)
  (and (stringp expr) (search "=" expr)))

;;; ------------------------------------------------------------------
;;; Result Wrapping for JSON
;;; ------------------------------------------------------------------

(defun format-result-for-json (expr format &optional include-all-formats)
  (if include-all-formats
      (make-json-object
       "text" (format-result expr :text)
       "latex" (format-result expr :latex)
       "lisp" (format-result expr :lisp))
      (format-result expr format)))

(defun wrap-tool-result (result &key format (is-error nil) error-message)
  (if is-error
      (make-json-object
       "isError" t
       "content" (list (make-json-object
                        "type" "text"
                        "text" (or error-message "Unknown error"))))
      (let ((formatted (if (eq format :text)
                           result  ; Already formatted from subprocess
                           (format-result result format))))
        (make-json-object
         "content" (list (make-json-object
                          "type" "text"
                          "text" formatted))))))
