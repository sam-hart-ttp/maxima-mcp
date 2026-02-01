;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-meta.lisp - Meta tools for Maxima MCP
;;;
;;; Provides tools for getting help and information about Maxima
;;; functionality: describe, examples, and capabilities.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; describe - Get help on Maxima function
;;; ------------------------------------------------------------------

(define-mcp-tool "describe"
    (:description "Get documentation and help for a Maxima function or topic. Use this to learn about available Maxima functions and how to use them.")
  (("topic" "string" :description "The function or topic to describe (e.g., \"integrate\", \"solve\", \"matrix\")"))

  (let* ((topic-str (get-argument arguments "topic")))

    (unless topic-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: topic"))

    ;; Use Maxima's describe function which returns documentation
    (let ((desc-expr (format nil "describe(~A)" topic-str)))
      (multiple-value-bind (result err) (parse-and-eval desc-expr)
        (if err
            ;; If describe fails, return a helpful message
            (wrap-tool-result nil :is-error t
                              :error-message (format nil "No documentation found for: ~A" topic-str))
            ;; describe returns a list of matched topics (or a string in subprocess mode)
            (if (stringp result)
                (wrap-tool-result result :format :text)
                (if (and (consp result)
                         (consp (car result))
                         (string= (symbol-name (caar result)) "MLIST"))
                    (let ((topics (cdr result)))
                      (if (null topics)
                          (wrap-tool-result (format nil "No documentation found for: ~A" topic-str)
                                            :format :text)
                          (wrap-tool-result (format nil "Found documentation for ~A topic(s). Use ? ~A in Maxima for full details."
                                                    (length topics) topic-str)
                                            :format :text)))
                    (wrap-tool-result result :format :text))))))))

;;; ------------------------------------------------------------------
;;; capabilities - List available tools
;;; ------------------------------------------------------------------

(define-mcp-tool "capabilities"
    (:description "List all available MCP tools with their descriptions. Use this to discover what operations are available.")
  ()

  (let ((tools (list-tools))
        (result-parts nil))
    ;; Build a text description of all tools
    (dolist (tool (sort (copy-list tools) #'string< :key #'mcp-tool-name))
      (push (format nil "~A: ~A"
                    (mcp-tool-name tool)
                    (mcp-tool-description tool))
            result-parts))
    (wrap-tool-result (format nil "Available tools (~A):~%~%~{~A~%~}"
                              (length tools)
                              (nreverse result-parts))
                      :format :text)))

;;; ------------------------------------------------------------------
;;; example - Show usage examples
;;; ------------------------------------------------------------------

(define-mcp-tool "example"
    (:description "Show usage examples for a Maxima function. This runs the built-in examples.")
  (("function" "string" :description "The function to show examples for (e.g., \"integrate\", \"factor\")"))

  (let* ((func-str (get-argument arguments "function")))

    (unless func-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: function"))

    ;; Capture output from example()
    (let ((example-expr (format nil "example(~A)" func-str)))
      (multiple-value-bind (result err) (parse-and-eval example-expr)
        (declare (ignore result))
        (if err
            (wrap-tool-result nil :is-error t
                              :error-message (format nil "No examples found for: ~A" func-str))
            (wrap-tool-result (format nil "Examples run for ~A. Check the output above." func-str)
                              :format :text))))))

;;; ------------------------------------------------------------------
;;; apropos - Search for functions by keyword
;;; ------------------------------------------------------------------

(define-mcp-tool "apropos"
    (:description "Search for Maxima functions and variables whose names contain a given string.")
  (("pattern" "string" :description "The pattern to search for in function/variable names"))

  (let* ((pattern-str (get-argument arguments "pattern")))

    (unless pattern-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: pattern"))

    (let ((apropos-expr (format nil "apropos(\"~A\")" pattern-str)))
      (multiple-value-bind (result err) (parse-and-eval apropos-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format :text))))))

;;; ------------------------------------------------------------------
;;; fundef - Get function definition
;;; ------------------------------------------------------------------

(define-mcp-tool "fundef"
    (:description "Get the definition of a user-defined function.")
  (("function" "string" :description "The name of the function")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((func-str (get-argument arguments "function"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless func-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: function"))

    (let ((fundef-expr (format nil "fundef(~A)" func-str)))
      (multiple-value-bind (result err) (parse-and-eval fundef-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; define_function - Define a user function
;;; ------------------------------------------------------------------

(define-mcp-tool "define_function"
    (:description "Define a custom function in Maxima. The function can then be used in subsequent expressions.")
  (("name" "string" :description "The function name with arguments (e.g., \"f(x)\" or \"g(x,y)\")")
   ("body" "string" :description "The function body expression (e.g., \"x^2+1\" or \"x+y\")")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((name-str (get-argument arguments "name"))
         (body-str (get-argument arguments "body"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (unless name-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: name"))
    (unless body-str
      (signal-mcp-error +invalid-params+ "Missing required parameter: body"))

    ;; Define using := syntax
    (let ((def-expr (format nil "~A := ~A" name-str body-str)))
      (multiple-value-bind (result err) (parse-and-eval def-expr)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; list_functions - List user-defined functions
;;; ------------------------------------------------------------------

(define-mcp-tool "list_functions"
    (:description "List all user-defined functions.")
  (("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))

  (let* ((format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))

    (multiple-value-bind (result err) (parse-and-eval "functions")
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

;;; ------------------------------------------------------------------
;;; version - Get Maxima version
;;; ------------------------------------------------------------------

(define-mcp-tool "version"
    (:description "Get the Maxima version and build information.")
  ()

  (multiple-value-bind (result err) (parse-and-eval "build_info()")
    (if err
        ;; Fall back to just the version string
        (wrap-tool-result "Maxima (version unknown)" :format :text)
        (wrap-tool-result result :format :text))))

;;; ------------------------------------------------------------------
;;; constants - List mathematical constants
;;; ------------------------------------------------------------------

(define-mcp-tool "constants"
    (:description "Show common mathematical constants available in Maxima.")
  ()

  (wrap-tool-result
   "Mathematical constants in Maxima:
%pi      - Pi (3.14159...)
%e       - Euler's number e (2.71828...)
%i       - Imaginary unit (sqrt(-1))
%phi     - Golden ratio ((1+sqrt(5))/2)
%gamma   - Euler-Mascheroni constant
inf      - Positive infinity
minf     - Negative infinity
und      - Undefined
ind      - Indefinite (finite but undetermined)"
   :format :text))
