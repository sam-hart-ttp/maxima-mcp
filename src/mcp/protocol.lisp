;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; protocol.lisp - MCP protocol handling for Maxima MCP
;;;
;;; Implements the Model Context Protocol (MCP) using JSON-RPC 2.0.
;;; Handles protocol initialization, tool listing, and tool invocation.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Protocol Constants
;;; ------------------------------------------------------------------

(defparameter *mcp-protocol-version* "2024-11-05"
  "The MCP protocol version supported.")

(defparameter *server-name* "maxima-mcp"
  "The server name for MCP identification.")

(defparameter *server-version* "0.1.0"
  "The server version.")

(defparameter *tool-selection-policy*
  (concatenate 'string
               "Use dedicated tools whenever possible. "
               "Treat evaluate as a fallback only when no specific tool exists.")
  "Tool selection guidance returned during initialize.")

(defparameter *tool-observability-log-interval* 25
  "Emit an observability summary every N tool calls when debug logging is enabled.")

(defvar *tool-call-counts* (make-hash-table :test #'equal)
  "Per-tool invocation counters for observability.")

(defvar *tool-call-total* 0
  "Total number of tool invocations handled in this process.")

(defvar *symbolic-call-total* 0
  "Number of symbolic-tool calls tracked for preflight observability.")

(defvar *symbolic-calls-without-assumptions* 0
  "Number of symbolic-tool calls made without explicit assumptions in session.")

(defvar *symbolic-preflight-warnings* 0
  "Number of symbolic preflight warnings emitted.")

(defvar *mcp-debug* nil
  "When non-nil, enable debug output to stderr.")

;;; ------------------------------------------------------------------
;;; Request Handling
;;; ------------------------------------------------------------------

(defun handle-request (request session)
  "Handle a JSON-RPC request. Returns a response object."
  (handler-case
      (let* ((jsonrpc (json-object-get request "jsonrpc"))
             (method (json-object-get request "method"))
             (params (json-object-get request "params"))
             (id (json-object-get request "id"))
             (notification-p (null id))
             response)

        ;; Validate JSON-RPC version
        (unless (equal jsonrpc "2.0")
          (setf response
                (make-error-response id +invalid-request+ "Invalid JSON-RPC version")))

        ;; Dispatch based on method (only if no prior error)
        (unless response
          (setf response (dispatch-method method params session id)))

        ;; Notifications must not receive any response (even on error)
        (if notification-p
            nil
            response))

    (mcp-error (e)
      (let ((id (json-object-get request "id")))
        (if (null id)
            nil
            (make-error-response id
                                 (mcp-error-code e)
                                 (mcp-error-message e)
                                 (mcp-error-data e)))))
    (error (e)
      (let ((id (json-object-get request "id")))
        (if (null id)
            nil
            (make-error-response id
                                 +internal-error+
                                 (format nil "Internal error: ~A" e)))))))

(defun dispatch-method (method params session id)
  "Dispatch a request to the appropriate handler based on METHOD."
  (cond
    ;; MCP Lifecycle methods
    ((equal method "initialize")
     (handle-initialize params id))
    ((equal method "initialized")
     ;; Notification - no response needed
     (make-json-object "jsonrpc" "2.0" "id" id "result" (make-hash-table :test #'equal)))
    ((equal method "ping")
     (handle-ping id))

    ;; Tool methods
    ((equal method "tools/list")
     (handle-tools-list params id))
    ((equal method "tools/call")
     (handle-tools-call params session id))

    ;; Resource methods (minimal implementation)
    ((equal method "resources/list")
     (handle-resources-list id))
    ((equal method "resources/templates/list")
     (handle-resources-templates-list id))
    ((equal method "resources/read")
     (handle-resources-read params id))

    ;; Prompts methods (minimal implementation)
    ((equal method "prompts/list")
     (handle-prompts-list id))

    ;; Unknown method
    (t
     (make-error-response id +method-not-found+
                          (format nil "Unknown method: ~A" method)))))

;;; ------------------------------------------------------------------
;;; Initialize Handler
;;; ------------------------------------------------------------------

(defun handle-initialize (params id)
  "Handle the initialize request."
  (declare (ignore params))
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-json-object
             "protocolVersion" *mcp-protocol-version*
             "capabilities" (make-json-object
                             "tools" (make-json-object
                                      "listChanged" :false)
                             "resources" (make-json-object
                                          "subscribe" :false
                                          "listChanged" :false)
                             "prompts" (make-json-object
                                        "listChanged" :false))
             "serverInfo" (make-json-object
                           "name" *server-name*
                           "version" *server-version*)
             "instructions" *tool-selection-policy*)))

;;; ------------------------------------------------------------------
;;; Ping Handler
;;; ------------------------------------------------------------------

(defun handle-ping (id)
  "Handle the ping request."
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-hash-table :test #'equal)))

;;; ------------------------------------------------------------------
;;; Tools Handlers
;;; ------------------------------------------------------------------

(defun handle-tools-list (params id)
  "Handle the tools/list request."
  (declare (ignore params))
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-json-object
             "tools" (all-tools-json))))

(defun handle-tools-call (params session id)
  "Handle the tools/call request."
  (let ((tool-name (json-object-get params "name"))
        (arguments (json-object-get params "arguments")))

    (unless tool-name
      (return-from handle-tools-call
        (make-error-response id +invalid-params+ "Missing tool name")))

    (record-tool-call tool-name)
    (let ((preflight-warning (symbolic-preflight-warning tool-name session)))
      (handler-case
          (let ((result (invoke-tool tool-name session (or arguments
                                                           (make-hash-table :test #'equal)))))
            (when preflight-warning
              (setf result (inject-preflight-warning result preflight-warning)))
            (make-json-object
             "jsonrpc" "2.0"
             "id" id
             "result" result))
        (mcp-error (e)
          (make-error-response id
                               (mcp-error-code e)
                               (mcp-error-message e)
                               (mcp-error-data e)))
        (error (e)
          (make-error-response id +tool-execution-error+
                               (format nil "Tool execution error: ~A" e))))))
  )

(defun record-tool-call (tool-name)
  "Record per-tool call counts and emit periodic debug summaries."
  (incf *tool-call-total*)
  (incf (gethash tool-name *tool-call-counts* 0))
  (when (and *mcp-debug*
             (> *tool-observability-log-interval* 0)
             (zerop (mod *tool-call-total* *tool-observability-log-interval*)))
    (protocol-debug-log "Tool usage summary (total=~D, evaluate=~D): ~A"
                        *tool-call-total*
                        (gethash "evaluate" *tool-call-counts* 0)
                        (tool-usage-snapshot))))

(defparameter *symbolic-preflight-tools*
  '("integrate" "limit" "solve")
  "Tool names that should preflight-check for explicit assumptions.")

(defun symbolic-preflight-warning (tool-name session)
  "Return warning text if TOOL-NAME should warn due to missing assumptions."
  (when (member tool-name *symbolic-preflight-tools* :test #'string=)
    (incf *symbolic-call-total*)
    (when (<= (mcp-session-assumption-count session) 0)
      (incf *symbolic-calls-without-assumptions*)
      (incf *symbolic-preflight-warnings*)
      (format nil
              "Preflight warning: no explicit assumptions in session. Before symbolic ~A, consider assume(a>0, b>0, ...) to avoid sign ambiguity and asksign stalls."
              tool-name))))

(defun inject-preflight-warning (result warning-text)
  "Prepend WARNING-TEXT to successful tool RESULT content."
  (let ((is-error (json-object-get result "isError")))
    (if is-error
        result
        (let ((content (json-object-get result "content")))
          (json-object-set result "content"
                           (cons (make-json-object
                                  "type" "text"
                                  "text" warning-text)
                                 content))
          result))))

(defun tool-usage-snapshot ()
  "Return an alist of tool-name . count sorted by descending count."
  (sort (loop for name being the hash-keys of *tool-call-counts*
              using (hash-value count)
              collect (cons name count))
        #'>
        :key #'cdr))

(defun protocol-debug-log (format-string &rest args)
  "Write a protocol debug message to stderr when debugging is enabled."
  (when *mcp-debug*
    (apply #'format *error-output* format-string args)
    (fresh-line *error-output*)
    (finish-output *error-output*)))

;;; ------------------------------------------------------------------
;;; tool_usage_stats - Observability for tool selection
;;; ------------------------------------------------------------------

(defun render-tool-usage-stats ()
  "Render current tool usage counters as human-readable text."
  (let* ((counts (tool-usage-snapshot))
         (evaluate-count (gethash "evaluate" *tool-call-counts* 0))
         (evaluate-pct (if (plusp *tool-call-total*)
                           (* 100.0 (/ evaluate-count *tool-call-total*))
                           0.0))
         (symbolic-no-assume-pct (if (plusp *symbolic-call-total*)
                                     (* 100.0 (/ *symbolic-calls-without-assumptions* *symbolic-call-total*))
                                     0.0))
         (lines (loop for (name . count) in counts
                      collect (format nil "  ~A: ~D" name count))))
    (format nil "Tool usage stats (process lifetime):~%total_calls: ~D~%evaluate_calls: ~D~%evaluate_percent: ~,2F~%symbolic_calls: ~D~%symbolic_calls_without_assumptions: ~D~%symbolic_calls_without_assumptions_percent: ~,2F~%symbolic_preflight_warnings: ~D~%counts:~%~{~A~%~}"
            *tool-call-total*
            evaluate-count
            evaluate-pct
            *symbolic-call-total*
            *symbolic-calls-without-assumptions*
            symbolic-no-assume-pct
            *symbolic-preflight-warnings*
            lines)))

(define-mcp-tool "tool_usage_stats"
    (:description "Return in-process MCP tool usage counters (total calls, evaluate calls/percentage, and per-tool counts).")
  ()
  (wrap-tool-result (render-tool-usage-stats) :format :text))

;;; ------------------------------------------------------------------
;;; Resources Handlers (Documentation v1)
;;; ------------------------------------------------------------------

(defun handle-resources-list (id)
  "Handle the resources/list request."
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-json-object
             "resources"
             (list
              (make-json-object
               "uri" "maxima://docs/index"
               "name" "Maxima MCP documentation index"
               "description" "Entry point for MCP documentation resources and templates."
               "mimeType" "text/markdown")))))

(defun handle-resources-templates-list (id)
  "Handle the resources/templates/list request."
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-json-object
             "resourceTemplates"
             (list
              (make-json-object
               "uriTemplate" "maxima://docs/topic/{name}"
               "name" "Maxima topic documentation"
               "description" "Documentation for a Maxima topic via describe(name)."
               "mimeType" "text/markdown")))))

(defun starts-with (string prefix)
  "Return T if STRING starts with PREFIX."
  (and (stringp string)
       (stringp prefix)
       (>= (length string) (length prefix))
       (string= prefix string :end2 (length prefix))))

(defun valid-doc-topic-char-p (ch)
  "Return T if CH is valid in a docs/topic identifier."
  (or (alphanumericp ch)
      (find ch "-_+$%?!" :test #'char=)))

(defun sanitize-doc-topic (name)
  "Sanitize NAME for use in describe(NAME). Returns NIL if invalid."
  (when (and (stringp name) (> (length name) 0))
    (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return #\/) name)))
      (when (and (> (length trimmed) 0)
                 (every #'valid-doc-topic-char-p trimmed))
        trimmed))))

(defun slurp-file-contents (pathname)
  "Read PATHNAME and return full text as a string."
  (with-open-file (in pathname :direction :input)
    (with-output-to-string (out)
      (loop for line = (read-line in nil nil)
            while line
            do (write-line line out)))))

(defun local-doc-path-candidates (topic)
  "Return candidate local documentation files for TOPIC."
  (list (format nil "doc/~A.md" topic)
        (format nil "doc/topics/~A.md" topic)
        (format nil "doc/~A.txt" topic)
        (format nil "doc/topics/~A.txt" topic)))

(defun read-local-topic-doc (topic)
  "Return local docs text for TOPIC if available, else NIL."
  (loop for candidate in (local-doc-path-candidates topic)
        for path = (probe-file candidate)
        when path
          do (return (slurp-file-contents path))
        finally (return nil)))

(defun parse-apropos-items (apropos-text)
  "Parse apropos output like [a,b,c] into a list of strings."
  (let* ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) apropos-text)))
    (if (and (> (length trimmed) 1)
             (char= (char trimmed 0) #\[)
             (char= (char trimmed (1- (length trimmed))) #\]))
        (let ((inner (subseq trimmed 1 (1- (length trimmed)))))
          (remove-if (lambda (s) (zerop (length s)))
                     (mapcar (lambda (s)
                               (string-trim '(#\Space #\Tab #\Newline #\Return) s))
                             (uiop:split-string inner :separator '(#\,)))))
        nil)))

(defun build-topic-doc (topic uri)
  "Build topic documentation and return two values: markdown and structured JSON object.
   Uses local doc/ files first, then apropos fallback. Avoids describe() side effects."
  (let* ((local-doc (read-local-topic-doc topic))
         (apropos-call (format nil "apropos(\"~A\")" topic))
         (apropos-text nil)
         (apropos-items nil)
         (source "error")
         (markdown nil))
    (when local-doc
      (setf source "local_docs"
            markdown (format nil "# ~A~%~%Source: local docs (`./doc`)~%~%~A~%"
                             topic local-doc)))
    (multiple-value-bind (apropos-result apropos-err) (parse-and-eval apropos-call)
      (unless apropos-err
        (setf apropos-text (if (stringp apropos-result)
                               apropos-result
                               (format-result apropos-result :text))
              apropos-items (parse-apropos-items apropos-text))))
    (unless markdown
      (if apropos-text
          (progn
            (setf source "apropos_fallback"
                  markdown (format nil "# ~A~%~%No local doc file found under `./doc`.~%Using `apropos(\"~A\")` fallback:~%~%```text~%~A~%```~%"
                                   topic topic apropos-text)))
          (setf source "error"
                markdown (format nil "# ~A~%~%Unable to fetch documentation from `./doc` or `apropos(\"~A\")`.~%"
                                 topic topic))))
    (values markdown
            (make-json-object
             "topic" topic
             "uri" uri
             "source" source
             "hasLocalDocs" (if local-doc t :false)
             "describeSuccess" :false
             "describeError" :null
             "apropos" (or apropos-items '())
             "markdown" markdown))))

(defun docs-index-markdown ()
  "Return markdown documentation index."
  (with-output-to-string (s)
    (format s "# Maxima MCP Docs~%~%")
    (format s "Available resources:~%")
    (format s "- `maxima://docs/index`~%~%")
    (format s "Available templates:~%")
    (format s "- `maxima://docs/topic/{name}`~%~%")
    (format s "Examples:~%")
    (format s "- `maxima://docs/topic/integrate`~%")
    (format s "- `maxima://docs/topic/solve`~%")
    (format s "- `maxima://docs/topic/plot2d`~%")))

(defun handle-resources-read (params id)
  "Handle the resources/read request."
  (let ((uri (json-object-get params "uri")))
    (unless (and uri (stringp uri))
      (return-from handle-resources-read
        (make-error-response id +invalid-params+ "Missing or invalid resource uri")))
    (cond
      ((string= uri "maxima://docs/index")
       (make-json-object
        "jsonrpc" "2.0"
        "id" id
        "result" (make-json-object
                  "contents"
                  (list (make-json-object
                         "uri" uri
                         "mimeType" "text/markdown"
                         "text" (docs-index-markdown))))))
      ((starts-with uri "maxima://docs/topic/")
       (let* ((raw-topic (subseq uri (length "maxima://docs/topic/")))
              (topic (sanitize-doc-topic raw-topic)))
         (unless topic
           (return-from handle-resources-read
             (make-error-response id +invalid-params+
                                  (format nil "Invalid docs topic in URI: ~A" uri))))
         (multiple-value-bind (topic-markdown topic-structured)
             (build-topic-doc topic uri)
           (make-json-object
            "jsonrpc" "2.0"
            "id" id
            "result" (make-json-object
                      "contents"
                      (list (make-json-object
                             "uri" uri
                             "mimeType" "text/markdown"
                             "text" topic-markdown)
                            (make-json-object
                             "uri" uri
                             "mimeType" "application/json"
                             "text" (json-encode-to-string topic-structured))))))))
      (t
       (make-error-response id +invalid-params+
                            (format nil "Unknown resource URI: ~A" uri))))))

;;; ------------------------------------------------------------------
;;; Prompts Handlers (Minimal Implementation)
;;; ------------------------------------------------------------------

(defun handle-prompts-list (id)
  "Handle the prompts/list request. Returns empty list."
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-json-object
             "prompts" #())))

;;; ------------------------------------------------------------------
;;; JSON-RPC Response Utilities
;;; ------------------------------------------------------------------

(defun make-success-response (id result)
  "Create a successful JSON-RPC response."
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" result))

(defun is-notification-p (request)
  "Return T if REQUEST is a notification (no id field)."
  (null (json-object-get request "id")))

;;; ------------------------------------------------------------------
;;; Batch Request Support
;;; ------------------------------------------------------------------

(defun handle-batch-request (requests session)
  "Handle a batch of JSON-RPC requests."
  (let ((responses nil))
    (dolist (request requests)
      (let ((response (handle-request request session)))
        (when response
          (push response responses))))
    (nreverse responses)))

(defun is-batch-request-p (parsed)
  "Return T if PARSED is a batch request (array of requests)."
  (and (listp parsed)
       (not (hash-table-p parsed))
       (every #'hash-table-p parsed)))
