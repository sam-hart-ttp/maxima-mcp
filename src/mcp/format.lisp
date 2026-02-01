;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; format.lisp - Output formatting for Maxima MCP
;;;
;;; Provides output formatting functions for converting Maxima expressions
;;; to various text formats: text (1D), latex, mathml, and lisp.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Text Format (1D linear display)
;;; ------------------------------------------------------------------

(defun format-as-text (expr)
  "Format a Maxima expression as plain text (1D linear format)."
  (with-output-to-string (s)
    (let ((maxima::$display2d nil))
      (maxima::mgrind expr s))))

;;; ------------------------------------------------------------------
;;; LaTeX Format
;;; ------------------------------------------------------------------

(defun format-as-latex (expr)
  "Format a Maxima expression as LaTeX."
  (maxima::$tex1 expr))

;;; ------------------------------------------------------------------
;;; MathML Format
;;; ------------------------------------------------------------------

(defvar *mathml-loaded* nil
  "Whether the MathML package has been loaded.")

(defun ensure-mathml-loaded ()
  "Ensure the MathML package is loaded."
  (unless *mathml-loaded*
    (handler-case
        (progn
          ;; Try to load the lurkmathml package
          (with-maxima-error-handling
            (maxima::mfuncall 'maxima::$load "mathml"))
          (setf *mathml-loaded* t))
      (error (e)
        (declare (ignore e))
        ;; MathML not available, will fall back to text
        nil))))

(defun format-as-mathml (expr)
  "Format a Maxima expression as MathML.
   Falls back to LaTeX if MathML package is not available."
  (ensure-mathml-loaded)
  (if *mathml-loaded*
      (handler-case
          ;; mathml(expr, nil) returns a string
          (let ((result (maxima::mfuncall 'maxima::$mathml expr nil)))
            (if (stringp result)
                result
                (format-as-latex expr)))
        (error ()
          (format-as-latex expr)))
      ;; Fall back to LaTeX
      (format-as-latex expr)))

;;; ------------------------------------------------------------------
;;; Lisp Format
;;; ------------------------------------------------------------------

(defun format-as-lisp (expr)
  "Format a Maxima expression as its Lisp representation."
  (prin1-to-string expr))

;;; ------------------------------------------------------------------
;;; Main Format Function
;;; ------------------------------------------------------------------

(defun format-result (expr format)
  "Format a Maxima expression EXPR according to FORMAT.
   FORMAT can be :text, :latex, :mathml, or :lisp."
  (handler-case
      (ecase format
        (:text (format-as-text expr))
        (:latex (format-as-latex expr))
        (:mathml (format-as-mathml expr))
        (:lisp (format-as-lisp expr)))
    (error (e)
      ;; Fall back to text on any error
      (handler-case
          (format-as-text expr)
        (error ()
          (format nil "~S" expr))))))

;;; ------------------------------------------------------------------
;;; Expression Type Detection
;;; ------------------------------------------------------------------

(defun maxima-list-p (expr)
  "Return T if EXPR is a Maxima list ((mlist) ...)."
  (and (consp expr)
       (consp (car expr))
       (eq (caar expr) 'maxima::mlist)))

(defun maxima-matrix-p (expr)
  "Return T if EXPR is a Maxima matrix ((mmatrix) ...)."
  (and (consp expr)
       (consp (car expr))
       (eq (caar expr) 'maxima::$matrix)))

(defun maxima-equation-p (expr)
  "Return T if EXPR is a Maxima equation ((mequal) lhs rhs)."
  (and (consp expr)
       (consp (car expr))
       (eq (caar expr) 'maxima::mequal)))

;;; ------------------------------------------------------------------
;;; Result Wrapping for JSON
;;; ------------------------------------------------------------------

(defun format-result-for-json (expr format &optional include-all-formats)
  "Format EXPR for JSON response.
   If INCLUDE-ALL-FORMATS is true, include all formats in the response."
  (if include-all-formats
      (make-json-object
       "text" (format-result expr :text)
       "latex" (format-result expr :latex)
       "lisp" (format-result expr :lisp))
      (format-result expr format)))

(defun wrap-tool-result (result &key format (is-error nil) error-message)
  "Wrap a tool result for MCP response.
   RESULT is the Maxima expression.
   FORMAT is the output format (:text, :latex, etc.).
   IS-ERROR indicates if this is an error result.
   ERROR-MESSAGE is the error message if IS-ERROR is true."
  (if is-error
      (make-json-object
       "isError" t
       "content" (list (make-json-object
                        "type" "text"
                        "text" (or error-message "Unknown error"))))
      (let ((formatted (format-result result format)))
        (make-json-object
         "content" (list (make-json-object
                          "type" "text"
                          "text" formatted))))))
