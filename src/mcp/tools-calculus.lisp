;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-calculus.lisp - Calculus tools for Maxima MCP
;;;
;;; Provides calculus-related tools: differentiate, integrate, limit,
;;; taylor, sum, and product.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; differentiate - Symbolic differentiation
;;; ------------------------------------------------------------------

(define-mcp-tool "differentiate"
    (:description "Compute the derivative of an expression with respect to a variable. Supports higher-order derivatives.")
  (("expression" "string" :description "The expression to differentiate (e.g., \"x^3\", \"sin(x)*cos(x)\")")
   ("variable" "string" :description "The variable to differentiate with respect to (e.g., \"x\")")
   ("order" "number" :description "Order of differentiation (default 1)" :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (var-str (get-argument arguments "variable"))
         (order (get-argument arguments "order" 1))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))

    (let ((diff-expr (if (and order (> order 1))
                         (format nil "diff(~A, ~A, ~A)" expr-str var-str order)
                         (format nil "diff(~A, ~A)" expr-str var-str))))
      (multiple-value-bind (result err) (parse-and-eval diff-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; integrate - Symbolic integration
;;; ------------------------------------------------------------------

(define-mcp-tool "integrate"
    (:description "Compute the integral of an expression. Supports both indefinite and definite integrals.")
  (("expression" "string" :description "The expression to integrate (e.g., \"x^2\", \"sin(x)\")")
   ("variable" "string" :description "The variable of integration (e.g., \"x\")")
   ("lower" "string" :description "Lower limit for definite integral (e.g., \"0\", \"-inf\")" :required nil)
   ("upper" "string" :description "Upper limit for definite integral (e.g., \"1\", \"inf\")" :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (var-str (get-argument arguments "variable"))
         (lower (get-argument arguments "lower"))
         (upper (get-argument arguments "upper"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))

    (let ((int-expr (if (and lower upper)
                        (format nil "integrate(~A, ~A, ~A, ~A)"
                                expr-str var-str lower upper)
                        (format nil "integrate(~A, ~A)" expr-str var-str))))
      (multiple-value-bind (result err) (parse-and-eval int-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; limit - Compute limits
;;; ------------------------------------------------------------------

(define-mcp-tool "limit"
    (:description "Compute the limit of an expression as a variable approaches a value.")
  (("expression" "string" :description "The expression to take the limit of")
   ("variable" "string" :description "The variable approaching the limit point")
   ("point" "string" :description "The point to approach (e.g., \"0\", \"inf\", \"minf\")")
   ("direction" "string" :description "Direction: plus (from above), minus (from below), or omit for both" :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (var-str (get-argument arguments "variable"))
         (point-str (get-argument arguments "point"))
         (direction (get-argument arguments "direction"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless point-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: point"))

    (let ((limit-expr (if direction
                          (format nil "limit(~A, ~A, ~A, ~A)"
                                  expr-str var-str point-str direction)
                          (format nil "limit(~A, ~A, ~A)"
                                  expr-str var-str point-str))))
      (multiple-value-bind (result err) (parse-and-eval limit-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; taylor - Taylor series expansion
;;; ------------------------------------------------------------------

(define-mcp-tool "taylor"
    (:description "Compute the Taylor series expansion of an expression around a point.")
  (("expression" "string" :description "The expression to expand")
   ("variable" "string" :description "The variable of expansion")
   ("point" "string" :description "The point around which to expand (e.g., \"0\")")
   ("order" "number" :description "The order of the expansion (number of terms)")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (var-str (get-argument arguments "variable"))
         (point-str (get-argument arguments "point"))
         (order (get-argument arguments "order"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless point-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: point"))
    (unless order
      (signal-mcp-error +invalid-params+ "Missing required parameter: order"))

    (let ((taylor-expr (format nil "taylor(~A, ~A, ~A, ~A)"
                               expr-str var-str point-str order)))
      (multiple-value-bind (result err) (parse-and-eval taylor-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; sum - Symbolic summation
;;; ------------------------------------------------------------------

(define-mcp-tool "sum"
    (:description "Compute a symbolic sum. Can compute both finite sums and infinite series.")
  (("expression" "string" :description "The expression to sum (the summand)")
   ("variable" "string" :description "The index variable of summation")
   ("lower" "string" :description "Lower limit of summation (e.g., \"1\", \"0\")")
   ("upper" "string" :description "Upper limit of summation (e.g., \"n\", \"inf\")")
   ("simpsum" "boolean" :description "If true, attempt to find a closed-form result" :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (var-str (get-argument arguments "variable"))
         (lower-str (get-argument arguments "lower"))
         (upper-str (get-argument arguments "upper"))
         (simpsum (get-argument arguments "simpsum"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless lower-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: lower"))
    (unless upper-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: upper"))

    (let ((sum-expr (if simpsum
                        (format nil "(simpsum:true, sum(~A, ~A, ~A, ~A))"
                                expr-str var-str lower-str upper-str)
                        (format nil "sum(~A, ~A, ~A, ~A)"
                                expr-str var-str lower-str upper-str))))
      (multiple-value-bind (result err) (parse-and-eval sum-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; product - Symbolic product
;;; ------------------------------------------------------------------

(define-mcp-tool "product"
    (:description "Compute a symbolic product.")
  (("expression" "string" :description "The expression to multiply (the factor)")
   ("variable" "string" :description "The index variable")
   ("lower" "string" :description "Lower limit")
   ("upper" "string" :description "Upper limit")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (var-str (get-argument arguments "variable"))
         (lower-str (get-argument arguments "lower"))
         (upper-str (get-argument arguments "upper"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless lower-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: lower"))
    (unless upper-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: upper"))

    (let ((prod-expr (format nil "product(~A, ~A, ~A, ~A)"
                             expr-str var-str lower-str upper-str)))
      (multiple-value-bind (result err) (parse-and-eval prod-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; laplace - Laplace transform
;;; ------------------------------------------------------------------

(define-mcp-tool "laplace"
    (:description "Compute the Laplace transform of an expression.")
  (("expression" "string" :description "The expression to transform")
   ("t_var" "string" :description "The time-domain variable (typically t)")
   ("s_var" "string" :description "The frequency-domain variable (typically s)")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (t-var (get-argument arguments "t_var"))
         (s-var (get-argument arguments "s_var"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless t-var
      (signal-mcp-error +invalid-params+ "Missing required parameter: t_var"))
    (unless s-var
      (signal-mcp-error +invalid-params+ "Missing required parameter: s_var"))

    (let ((laplace-expr (format nil "laplace(~A, ~A, ~A)" expr-str t-var s-var)))
      (multiple-value-bind (result err) (parse-and-eval laplace-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; ilt - Inverse Laplace transform
;;; ------------------------------------------------------------------

(define-mcp-tool "ilt"
    (:description "Compute the inverse Laplace transform of an expression.")
  (("expression" "string" :description "The expression to inverse transform")
   ("s_var" "string" :description "The frequency-domain variable (typically s)")
   ("t_var" "string" :description "The time-domain variable (typically t)")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (s-var (get-argument arguments "s_var"))
         (t-var (get-argument arguments "t_var"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless s-var
      (signal-mcp-error +invalid-params+ "Missing required parameter: s_var"))
    (unless t-var
      (signal-mcp-error +invalid-params+ "Missing required parameter: t_var"))

    (let ((ilt-expr (format nil "ilt(~A, ~A, ~A)" expr-str s-var t-var)))
      (multiple-value-bind (result err) (parse-and-eval ilt-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
