;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; transport.lisp - Transport layer for Maxima MCP
;;;
;;; Implements the stdio transport for MCP communication.
;;; Reads JSON-RPC messages from stdin and writes responses to stdout.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Transport Configuration
;;; ------------------------------------------------------------------

(defvar *mcp-debug* nil
  "When non-nil, enable debug output to stderr.")

(defun debug-log (format-string &rest args)
  "Write a debug message to stderr if debugging is enabled."
  (when *mcp-debug*
    (apply #'format *error-output* format-string args)
    (fresh-line *error-output*)
    (finish-output *error-output*)))

;;; ------------------------------------------------------------------
;;; Message Reading
;;; ------------------------------------------------------------------

(defun read-json-message (stream)
  "Read a JSON message from STREAM.
   Returns the parsed JSON object, or :eof on end of file, or :error on parse error."
  (handler-case
      (let ((line (read-line stream nil :eof)))
        (cond
          ((eq line :eof) :eof)
          ((string= line "") (read-json-message stream))  ; Skip empty lines
          (t
           (debug-log "Received: ~A" line)
           (handler-case
               (json-decode line)
             (error (e)
               (debug-log "JSON parse error: ~A" e)
               :error)))))
    (error (e)
      (debug-log "Read error: ~A" e)
      :eof)))

;;; ------------------------------------------------------------------
;;; Message Writing
;;; ------------------------------------------------------------------

(defun write-json-message (message stream)
  "Write a JSON message to STREAM followed by a newline."
  (let ((json-string (json-encode-to-string message)))
    (debug-log "Sending: ~A" json-string)
    (write-string json-string stream)
    (terpri stream)
    (finish-output stream)))

;;; ------------------------------------------------------------------
;;; Main Server Loop
;;; ------------------------------------------------------------------

(defun run-mcp-server (&key (input *standard-input*)
                             (output *standard-output*)
                             (debug nil))
  "Run the MCP server, reading from INPUT and writing to OUTPUT.
   This is the main entry point for the MCP server."
  (let ((*mcp-debug* debug)
        (*standard-output* output)
        (*error-output* *error-output*)
        (session (make-mcp-session)))

    ;; Initialize the session (and Maxima)
    (initialize-session session)

    (debug-log "MCP server starting...")

    ;; Main message loop
    (loop
      (let ((message (read-json-message input)))
        (cond
          ;; End of input - exit
          ((eq message :eof)
           (debug-log "Received EOF, exiting")
           (return))

          ;; Parse error - send error response
          ((eq message :error)
           (write-json-message
            (make-error-response nil +parse-error+ "JSON parse error")
            output))

          ;; Batch request
          ((is-batch-request-p message)
           (let ((responses (handle-batch-request message session)))
             (when responses
               (write-json-message responses output))))

          ;; Single request
          ((hash-table-p message)
           (let ((response (handle-request message session)))
             (when response
               (write-json-message response output))))

          ;; Invalid message format
          (t
           (write-json-message
            (make-error-response nil +invalid-request+ "Invalid message format")
            output)))))))

;;; ------------------------------------------------------------------
;;; Alternative Entry Points
;;; ------------------------------------------------------------------

(defun process-single-request (json-string session)
  "Process a single JSON-RPC request string and return the response string.
   Useful for testing or embedding."
  (let* ((request (handler-case
                      (json-decode json-string)
                    (error ()
                      (return-from process-single-request
                        (json-encode-to-string
                         (make-error-response nil +parse-error+ "JSON parse error"))))))
         (response (if (is-batch-request-p request)
                       (handle-batch-request request session)
                       (handle-request request session))))
    (when response
      (json-encode-to-string response))))

;;; ------------------------------------------------------------------
;;; Interactive Testing
;;; ------------------------------------------------------------------

(defun test-tool (tool-name &rest arg-pairs)
  "Test a tool interactively. ARG-PAIRS is a plist of argument names and values.
   Example: (test-tool \"evaluate\" \"expression\" \"2+2\")"
  (let ((session (make-mcp-session))
        (args (make-hash-table :test #'equal)))
    ;; Build arguments hash table
    (loop for (key value) on arg-pairs by #'cddr
          do (setf (gethash key args) value))
    ;; Initialize session
    (initialize-session session)
    ;; Invoke tool
    (handler-case
        (invoke-tool tool-name session args)
      (error (e)
        (format t "Error: ~A~%" e)))))

(defun test-request (json-string)
  "Test processing a JSON-RPC request string."
  (let ((session (make-mcp-session)))
    (initialize-session session)
    (process-single-request json-string session)))
