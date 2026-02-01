;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-matrix.lisp - Matrix tools for Maxima MCP
;;;
;;; Provides matrix operation tools: determinant, invert, eigenvalues,
;;; eigenvectors, transpose, and matrix arithmetic.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; determinant - Matrix determinant
;;; ------------------------------------------------------------------

(define-mcp-tool "determinant"
    (:description "Compute the determinant of a square matrix.")
  (("matrix" "string" :description "The matrix as a Maxima matrix expression (e.g., \"matrix([1,2],[3,4])\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    (let ((det-expr (format nil "determinant(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval det-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; invert - Matrix inverse
;;; ------------------------------------------------------------------

(define-mcp-tool "invert"
    (:description "Compute the inverse of a square matrix.")
  (("matrix" "string" :description "The matrix to invert (e.g., \"matrix([1,2],[3,4])\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    (let ((inv-expr (format nil "invert(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval inv-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; eigenvalues - Matrix eigenvalues
;;; ------------------------------------------------------------------

(define-mcp-tool "eigenvalues"
    (:description "Compute the eigenvalues of a square matrix. Returns a list of eigenvalues and their multiplicities.")
  (("matrix" "string" :description "The matrix to find eigenvalues for")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    (let ((eig-expr (format nil "eigenvalues(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval eig-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; eigenvectors - Matrix eigenvectors
;;; ------------------------------------------------------------------

(define-mcp-tool "eigenvectors"
    (:description "Compute the eigenvectors and eigenvalues of a square matrix.")
  (("matrix" "string" :description "The matrix to find eigenvectors for")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    (let ((eig-expr (format nil "eigenvectors(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval eig-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; transpose - Matrix transpose
;;; ------------------------------------------------------------------

(define-mcp-tool "transpose"
    (:description "Compute the transpose of a matrix.")
  (("matrix" "string" :description "The matrix to transpose")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    (let ((trans-expr (format nil "transpose(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval trans-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; matrix_multiply - Matrix multiplication
;;; ------------------------------------------------------------------

(define-mcp-tool "matrix_multiply"
    (:description "Multiply two matrices together using the dot operator (A . B).")
  (("matrix1" "string" :description "The first matrix")
   ("matrix2" "string" :description "The second matrix")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((m1-str (get-argument arguments "matrix1"))
         (m2-str (get-argument arguments "matrix2"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless m1-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix1"))
    (unless m2-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix2"))

    (let ((mult-expr (format nil "(~A) . (~A)" m1-str m2-str)))
      (multiple-value-bind (result err) (parse-and-eval mult-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; rank - Matrix rank
;;; ------------------------------------------------------------------

(define-mcp-tool "rank"
    (:description "Compute the rank of a matrix.")
  (("matrix" "string" :description "The matrix to compute the rank of")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    (let ((rank-expr (format nil "rank(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval rank-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; charpoly - Characteristic polynomial
;;; ------------------------------------------------------------------

(define-mcp-tool "charpoly"
    (:description "Compute the characteristic polynomial of a square matrix.")
  (("matrix" "string" :description "The matrix to compute the characteristic polynomial of")
   ("variable" "string" :description "The variable for the polynomial (typically x or lambda)")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (var-str (get-argument arguments "variable"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))

    (let ((char-expr (format nil "charpoly(~A, ~A)" matrix-str var-str)))
      (multiple-value-bind (result err) (parse-and-eval char-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; trace_matrix - Matrix trace
;;; ------------------------------------------------------------------

(define-mcp-tool "trace_matrix"
    (:description "Compute the trace (sum of diagonal elements) of a square matrix.")
  (("matrix" "string" :description "The matrix to compute the trace of")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    ;; Note: Maxima's trace function is called mattrace
    (let ((trace-expr (format nil "mattrace(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval trace-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; solve_linear - Solve linear system
;;; ------------------------------------------------------------------

(define-mcp-tool "solve_linear"
    (:description "Solve a system of linear equations Ax = b.")
  (("matrix" "string" :description "The coefficient matrix A")
   ("vector" "string" :description "The right-hand side vector b (as a column matrix)")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (vector-str (get-argument arguments "vector"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))
    (unless vector-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: vector"))

    ;; Use linsolve for linear systems
    (let ((solve-expr (format nil "invert(~A) . (~A)" matrix-str vector-str)))
      (multiple-value-bind (result err) (parse-and-eval solve-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; nullspace - Null space of a matrix
;;; ------------------------------------------------------------------

(define-mcp-tool "nullspace"
    (:description "Compute the null space (kernel) of a matrix.")
  (("matrix" "string" :description "The matrix to compute the null space of")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((matrix-str (get-argument arguments "matrix"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless matrix-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: matrix"))

    (let ((null-expr (format nil "nullspace(~A)" matrix-str)))
      (multiple-value-bind (result err) (parse-and-eval null-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
