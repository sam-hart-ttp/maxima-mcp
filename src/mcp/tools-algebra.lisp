;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-algebra.lisp - Algebra tools for Maxima MCP
;;;
;;; Provides algebraic manipulation tools: simplify, factor, expand, ratsimp.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; simplify - General simplification
;;; ------------------------------------------------------------------

(define-mcp-tool "simplify"
    (:description "Simplify an expression using rational simplification (ratsimp). This applies algebraic simplifications including combining fractions and simplifying rational expressions.")
  (("expression" "string" :description "The expression to simplify")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((simp-expr (format nil "ratsimp(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval simp-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; factor - Factor polynomials
;;; ------------------------------------------------------------------

(define-mcp-tool "factor"
    (:description "Factor a polynomial or rational expression into irreducible factors over the integers.")
  (("expression" "string" :description "The expression to factor (e.g., \"x^2-4\", \"x^3-1\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((factor-expr (format nil "factor(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval factor-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; expand - Expand expressions
;;; ------------------------------------------------------------------

(define-mcp-tool "expand"
    (:description "Expand an expression by multiplying out products and powers.")
  (("expression" "string" :description "The expression to expand (e.g., \"(x+1)^3\", \"(a+b)*(c+d)\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((expand-expr (format nil "expand(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval expand-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; ratsimp - Rational simplification
;;; ------------------------------------------------------------------

(define-mcp-tool "ratsimp"
    (:description "Simplify an expression by putting it over a common denominator and canceling common factors.")
  (("expression" "string" :description "The expression to simplify rationally")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((ratsimp-expr (format nil "ratsimp(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval ratsimp-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; trigsimp - Trigonometric simplification
;;; ------------------------------------------------------------------

(define-mcp-tool "trigsimp"
    (:description "Simplify trigonometric expressions using trigonometric identities.")
  (("expression" "string" :description "The trigonometric expression to simplify")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((trig-expr (format nil "trigsimp(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval trig-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; trigexpand - Expand trigonometric expressions
;;; ------------------------------------------------------------------

(define-mcp-tool "trigexpand"
    (:description "Expand trigonometric functions of sums and multiples of angles.")
  (("expression" "string" :description "The trigonometric expression to expand (e.g., \"sin(a+b)\", \"cos(2*x)\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((trig-expr (format nil "trigexpand(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval trig-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; trigreduce - Reduce trigonometric powers
;;; ------------------------------------------------------------------

(define-mcp-tool "trigreduce"
    (:description "Reduce powers and products of trigonometric functions to linear form using multiple angle formulas.")
  (("expression" "string" :description "The trigonometric expression to reduce (e.g., \"sin(x)^2\", \"sin(x)*cos(x)\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((trig-expr (format nil "trigreduce(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval trig-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; radcan - Simplify radicals and logarithms
;;; ------------------------------------------------------------------

(define-mcp-tool "radcan"
    (:description "Simplify expressions containing radicals, exponentials, and logarithms using canonical forms.")
  (("expression" "string" :description "The expression containing radicals/logs to simplify")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((rad-expr (format nil "radcan(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval rad-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; partfrac - Partial fraction decomposition
;;; ------------------------------------------------------------------

(define-mcp-tool "partfrac"
    (:description "Compute the partial fraction decomposition of a rational expression.")
  (("expression" "string" :description "The rational expression to decompose")
   ("variable" "string" :description "The variable with respect to which to decompose")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (var-str (get-argument arguments "variable"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))

    (let ((pf-expr (format nil "partfrac(~A, ~A)" expr-str var-str)))
      (multiple-value-bind (result err) (parse-and-eval pf-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; gcd - Greatest common divisor of polynomials
;;; ------------------------------------------------------------------

(define-mcp-tool "gcd"
    (:description "Compute the greatest common divisor of two polynomial expressions.")
  (("expr1" "string" :description "First polynomial")
   ("expr2" "string" :description "Second polynomial")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr1-str (get-argument arguments "expr1"))
         (expr2-str (get-argument arguments "expr2"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr1-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expr1"))
    (unless expr2-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expr2"))

    (let ((gcd-expr (format nil "gcd(~A, ~A)" expr1-str expr2-str)))
      (multiple-value-bind (result err) (parse-and-eval gcd-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; subst - Substitute values
;;; ------------------------------------------------------------------

(define-mcp-tool "subst"
    (:description "Substitute a value for a variable in an expression.")
  (("replacement" "string" :description "The replacement value or expression")
   ("variable" "string" :description "The variable to replace")
   ("expression" "string" :description "The expression in which to make the substitution")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((repl-str (get-argument arguments "replacement"))
         (var-str (get-argument arguments "variable"))
         (expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless repl-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: replacement"))
    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((subst-expr (format nil "subst(~A, ~A, ~A)" repl-str var-str expr-str)))
      (multiple-value-bind (result err) (parse-and-eval subst-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
