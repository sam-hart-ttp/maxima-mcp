;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-linear.lisp - Linear systems and matrix construction tools
;;;
;;; Provides linear-algebra related tools used in the OU tutorials.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; linsolve - Solve linear system of equations
;;; ------------------------------------------------------------------

(define-mcp-tool "linsolve"
    (:description "Solve a linear system of equations using linsolve. Accepts equation list and variable list.")
  (("equations" "string" :description "List of equations, e.g. \"[x-4*y+2*z=9, 3*x-2*y+3*z=7]\"")
   ("variables" "string" :description "List of variables, e.g. \"[x,y,z]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eqs (get-argument arguments "equations"))
         (vars (get-argument arguments "variables"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eqs
      (signal-mcp-error +invalid-params+ "Missing required parameter: equations"))
    (unless vars
      (signal-mcp-error +invalid-params+ "Missing required parameter: variables"))
    (let ((expr (format nil "linsolve(~A, ~A)" eqs vars)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; fast_linsolve - Faster linear system solver
;;; ------------------------------------------------------------------

(define-mcp-tool "fast_linsolve"
    (:description "Solve a linear system with fast_linsolve (sparse-friendly).")
  (("equations" "string" :description "List of equations, e.g. \"[x-4*y+2*z=9, 3*x-2*y+3*z=7]\"")
   ("variables" "string" :description "List of variables, e.g. \"[x,y,z]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eqs (get-argument arguments "equations"))
         (vars (get-argument arguments "variables"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eqs
      (signal-mcp-error +invalid-params+ "Missing required parameter: equations"))
    (unless vars
      (signal-mcp-error +invalid-params+ "Missing required parameter: variables"))
    (let ((expr (format nil "fast_linsolve(~A, ~A)" eqs vars)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; augcoefmatrix - Augmented coefficient matrix
;;; ------------------------------------------------------------------

(define-mcp-tool "augcoefmatrix"
    (:description "Compute the augmented coefficient matrix for a system of equations.")
  (("equations" "string" :description "List of equations, e.g. \"[x-4*y+2*z=9, 3*x-2*y+3*z=7]\"")
   ("variables" "string" :description "List of variables, e.g. \"[x,y,z]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eqs (get-argument arguments "equations"))
         (vars (get-argument arguments "variables"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eqs
      (signal-mcp-error +invalid-params+ "Missing required parameter: equations"))
    (unless vars
      (signal-mcp-error +invalid-params+ "Missing required parameter: variables"))
    (let ((expr (format nil "augcoefmatrix(~A, ~A)" eqs vars)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; coefmatrix - Coefficient matrix
;;; ------------------------------------------------------------------

(define-mcp-tool "coefmatrix"
    (:description "Compute the coefficient matrix for a system of equations.")
  (("equations" "string" :description "List of equations, e.g. \"[x-4*y+2*z=9, 3*x-2*y+3*z=7]\"")
   ("variables" "string" :description "List of variables, e.g. \"[x,y,z]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eqs (get-argument arguments "equations"))
         (vars (get-argument arguments "variables"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eqs
      (signal-mcp-error +invalid-params+ "Missing required parameter: equations"))
    (unless vars
      (signal-mcp-error +invalid-params+ "Missing required parameter: variables"))
    (let ((expr (format nil "coefmatrix(~A, ~A)" eqs vars)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; addcol - Add column(s) to a matrix
;;; ------------------------------------------------------------------

(define-mcp-tool "addcol"
    (:description "Add column(s) to a matrix: addcol(M, list1, ...).")
  (("matrix" "string" :description "Matrix expression, e.g. \"matrix([1,2],[3,4])\"")
   ("columns" "array" :description "List of column vectors as strings, e.g. [\"[5,6]\", \"[7,8]\"]")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((matrix-str (get-argument arguments "matrix"))
         (cols (get-argument arguments "columns"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))
    (unless (and cols (listp cols))
      (signal-mcp-error +invalid-params+ "Missing required parameter: columns"))
    (let ((expr (format nil "addcol(~A, ~{~A~^, ~})" matrix-str cols)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; triangularize - Gaussian elimination
;;; ------------------------------------------------------------------

(define-mcp-tool "triangularize"
    (:description "Triangularize a matrix using Gaussian elimination.")
  (("matrix" "string" :description "Matrix expression")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))
    (let ((expr (format nil "triangularize(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; echelon - Echelon form
;;; ------------------------------------------------------------------

(define-mcp-tool "echelon"
    (:description "Compute the echelon form of a matrix.")
  (("matrix" "string" :description "Matrix expression")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))
    (let ((expr (format nil "echelon(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; matrix - Construct a matrix from rows
;;; ------------------------------------------------------------------

(define-mcp-tool "matrix"
    (:description "Construct a Maxima matrix from row lists.")
  (("rows" "array" :description "Row lists as strings, e.g. [\"[1,2]\", \"[3,4]\"]")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((rows (get-argument arguments "rows"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless (and rows (listp rows))
      (signal-mcp-error +invalid-params+ "Missing required parameter: rows"))
    (let ((expr (format nil "matrix(~{~A~^, ~})" rows)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
