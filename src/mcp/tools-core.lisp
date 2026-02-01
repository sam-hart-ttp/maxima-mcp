;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-core.lisp - Core tools for Maxima MCP
;;;
;;; Provides the fundamental tools: evaluate and solve.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; evaluate - Evaluate any Maxima expression
;;; ------------------------------------------------------------------

(define-mcp-tool "evaluate"
    (:description "Evaluate a Maxima expression. This is the most general tool - it can evaluate any valid Maxima expression including arithmetic, algebra, calculus, and more.")
  (("expression" "string" :description "The Maxima expression to evaluate (e.g., \"2+2\", \"diff(x^2,x)\", \"integrate(sin(x),x)\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (multiple-value-bind (result err) (parse-and-eval expr-str)
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

;;; ------------------------------------------------------------------
;;; solve - Solve equations
;;; ------------------------------------------------------------------

(define-mcp-tool "solve"
    (:description "Solve an equation or system of equations for specified variables. Returns a list of solutions.")
  (("equation" "string" :description "The equation to solve (e.g., \"x^2-4=0\") or a list of equations (e.g., \"[x+y=1, x-y=3]\")")
   ("variable" "string" :description "The variable(s) to solve for (e.g., \"x\" or \"[x,y]\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((equation-str (get-argument arguments "equation"))
         (variable-str (get-argument arguments "variable"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless equation-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: equation"))
    (unless variable-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))

    ;; Build the solve expression
    (let ((solve-expr (format nil "solve(~A, ~A)" equation-str variable-str)))
      (multiple-value-bind (result err) (parse-and-eval solve-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; find_root - Find numerical roots
;;; ------------------------------------------------------------------

(define-mcp-tool "find_root"
    (:description "Find a numerical root of an equation in a given interval using the bisection method.")
  (("expression" "string" :description "The expression to find a root for (e.g., \"x^2-2\") - finds where it equals zero")
   ("variable" "string" :description "The variable to solve for")
   ("lower" "number" :description "Lower bound of the search interval")
   ("upper" "number" :description "Upper bound of the search interval")
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
    (unless (and lower upper)
      (signal-mcp-error +invalid-params+ "Missing required parameters: lower and upper bounds"))

    (let ((find-root-expr (format nil "find_root(~A, ~A, ~A, ~A)"
                                  expr-str var-str lower upper)))
      (multiple-value-bind (result err) (parse-and-eval find-root-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; float - Convert to floating point
;;; ------------------------------------------------------------------

(define-mcp-tool "float"
    (:description "Convert an expression to floating point numerical value.")
  (("expression" "string" :description "The expression to convert to float (e.g., \"sqrt(2)\", \"%pi\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((float-expr (format nil "float(~A)" expr-str)))
      (multiple-value-bind (result err) (parse-and-eval float-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; bfloat - Convert to bigfloat (arbitrary precision)
;;; ------------------------------------------------------------------

(define-mcp-tool "bfloat"
    (:description "Convert an expression to arbitrary-precision floating point (bigfloat). Use fpprec to control precision.")
  (("expression" "string" :description "The expression to convert to bigfloat")
   ("precision" "number" :description "Number of decimal digits of precision (sets fpprec)" :required nil)
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((expr-str (get-argument arguments "expression"))
         (precision (get-argument arguments "precision"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless expr-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))

    (let ((bfloat-expr (if precision
                          (format nil "(fpprec:~A, bfloat(~A))" precision expr-str)
                          (format nil "bfloat(~A)" expr-str))))
      (multiple-value-bind (result err) (parse-and-eval bfloat-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
