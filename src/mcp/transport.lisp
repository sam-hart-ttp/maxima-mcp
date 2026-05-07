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

(defvar *mcp-wire-log-path* nil
  "Optional file path for transport-level wire logging.")

(defvar *mcp-stdio-framing* :framed
  "Response framing for the current stdio session, either :FRAMED or :LEGACY.")

(defun wire-log (format-string &rest args)
  "Append a transport log entry to *MCP-WIRE-LOG-PATH* when configured."
  (when *mcp-wire-log-path*
    (handler-case
        (with-open-file (stream *mcp-wire-log-path*
                                :direction :output
                                :if-exists :append
                                :if-does-not-exist :create)
          (write-string (multiple-value-bind (sec min hour day month year)
                            (get-decoded-time)
                          (format nil "[~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D] "
                                  year month day hour min sec))
                        stream)
          (apply #'format stream format-string args)
          (terpri stream))
      (error () nil))))

(defun debug-log (format-string &rest args)
  "Write a debug message to stderr if debugging is enabled."
  (when *mcp-debug*
    (apply #'format *error-output* format-string args)
    (fresh-line *error-output*)
    (finish-output *error-output*)))

;;; ------------------------------------------------------------------
;;; Message Reading
;;; ------------------------------------------------------------------

(defun trim-header-line (line)
  "Trim carriage returns and surrounding whitespace from a header LINE."
  (string-trim '(#\Space #\Tab #\Return) line))

(defun json-message-line-p (line)
  "Return true when LINE looks like a line-delimited JSON-RPC message."
  (and (plusp (length line))
       (or (char= (char line 0) #\{)
           (char= (char line 0) #\[))))

(defun parse-content-length (headers)
  "Extract Content-Length from HEADERS or return NIL."
  (loop for (name . value) in headers
        when (string-equal name "Content-Length")
          do (return (parse-integer value :junk-allowed t))
        finally (return nil)))

(defun read-framed-body (stream content-length)
  "Read CONTENT-LENGTH characters from STREAM and return them as a string."
  (let ((buffer (make-string content-length)))
    (let ((count (read-sequence buffer stream)))
      (if (= count content-length)
          buffer
          :eof))))

(defun read-json-message (stream)
  "Read a JSON message from STREAM.
   Returns the parsed JSON object, or :eof on end of file, or :error on parse error."
  (handler-case
      (labels ((decode-json (text)
                 (handler-case
                     (json-decode text)
                   (error (e)
                     (debug-log "JSON parse error: ~A" e)
                     :error)))
               (read-framed-message (first-line)
                 (let ((headers nil)
                       (line first-line))
                   (loop
                     for trimmed = (trim-header-line line)
                     do (cond
                          ((string= trimmed "")
                           (return))
                          (t
                           (let ((separator (position #\: trimmed)))
                             (unless separator
                               (debug-log "Invalid header line: ~A" trimmed)
                               (return-from read-framed-message :error))
                             (push (cons (subseq trimmed 0 separator)
                                         (trim-header-line (subseq trimmed (1+ separator))))
                                   headers))))
                     do (setf line (read-line stream nil :eof))
                     when (eq line :eof)
                       do (return-from read-framed-message :eof))
                   (let ((content-length (parse-content-length headers)))
                     (unless (and content-length (plusp content-length))
                       (debug-log "Missing or invalid Content-Length header: ~S" headers)
                       (return-from read-framed-message :error))
                     (let ((body (read-framed-body stream content-length)))
               (when (eq body :eof)
                 (return-from read-framed-message :eof))
               (debug-log "Received framed message: ~A" body)
               (wire-log "RECV framed ~A" body)
               (setf *mcp-stdio-framing* :framed)
               (decode-json body))))))
        (let ((first-line (read-line stream nil :eof)))
          (cond
            ((eq first-line :eof) :eof)
            (t
             (let ((line (trim-header-line first-line)))
               (cond
                 ((string= line "")
                  (read-json-message stream))
                 ;; Backward-compatible fallback for line-delimited JSON.
                 ;; JSON-RPC objects contain colons, so detect them before
                 ;; treating colon-containing input as framed headers.
                 ((or (json-message-line-p line)
                      (not (find #\: first-line)))
                  (debug-log "Received legacy line message: ~A" line)
                  (wire-log "RECV legacy ~A" line)
                  (setf *mcp-stdio-framing* :legacy)
                  (decode-json line))
                 (t
                  (read-framed-message first-line))))))))
    (error (e)
      (debug-log "Read error: ~A" e)
      (wire-log "READ error ~A" e)
      :eof)))

;;; ------------------------------------------------------------------
;;; Message Writing
;;; ------------------------------------------------------------------

(defun write-json-message (message stream)
  "Write a JSON message to STREAM using the active stdio framing."
  (let ((json-string (json-encode-to-string message)))
    (debug-log "Sending: ~A" json-string)
    (wire-log "SEND ~A" json-string)
    (ecase *mcp-stdio-framing*
      (:legacy
       (write-string json-string stream)
       (terpri stream))
      (:framed
       (write-string "Content-Length: " stream)
       (write-string (princ-to-string (length json-string)) stream)
       (write-char #\Return stream)
       (write-char #\Linefeed stream)
       (write-char #\Return stream)
       (write-char #\Linefeed stream)
       (write-string json-string stream)))
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
        (*mcp-wire-log-path* (uiop:getenv "MAXIMA_MCP_WIRE_LOG"))
        (*mcp-stdio-framing* :framed)
        (*standard-output* output)
        (*error-output* *error-output*)
        (session (make-mcp-session)))

    ;; Initialize the session (and Maxima)
    (initialize-session session)
    (wire-log "SERVER start")

    (debug-log "MCP server starting...")

    ;; Main message loop
    (loop
      (let ((message (read-json-message input)))
        (cond
          ;; End of input - exit
          ((eq message :eof)
           (debug-log "Received EOF, exiting")
           (wire-log "SERVER eof/exit")
           (return))

          ;; Parse error - send error response
          ((eq message :error)
           (wire-log "SERVER parse-error response")
           (write-json-message
            (make-error-response nil +parse-error+ "JSON parse error")
            output))

          ;; Batch request
          ((is-batch-request-p message)
           (wire-log "SERVER batch request")
           (let ((responses (handle-batch-request message session)))
             (when responses
               (write-json-message responses output))))

          ;; Single request
          ((hash-table-p message)
           (wire-log "SERVER single request method=~A" (json-object-get message "method"))
           (let ((response (handle-request message session)))
             (when response
               (write-json-message response output))))

          ;; Invalid message format
          (t
           (wire-log "SERVER invalid message format")
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
