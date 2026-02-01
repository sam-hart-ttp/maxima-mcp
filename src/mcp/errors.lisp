;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; errors.lisp - Error handling for Maxima MCP
;;;
;;; Provides error capture and formatting utilities, integrating with
;;; Maxima's error system (with-$error, maxima-$error condition).

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; MCP Error Condition
;;; ------------------------------------------------------------------

(define-condition mcp-error (error)
  ((code :initarg :code :reader mcp-error-code)
   (message :initarg :message :reader mcp-error-message)
   (data :initarg :data :initform nil :reader mcp-error-data))
  (:documentation "Condition for MCP protocol errors.")
  (:report (lambda (c stream)
             (format stream "MCP Error ~A: ~A"
                     (mcp-error-code c)
                     (mcp-error-message c)))))

;;; ------------------------------------------------------------------
;;; JSON-RPC 2.0 Error Codes
;;; ------------------------------------------------------------------

(defconstant +parse-error+ -32700
  "Invalid JSON was received by the server.")

(defconstant +invalid-request+ -32600
  "The JSON sent is not a valid Request object.")

(defconstant +method-not-found+ -32601
  "The method does not exist / is not available.")

(defconstant +invalid-params+ -32602
  "Invalid method parameter(s).")

(defconstant +internal-error+ -32603
  "Internal JSON-RPC error.")

;;; MCP-specific error codes (from -32000 to -32099)
(defconstant +tool-not-found+ -32001
  "The requested tool was not found.")

(defconstant +tool-execution-error+ -32002
  "Error during tool execution.")

(defconstant +maxima-error+ -32010
  "Error from Maxima evaluation.")

;;; ------------------------------------------------------------------
;;; Error Construction
;;; ------------------------------------------------------------------

(defun make-mcp-error (code message &optional data)
  "Create an MCP error condition."
  (make-condition 'mcp-error :code code :message message :data data))

(defun signal-mcp-error (code message &optional data)
  "Signal an MCP error."
  (error 'mcp-error :code code :message message :data data))

(defun make-error-response (id code message &optional data)
  "Create a JSON-RPC 2.0 error response object."
  (let ((error-obj (make-json-object "code" code "message" message)))
    (when data
      (json-object-set error-obj "data" data))
    (make-json-object "jsonrpc" "2.0"
                      "id" id
                      "error" error-obj)))

;;; ------------------------------------------------------------------
;;; Maxima Error Capture
;;; ------------------------------------------------------------------

(defun capture-maxima-error ()
  "Capture the current Maxima error message.
   Returns a string describing the error."
  (handler-case
      (let ((err-list maxima::$error))
        (if (and (consp err-list) (consp (cdr err-list)))
            ;; $error is ((mlist) format-string arg1 arg2 ...)
            (let ((format-string (second err-list))
                  (args (cddr err-list)))
              (if (stringp format-string)
                  (apply #'format nil
                         (substitute #\~ #\~ format-string)
                         (mapcar #'maxima-expr-to-string args))
                  (format nil "~S" err-list)))
            "Unknown Maxima error"))
    (error (e)
      (format nil "Error capturing Maxima error: ~A" e))))

(defun maxima-expr-to-string (expr)
  "Convert a Maxima expression to a string for error messages."
  (handler-case
      (with-output-to-string (s)
        (let ((maxima::$display2d nil))
          (maxima::mgrind expr s)))
    (error ()
      (format nil "~S" expr))))

;;; ------------------------------------------------------------------
;;; Safe Evaluation Wrapper
;;; ------------------------------------------------------------------

(defmacro with-maxima-error-handling (&body body)
  "Execute BODY with Maxima error handling. Returns (values result error-string).
   If an error occurs, result is nil and error-string describes the error.
   If successful, result is the value and error-string is nil."
  `(handler-case
       (maxima::with-$error
         (values (progn ,@body) nil))
     (maxima::maxima-$error (c)
       (declare (ignore c))
       (values nil (capture-maxima-error)))
     (error (c)
       (values nil (format nil "Lisp error: ~A" c)))))

(defmacro with-error-response ((id) &body body)
  "Execute BODY and convert any errors to an MCP error response.
   ID is the JSON-RPC request id."
  (let ((result (gensym "RESULT"))
        (err (gensym "ERR")))
    `(handler-case
         (progn ,@body)
       (mcp-error (,err)
         (make-error-response ,id
                              (mcp-error-code ,err)
                              (mcp-error-message ,err)
                              (mcp-error-data ,err)))
       (error (,err)
         (make-error-response ,id
                              +internal-error+
                              (format nil "~A" ,err))))))
