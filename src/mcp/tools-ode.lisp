;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-ode.lisp - Differential equation tools
;;;
;;; Provides ODE tools used in the OU tutorials.

(in-package :maxima-mcp)

(defun ensure-ode-loaded ()
  "Ensure ODE functions are available (ode2 is built-in)."
  t)

;;; ------------------------------------------------------------------
;;; ode2 - Solve a single ODE
;;; ------------------------------------------------------------------

(define-mcp-tool "ode2"
    (:description "Solve a first/second order ODE using ode2.")
  (("equation" "string" :description "ODE equation, e.g. \"diff(y,x)=y\"")
   ("function" "string" :description "Dependent variable, e.g. \"y\" or \"y(x)\"")
   ("variable" "string" :description "Independent variable, e.g. \"x\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eqn (get-argument arguments "equation"))
         (fn (get-argument arguments "function"))
         (var (get-argument arguments "variable"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eqn
      (signal-mcp-error +invalid-params+ "Missing required parameter: equation"))
    (unless fn
      (signal-mcp-error +invalid-params+ "Missing required parameter: function"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (ensure-ode-loaded)
    (let ((expr (format nil "ode2(~A, ~A, ~A)" eqn fn var)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; ic1 - Apply initial condition (one)
;;; ------------------------------------------------------------------

(define-mcp-tool "ic1"
    (:description "Apply a single initial condition to a general solution from ode2.")
  (("solution" "string" :description "General solution from ode2")
   ("xval" "string" :description "Independent variable value, e.g. \"0\"")
   ("yval" "string" :description "Dependent variable value, e.g. \"1\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((sol (get-argument arguments "solution"))
         (xval (get-argument arguments "xval"))
         (yval (get-argument arguments "yval"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless sol
      (signal-mcp-error +invalid-params+ "Missing required parameter: solution"))
    (unless xval
      (signal-mcp-error +invalid-params+ "Missing required parameter: xval"))
    (unless yval
      (signal-mcp-error +invalid-params+ "Missing required parameter: yval"))
    (let ((expr (format nil "ic1(~A, ~A, ~A)" sol xval yval)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; ic2 - Apply two initial conditions
;;; ------------------------------------------------------------------

(define-mcp-tool "ic2"
    (:description "Apply two initial conditions to a general solution from ode2.")
  (("solution" "string" :description "General solution from ode2")
   ("xval1" "string" :description "First x value")
   ("yval1" "string" :description "First y value")
   ("xval2" "string" :description "Second x value")
   ("yval2" "string" :description "Second y value")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((sol (get-argument arguments "solution"))
         (xval1 (get-argument arguments "xval1"))
         (yval1 (get-argument arguments "yval1"))
         (xval2 (get-argument arguments "xval2"))
         (yval2 (get-argument arguments "yval2"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless sol
      (signal-mcp-error +invalid-params+ "Missing required parameter: solution"))
    (unless (and xval1 yval1 xval2 yval2)
      (signal-mcp-error +invalid-params+ "Missing required parameters: xval1, yval1, xval2, yval2"))
    (let ((expr (format nil "ic2(~A, ~A, ~A, ~A, ~A)" sol xval1 yval1 xval2 yval2)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; bc2 - Apply boundary conditions
;;; ------------------------------------------------------------------

(define-mcp-tool "bc2"
    (:description "Apply two boundary conditions to a general solution from ode2.")
  (("solution" "string" :description "General solution from ode2")
   ("xval1" "string" :description "First x value")
   ("yval1" "string" :description "First y value")
   ("xval2" "string" :description "Second x value")
   ("yval2" "string" :description "Second y value")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((sol (get-argument arguments "solution"))
         (xval1 (get-argument arguments "xval1"))
         (yval1 (get-argument arguments "yval1"))
         (xval2 (get-argument arguments "xval2"))
         (yval2 (get-argument arguments "yval2"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless sol
      (signal-mcp-error +invalid-params+ "Missing required parameter: solution"))
    (unless (and xval1 yval1 xval2 yval2)
      (signal-mcp-error +invalid-params+ "Missing required parameters: xval1, yval1, xval2, yval2"))
    (let ((expr (format nil "bc2(~A, ~A, ~A, ~A, ~A)" sol xval1 yval1 xval2 yval2)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; desolve - Solve linear ODE systems
;;; ------------------------------------------------------------------

(define-mcp-tool "desolve"
    (:description "Solve a system of linear ODEs with desolve.")
  (("equations" "string" :description "List of equations, e.g. \"[diff(x(t),t)=x(t), diff(y(t),t)=y(t)]\"")
   ("functions" "string" :description "List of functions, e.g. \"[x(t), y(t)]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((eqs (get-argument arguments "equations"))
         (fns (get-argument arguments "functions"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless eqs
      (signal-mcp-error +invalid-params+ "Missing required parameter: equations"))
    (unless fns
      (signal-mcp-error +invalid-params+ "Missing required parameter: functions"))
    (let ((expr (format nil "desolve(~A, ~A)" eqs fns)))
      (multiple-value-bind (result err) (parse-and-eval expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; atvalue - Define values at a point
;;; ------------------------------------------------------------------

(define-mcp-tool "atvalue"
    (:description "Set an atvalue for a function or derivative at a point.")
  (("expression" "string" :description "Function or derivative, e.g. \"x(t)\" or \"'diff(x(t),t)\"")
   ("point" "string" :description "Point specification, e.g. \"t=0\" or \"[t=0,y=1]\"")
   ("value" "string" :description "Value at the point, e.g. \"1\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (point (get-argument arguments "point"))
         (value (get-argument arguments "value"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless point
      (signal-mcp-error +invalid-params+ "Missing required parameter: point"))
    (unless value
      (signal-mcp-error +invalid-params+ "Missing required parameter: value"))
    (let ((call (format nil "atvalue(~A, ~A, ~A)" expr point value)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; printprops - Print properties (e.g. atvalue)
;;; ------------------------------------------------------------------

(define-mcp-tool "printprops"
    (:description "Print properties for a symbol or 'all'. Commonly used with atvalue.")
  (("symbol" "string" :description "Symbol name or 'all'")
   ("property" "string" :description "Property name, e.g. \"atvalue\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((sym (get-argument arguments "symbol"))
         (prop (get-argument arguments "property"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless sym
      (signal-mcp-error +invalid-params+ "Missing required parameter: symbol"))
    (unless prop
      (signal-mcp-error +invalid-params+ "Missing required parameter: property"))
    (let ((call (format nil "printprops(~A, ~A)" sym prop)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
