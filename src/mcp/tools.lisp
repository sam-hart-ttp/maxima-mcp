;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools.lisp - Tool registry infrastructure for Maxima MCP
;;;
;;; Provides the tool registration system and the define-mcp-tool macro
;;; for defining MCP tools that expose Maxima functionality.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Tool Structure
;;; ------------------------------------------------------------------

(defstruct mcp-tool
  "Definition of an MCP tool."
  (name "" :type string)
  (description "" :type string)
  (input-schema nil :type (or null hash-table))
  (handler nil :type (or null function)))

;;; ------------------------------------------------------------------
;;; Tool Registry
;;; ------------------------------------------------------------------

(defvar *mcp-tools* (make-hash-table :test #'equal)
  "Registry of MCP tools, keyed by tool name (string).")

(defun register-tool (tool)
  "Register an MCP tool in the registry."
  (setf (gethash (mcp-tool-name tool) *mcp-tools*) tool))

(defun find-tool (name)
  "Find a tool by name. Returns nil if not found."
  (gethash name *mcp-tools*))

(defun list-tools ()
  "Return a deterministic list of registered tools.
   Tools are sorted by name, with evaluate intentionally last."
  (let ((tools (loop for tool being the hash-values of *mcp-tools*
                     collect tool)))
    (sort tools
          (lambda (a b)
            (let ((name-a (mcp-tool-name a))
                  (name-b (mcp-tool-name b)))
              (cond
                ((string= name-a "evaluate") nil)
                ((string= name-b "evaluate") t)
                (t (string-lessp name-a name-b))))))))

(defun tool-exists-p (name)
  "Return T if a tool with NAME exists."
  (not (null (find-tool name))))

;;; ------------------------------------------------------------------
;;; Tool Definition Macro
;;; ------------------------------------------------------------------

(defmacro define-mcp-tool (name (&key description) params &body body)
  "Define an MCP tool.
   NAME is a string naming the tool.
   DESCRIPTION is a human-readable description.
   PARAMS is a list of parameter specs: ((name type &key description required default) ...)
   BODY is the tool implementation, which has access to SESSION and ARGUMENTS.

   Each parameter spec:
   - name: string naming the parameter
   - type: JSON Schema type (\"string\", \"number\", \"boolean\", \"array\", \"object\")
   - description: optional description
   - required: whether the parameter is required (default t)
   - default: default value if not provided
   - enum: list of allowed values"
  (let ((tool-var (gensym "TOOL"))
        (schema-var (gensym "SCHEMA"))
        (props-var (gensym "PROPS"))
        (required-var (gensym "REQUIRED")))
    `(let* ((,props-var (list ,@(loop for param in params
                                      collect (destructuring-bind
                                                  (pname ptype &key description enum default required)
                                                  param
                                                (declare (ignore default required))
                                                `(cons ,pname
                                                       (make-property-schema
                                                        ,ptype
                                                        :description ,description
                                                        :enum ,(when enum `(list ,@enum))))))))
            (,required-var (list ,@(loop for param in params
                                         for pname = (first param)
                                         for req = (getf (cddr param) :required t)
                                         when req
                                         collect pname)))
            (,schema-var (make-json-schema :type "object"
                                           :properties ,props-var
                                           :required ,required-var))
            (,tool-var (make-mcp-tool
                        :name ,name
                        :description ,description
                        :input-schema ,schema-var
                        :handler (lambda (session arguments)
                                   (declare (ignorable session arguments))
                                   ,@body))))
       (register-tool ,tool-var)
       ,tool-var)))

;;; ------------------------------------------------------------------
;;; Tool Invocation
;;; ------------------------------------------------------------------

(defun get-argument (arguments name &optional default)
  "Get an argument value from ARGUMENTS hash-table by NAME.
   Returns DEFAULT if not found."
  (if (hash-table-p arguments)
      (gethash name arguments default)
      default))

(defun invoke-tool (name session arguments)
  "Invoke a tool by NAME with SESSION and ARGUMENTS.
   Returns the tool result or signals an error."
  (let ((tool (find-tool name)))
    (unless tool
      (signal-mcp-error +tool-not-found+
                        (format nil "Tool not found: ~A" name)))
    (let ((handler (mcp-tool-handler tool)))
      (unless handler
        (signal-mcp-error +internal-error+
                          (format nil "Tool ~A has no handler" name)))
      (funcall handler session arguments))))

;;; ------------------------------------------------------------------
;;; Tool Listing for MCP
;;; ------------------------------------------------------------------

(defun tool-to-json (tool)
  "Convert an MCP-TOOL to JSON format for tools/list response."
  (make-json-object
   "name" (mcp-tool-name tool)
   "description" (mcp-tool-description tool)
   "inputSchema" (mcp-tool-input-schema tool)))

(defun all-tools-json ()
  "Return all tools in JSON format for tools/list response."
  (mapcar #'tool-to-json (list-tools)))

;;; ------------------------------------------------------------------
;;; Expression Parsing Utilities
;;; ------------------------------------------------------------------

;; Check if we're in subprocess mode (Maxima library not loaded)
(defvar *use-subprocess* nil
  "When T, use subprocess backend instead of library calls.")

(defun using-subprocess-p ()
  "Return T if we should use subprocess for evaluation."
  (or *use-subprocess*
      (not (find-package :maxima))))

(defun parse-maxima-expression (expr-string)
  "Parse a Maxima expression string into internal form.
   Returns (values parsed-expr error-string).
   If successful, error-string is nil.
   If parsing fails, parsed-expr is nil and error-string describes the error."
  (if (using-subprocess-p)
      ;; In subprocess mode, we don't parse - just return the string
      (values expr-string nil)
      ;; Library mode - use mread-raw
      (handler-case
          (let* ((input (concatenate 'string expr-string ";"))
                 (stream (make-string-input-stream input)))
            (let ((result (funcall (intern "MREAD-RAW" :maxima) stream)))
              (if result
                  ;; mread-raw returns (label-info labels parsed-expr)
                  (values (third result) nil)
                  (values nil "Empty or invalid expression"))))
        (error (e)
          (values nil (format nil "Parse error: ~A" e))))))

(defun safe-meval (expr)
  "Safely evaluate a parsed Maxima expression.
   Returns (values result error-string)."
  (if (using-subprocess-p)
      ;; In subprocess mode, expr is a string
      (subprocess-eval expr)
      ;; Library mode
      (with-maxima-error-handling
        (funcall (intern "MEVAL" :maxima) expr))))

(defun parse-and-eval (expr-string)
  "Parse and evaluate a Maxima expression string.
   Returns (values result error-string)."
  (if (using-subprocess-p)
      (subprocess-eval expr-string)
      (multiple-value-bind (parsed parse-err) (parse-maxima-expression expr-string)
        (if parse-err
            (values nil parse-err)
            (safe-meval parsed)))))
