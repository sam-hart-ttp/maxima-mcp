;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-session.lisp - Session management tools for Maxima MCP
;;;
;;; Provides tools for managing session state: variable assignment and
;;; retrieval, clearing variables, assumptions, and session reset.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; assign - Assign value to variable
;;; ------------------------------------------------------------------

(define-mcp-tool "assign"
    (:description "Assign a value to a variable. The variable can then be used in subsequent expressions.")
  (("variable" "string" :description "The variable name to assign to (e.g., \"x\", \"my_var\")")
   ("value" "string" :description "The value or expression to assign (e.g., \"5\", \"x^2+1\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((var-str (get-argument arguments "variable"))
         (value-str (get-argument arguments "value"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless value-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: value"))

    ;; Build assignment expression
    (let ((assign-expr (format nil "~A : ~A" var-str value-str)))
      (multiple-value-bind (result err) (parse-and-eval assign-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (progn
              ;; Track the variable in our session
              (let ((var-sym (intern (string-upcase
                                      (if (char= (char var-str 0) #\$)
                                          var-str
                                          (concatenate 'string "$" var-str)))
                                     :maxima)))
                (session-track-variable session var-sym))
              (wrap-tool-result result :format format)))))))

;;; ------------------------------------------------------------------
;;; get_value - Get variable value
;;; ------------------------------------------------------------------

(define-mcp-tool "get_value"
    (:description "Get the current value of a variable.")
  (("variable" "string" :description "The variable name to retrieve")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((var-str (get-argument arguments "variable"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))

    (multiple-value-bind (result err) (parse-and-eval var-str)
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

;;; ------------------------------------------------------------------
;;; list_variables - List defined variables
;;; ------------------------------------------------------------------

(define-mcp-tool "list_variables"
    (:description "List all user-defined variables and their values.")
  (("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    ;; Get Maxima's list of user values
    (multiple-value-bind (result err) (parse-and-eval "values")
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

;;; ------------------------------------------------------------------
;;; clear - Clear specific variables
;;; ------------------------------------------------------------------

(define-mcp-tool "clear"
    (:description "Clear (kill) specific variables, removing their values.")
  (("variables" "string" :description "Variable(s) to clear. Either a single variable name or a comma-separated list (e.g., \"x\" or \"x, y, z\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((vars-str (get-argument arguments "variables"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless vars-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variables"))

    ;; Build kill expression - kill(x, y, z) syntax
    (let ((kill-expr (format nil "kill(~A)" vars-str)))
      (multiple-value-bind (result err) (parse-and-eval kill-expr)
        (declare (ignore result))
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result "done" :format format))))))

;;; ------------------------------------------------------------------
;;; reset - Reset entire session
;;; ------------------------------------------------------------------

(define-mcp-tool "reset"
    (:description "Reset the Maxima session to its initial state, clearing all variables, functions, and assumptions.")
  (("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (multiple-value-bind (result err) (parse-and-eval "reset()")
      (declare (ignore result))
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (progn
            ;; Clear our session tracking
            (clrhash (mcp-session-variables session))
            (setf (mcp-session-assumption-count session) 0)
            (wrap-tool-result "done" :format format))))))

;;; ------------------------------------------------------------------
;;; assume - Add mathematical assumption
;;; ------------------------------------------------------------------

(define-mcp-tool "assume"
    (:description "Add a mathematical assumption about a variable. This affects simplification and computation of expressions involving that variable. For example, assume(x>0) allows sqrt(x^2) to simplify to x.")
  (("assumption" "string" :description "The assumption to add (e.g., \"x>0\", \"n integer\", \"x<y\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((assumption-str (get-argument arguments "assumption"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless assumption-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: assumption"))

    (let ((assume-expr (format nil "assume(~A)" assumption-str)))
      (multiple-value-bind (result err) (parse-and-eval assume-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (progn
              (incf (mcp-session-assumption-count session))
              (wrap-tool-result result :format format)))))))

;;; ------------------------------------------------------------------
;;; forget - Remove assumption
;;; ------------------------------------------------------------------

(define-mcp-tool "forget"
    (:description "Remove a previously made assumption about a variable.")
  (("assumption" "string" :description "The assumption to remove (same form as used with assume)")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((assumption-str (get-argument arguments "assumption"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless assumption-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: assumption"))

    (let ((forget-expr (format nil "forget(~A)" assumption-str)))
      (multiple-value-bind (result err) (parse-and-eval forget-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (progn
              ;; We cannot reliably infer exact active facts from a single forget().
              (setf (mcp-session-assumption-count session)
                    (max 0 (1- (mcp-session-assumption-count session))))
              (wrap-tool-result result :format format)))))))

;;; ------------------------------------------------------------------
;;; list_assumptions - List current assumptions
;;; ------------------------------------------------------------------

(define-mcp-tool "list_assumptions"
    (:description "List all current mathematical assumptions (the facts database).")
  (("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (multiple-value-bind (result err) (parse-and-eval "facts()")
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

;;; ------------------------------------------------------------------
;;; declare - Declare variable properties
;;; ------------------------------------------------------------------

(define-mcp-tool "declare"
    (:description "Declare properties of a variable or function. Common properties: integer, rational, real, complex, even, odd, constant, scalar, nonscalar.")
  (("variable" "string" :description "The variable or function to declare")
   ("property" "string" :description "The property to declare (e.g., \"integer\", \"real\", \"constant\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((var-str (get-argument arguments "variable"))
         (prop-str (get-argument arguments "property"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless var-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless prop-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: property"))

    (let ((decl-expr (format nil "declare(~A, ~A)" var-str prop-str)))
      (multiple-value-bind (result err) (parse-and-eval decl-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; properties - Get properties of a symbol
;;; ------------------------------------------------------------------

(define-mcp-tool "properties"
    (:description "List all properties of a symbol (variable or function).")
  (("symbol" "string" :description "The symbol to query")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((sym-str (get-argument arguments "symbol"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless sym-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: symbol"))

    (let ((props-expr (format nil "properties(~A)" sym-str)))
      (multiple-value-bind (result err) (parse-and-eval props-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; set_format - Set default output format
;;; ------------------------------------------------------------------

(define-mcp-tool "set_format"
    (:description "Set the default output format for the session.")
  (("format" "string" :description "Output format: text, latex, mathml, or lisp"))

  (let* ((format-str (get-argument arguments "format")))

    (unless format-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: format"))

    (let ((kw (normalize-format format-str)))
      (if (valid-format-p kw)
          (progn
            (setf (mcp-session-default-format session) kw)
            (wrap-tool-result (format nil "Default format set to ~A" format-str)
                              :format :text))
          (wrap-tool-result nil :is-error t
                            :error-message (format nil "Invalid format: ~A. Use text, latex, mathml, or lisp."
                                                   format-str))))))
