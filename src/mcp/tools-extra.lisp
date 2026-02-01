;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-extra.lisp - Additional utilities from OU guides/manual
;;;
;;; Provides roots, simplification, list ops, and numerical tools.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; fullratsimp - Full rational simplification
;;; ------------------------------------------------------------------

(define-mcp-tool "fullratsimp"
    (:description "Fully simplify rational expressions (fullratsimp).")
  (("expression" "string" :description "Expression to simplify")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (format nil "fullratsimp(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; logcontract - Combine logarithms
;;; ------------------------------------------------------------------

(define-mcp-tool "logcontract"
    (:description "Combine logarithms (logcontract).")
  (("expression" "string" :description "Expression to contract")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (format nil "logcontract(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; trigrat - Simplify trig ratios
;;; ------------------------------------------------------------------

(define-mcp-tool "trigrat"
    (:description "Simplify trigonometric ratios (trigrat).")
  (("expression" "string" :description "Expression to simplify")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (format nil "trigrat(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; realroots / allroots - Polynomial roots
;;; ------------------------------------------------------------------

(define-mcp-tool "realroots"
    (:description "Find real roots of a polynomial (realroots).")
  (("expression" "string" :description "Polynomial expression")
   ("epsilon" "number" :description "Tolerance (optional)" :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (eps (get-argument arguments "epsilon"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (if eps
                    (format nil "realroots(~A, ~A)" expr eps)
                    (format nil "realroots(~A)" expr))))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "allroots"
    (:description "Find all roots of a polynomial (allroots).")
  (("expression" "string" :description "Polynomial expression")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (format nil "allroots(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "multiplicities"
    (:description "Get multiplicities from the last solve/roots operation.")
  (("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (multiple-value-bind (result err) (parse-and-eval "multiplicities")
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

;;; ------------------------------------------------------------------
;;; rhs / lhs - Equation sides
;;; ------------------------------------------------------------------

(define-mcp-tool "rhs"
    (:description "Right-hand side of an equation.")
  (("equation" "string" :description "Equation, e.g. \"x=1\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eq (get-argument arguments "equation"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eq
      (signal-mcp-error +invalid-params+ "Missing required parameter: equation"))
    (let ((call (format nil "rhs(~A)" eq)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "lhs"
    (:description "Left-hand side of an equation.")
  (("equation" "string" :description "Equation, e.g. \"x=1\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eq (get-argument arguments "equation"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eq
      (signal-mcp-error +invalid-params+ "Missing required parameter: equation"))
    (let ((call (format nil "lhs(~A)" eq)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; map - Apply a function to a list
;;; ------------------------------------------------------------------

(define-mcp-tool "map"
    (:description "Apply a function to each element of a list.")
  (("function" "string" :description "Function name or lambda, e.g. \"f\" or \"lambda([x],x^2)\"")
   ("list" "string" :description "List expression, e.g. \"[1,2,3]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((fn (get-argument arguments "function"))
         (lst (get-argument arguments "list"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless fn
      (signal-mcp-error +invalid-params+ "Missing required parameter: function"))
    (unless lst
      (signal-mcp-error +invalid-params+ "Missing required parameter: list"))
    (let ((call (format nil "map(~A, ~A)" fn lst)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; quotient / remainder - Polynomial or integer division
;;; ------------------------------------------------------------------

(define-mcp-tool "quotient"
    (:description "Quotient of division (polynomial or integer).")
  (("dividend" "string" :description "Dividend expression")
   ("divisor" "string" :description "Divisor expression")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((a (get-argument arguments "dividend"))
         (b (get-argument arguments "divisor"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless a
      (signal-mcp-error +invalid-params+ "Missing required parameter: dividend"))
    (unless b
      (signal-mcp-error +invalid-params+ "Missing required parameter: divisor"))
    (let ((call (format nil "quotient(~A, ~A)" a b)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "remainder"
    (:description "Remainder of division (polynomial or integer).")
  (("dividend" "string" :description "Dividend expression")
   ("divisor" "string" :description "Divisor expression")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((a (get-argument arguments "dividend"))
         (b (get-argument arguments "divisor"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless a
      (signal-mcp-error +invalid-params+ "Missing required parameter: dividend"))
    (unless b
      (signal-mcp-error +invalid-params+ "Missing required parameter: divisor"))
    (let ((call (format nil "remainder(~A, ~A)" a b)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; gcdex - Extended GCD
;;; ------------------------------------------------------------------

(define-mcp-tool "gcdex"
    (:description "Extended GCD (Bezout coefficients).")
  (("a" "string" :description "First integer or polynomial")
   ("b" "string" :description "Second integer or polynomial")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((a (get-argument arguments "a"))
         (b (get-argument arguments "b"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless a
      (signal-mcp-error +invalid-params+ "Missing required parameter: a"))
    (unless b
      (signal-mcp-error +invalid-params+ "Missing required parameter: b"))
    (let ((call (format nil "gcdex(~A, ~A)" a b)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; quad_qags - Numerical integration
;;; ------------------------------------------------------------------

(define-mcp-tool "quad_qags"
    (:description "Numerical integration via quad_qags.")
  (("expression" "string" :description "Integrand expression")
   ("variable" "string" :description "Variable of integration")
   ("lower" "string" :description "Lower limit")
   ("upper" "string" :description "Upper limit")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (var (get-argument arguments "variable"))
         (lower (get-argument arguments "lower"))
         (upper (get-argument arguments "upper"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless lower
      (signal-mcp-error +invalid-params+ "Missing required parameter: lower"))
    (unless upper
      (signal-mcp-error +invalid-params+ "Missing required parameter: upper"))
    (let ((call (format nil "quad_qags(~A, ~A, ~A, ~A)" expr var lower upper)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; rk - Runge-Kutta (numerical ODE)
;;; ------------------------------------------------------------------

(define-mcp-tool "rk"
    (:description "Runge-Kutta solver for ODEs (rk).")
  (("expression" "string" :description "dy/dx expression, e.g. \"y-(x-2)^2\"")
   ("dependent" "string" :description "Dependent variable, e.g. \"y\"")
   ("initial" "string" :description "Initial value, e.g. \"1.9\"")
   ("range" "string" :description "Range spec, e.g. \"[x,0,5,1]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (dep (get-argument arguments "dependent"))
         (init (get-argument arguments "initial"))
         (range (get-argument arguments "range"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless dep
      (signal-mcp-error +invalid-params+ "Missing required parameter: dependent"))
    (unless init
      (signal-mcp-error +invalid-params+ "Missing required parameter: initial"))
    (unless range
      (signal-mcp-error +invalid-params+ "Missing required parameter: range"))
    (let ((call (format nil "rk(~A, ~A, ~A, ~A)" expr dep init range)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; solve_rec - Solve recurrence relations
;;; ------------------------------------------------------------------

(defun ensure-solve-rec-loaded ()
  "Ensure solve_rec package is loaded."
  (multiple-value-bind (result err) (parse-and-eval "load(\"solve_rec\")")
    (declare (ignore result))
    (when err
      (signal-mcp-error +internal-error+ err))))

(define-mcp-tool "solve_rec"
    (:description "Solve a linear recurrence relation (solve_rec package).")
  (("equation" "string" :description "Recurrence equation, e.g. \"u[n]=2*u[n-1]+3\"")
   ("term" "string" :description "General term, e.g. \"u[n]\"")
   ("initials" "string" :description "Initial conditions, e.g. \"u[1]=5\" or \"[u[0]=4,u[1]=9]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eq (get-argument arguments "equation"))
         (term (get-argument arguments "term"))
         (init (get-argument arguments "initials"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eq
      (signal-mcp-error +invalid-params+ "Missing required parameter: equation"))
    (unless term
      (signal-mcp-error +invalid-params+ "Missing required parameter: term"))
    (unless init
      (signal-mcp-error +invalid-params+ "Missing required parameter: initials"))
    (ensure-solve-rec-loaded)
    (let ((call (format nil "solve_rec(~A, ~A, ~A)" eq term init)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; set_plot_option - Plot option setter
;;; ------------------------------------------------------------------

(define-mcp-tool "set_plot_option"
    (:description "Set a global plot option (set_plot_option).")
  (("option" "string" :description "Plot option list, e.g. \"[gnuplot_preamble,\\\"set size ratio -1\\\"]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((opt (get-argument arguments "option"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless opt
      (signal-mcp-error +invalid-params+ "Missing required parameter: option"))
    (let ((call (format nil "set_plot_option(~A)" opt)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; depends / dependencies - Declare or list functional dependencies
;;; ------------------------------------------------------------------

(define-mcp-tool "depends"
    (:description "Declare functional dependencies (depends).")
  (("targets" "string" :description "Dependent symbols or list, e.g. \"f\" or \"[f,g]\"")
   ("variables" "string" :description "Independent symbols or list, e.g. \"x\" or \"[x,y]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((targets (get-argument arguments "targets"))
         (vars (get-argument arguments "variables"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless targets
      (signal-mcp-error +invalid-params+ "Missing required parameter: targets"))
    (unless vars
      (signal-mcp-error +invalid-params+ "Missing required parameter: variables"))
    (let ((call (format nil "depends(~A, ~A)" targets vars)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "dependencies"
    (:description "List or declare dependencies (dependencies).")
  (("expressions" "string" :description "Optional dependency expressions, e.g. \"f(x,y), g(u)\""
    :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((exprs (get-argument arguments "expressions"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str))
         (call (if exprs
                   (format nil "dependencies(~A)" exprs)
                   "dependencies")))
    (multiple-value-bind (result err) (parse-and-eval call)
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

(define-mcp-tool "remove_dependency"
    (:description "Remove all dependencies for a symbol (remove(symbol, dependency)).")
  (("symbol" "string" :description "Symbol or list of symbols to clear dependencies for")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((sym (get-argument arguments "symbol"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless sym
      (signal-mcp-error +invalid-params+ "Missing required parameter: symbol"))
    (let ((call (format nil "remove(~A, dependency)" sym)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; gradef - Define custom derivatives
;;; ------------------------------------------------------------------

(define-mcp-tool "gradef"
    (:description "Define custom derivative rules (gradef).")
  (("function" "string" :description "Function call, e.g. \"f(x,y)\" or \"sin(x)\"" :required nil)
   ("derivatives" "array" :description "Derivative expressions, e.g. [\"dfdx\",\"dfdy\"]" :required nil)
   ("symbol" "string" :description "Alternative form: variable or function name" :required nil)
   ("with_respect_to" "string" :description "Alternative form: differentiation variable" :required nil)
   ("expression" "string" :description "Alternative form: derivative expression" :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((fn (get-argument arguments "function"))
         (derivs (get-argument arguments "derivatives"))
         (sym (get-argument arguments "symbol"))
         (wrt (get-argument arguments "with_respect_to"))
         (expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (cond
      ((and fn derivs)
       (let* ((deriv-list (if (listp derivs) derivs (list derivs)))
              (call (format nil "gradef(~A~{, ~A~})" fn deriv-list)))
         (multiple-value-bind (result err) (parse-and-eval call)
           (if err
               (wrap-tool-result nil :is-error t :error-message err)
               (wrap-tool-result result :format format)))))
      ((and sym wrt expr)
       (let ((call (format nil "gradef(~A, ~A, ~A)" sym wrt expr)))
         (multiple-value-bind (result err) (parse-and-eval call)
           (if err
               (wrap-tool-result nil :is-error t :error-message err)
               (wrap-tool-result result :format format)))))
      (t
       (signal-mcp-error +invalid-params+
                         "Provide either function+derivatives or symbol+with_respect_to+expression.")))))

;;; ------------------------------------------------------------------
;;; propvars - Variables with a property
;;; ------------------------------------------------------------------

(define-mcp-tool "propvars"
    (:description "List variables with a given property (propvars).")
  (("property" "string" :description "Property name, e.g. \"constant\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((prop (get-argument arguments "property"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless prop
      (signal-mcp-error +invalid-params+ "Missing required parameter: property"))
    (let ((call (format nil "propvars(~A)" prop)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
