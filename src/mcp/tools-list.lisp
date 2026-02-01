;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-list.lisp - List and substitution utilities
;;;
;;; Provides explicit tools for common list/substitution operations.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; makelist - Construct a list by iteration
;;; ------------------------------------------------------------------

(define-mcp-tool "makelist"
    (:description "Construct a list by iterating a variable over a range or list.")
  (("expression" "string" :description "Expression to evaluate, e.g. \"[x[n],y[n]]\"")
   ("variable" "string" :description "Iteration variable, e.g. \"n\"")
   ("range" "string" :description "Range or list, e.g. \"0, 10\" or \"[0.5,0.1,0.01]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (var (get-argument arguments "variable"))
         (range (get-argument arguments "range"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless range
      (signal-mcp-error +invalid-params+ "Missing required parameter: range"))
    (let ((call (format nil "makelist(~A, ~A, ~A)" expr var range)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; subst - Substitute expressions
;;; ------------------------------------------------------------------

(define-mcp-tool "subst"
    (:description "Substitute an expression or list of rules into an expression.")
  (("substitution" "string" :description "Substitution rule(s), e.g. \"x=1\" or \"[x=1,y=2]\"")
   ("expression" "string" :description "Expression to substitute into")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((sub (get-argument arguments "substitution"))
         (expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless sub
      (signal-mcp-error +invalid-params+ "Missing required parameter: substitution"))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (format nil "subst(~A, ~A)" sub expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; ev - Evaluate with substitutions and flags
;;; ------------------------------------------------------------------

(define-mcp-tool "ev"
    (:description "Evaluate an expression with substitutions or flags.")
  (("expression" "string" :description "Expression to evaluate")
   ("rules" "string" :description "Rules or flags, e.g. \"x=1\" or \"[x=1,y=2]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (rules (get-argument arguments "rules"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless rules
      (signal-mcp-error +invalid-params+ "Missing required parameter: rules"))
    (let ((call (format nil "ev(~A, ~A)" expr rules)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; append - Concatenate lists
;;; ------------------------------------------------------------------

(define-mcp-tool "append"
    (:description "Append lists together.")
  (("lists" "array" :description "List expressions as strings, e.g. [\"[1,2]\", \"[3,4]\"]")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((lists (get-argument arguments "lists"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless (and lists (listp lists))
      (signal-mcp-error +invalid-params+ "Missing required parameter: lists"))
    (let ((call (format nil "append(~{~A~^, ~})" lists)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
