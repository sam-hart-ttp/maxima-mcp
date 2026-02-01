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

;;; ------------------------------------------------------------------
;;; Request Handling
;;; ------------------------------------------------------------------

(defun handle-request (request session)
  "Handle a JSON-RPC request. Returns a response object."
  (handler-case
      (let ((jsonrpc (json-object-get request "jsonrpc"))
            (method (json-object-get request "method"))
            (params (json-object-get request "params"))
            (id (json-object-get request "id")))

        ;; Validate JSON-RPC version
        (unless (equal jsonrpc "2.0")
          (return-from handle-request
            (make-error-response id +invalid-request+ "Invalid JSON-RPC version")))

        ;; Dispatch based on method
        (let ((response (dispatch-method method params session id)))
          ;; If id is nil, this is a notification and we don't send a response
          (if (and (null id) (not (json-object-get response "error")))
              nil
              response)))

    (mcp-error (e)
      (make-error-response (json-object-get request "id")
                           (mcp-error-code e)
                           (mcp-error-message e)
                           (mcp-error-data e)))
    (error (e)
      (make-error-response (json-object-get request "id")
                           +internal-error+
                           (format nil "Internal error: ~A" e)))))

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
                           "version" *server-version*))))

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

    (handler-case
        (let ((result (invoke-tool tool-name session (or arguments
                                                         (make-hash-table :test #'equal)))))
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

;;; ------------------------------------------------------------------
;;; Resources Handlers (Minimal Implementation)
;;; ------------------------------------------------------------------

(defun handle-resources-list (id)
  "Handle the resources/list request. Returns empty list."
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-json-object
             "resources" nil)))

(defun handle-resources-read (params id)
  "Handle the resources/read request."
  (declare (ignore params))
  (make-error-response id +method-not-found+ "No resources available"))

;;; ------------------------------------------------------------------
;;; Prompts Handlers (Minimal Implementation)
;;; ------------------------------------------------------------------

(defun handle-prompts-list (id)
  "Handle the prompts/list request. Returns empty list."
  (make-json-object
   "jsonrpc" "2.0"
   "id" id
   "result" (make-json-object
             "prompts" nil)))

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
