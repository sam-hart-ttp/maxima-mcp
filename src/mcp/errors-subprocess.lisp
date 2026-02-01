;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; errors-subprocess.lisp - Error handling for subprocess-based testing
;;;
;;; Standalone error handling that doesn't depend on Maxima library.

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

(defconstant +parse-error+ -32700)
(defconstant +invalid-request+ -32600)
(defconstant +method-not-found+ -32601)
(defconstant +invalid-params+ -32602)
(defconstant +internal-error+ -32603)
(defconstant +tool-not-found+ -32001)
(defconstant +tool-execution-error+ -32002)
(defconstant +maxima-error+ -32010)

;;; ------------------------------------------------------------------
;;; Error Construction
;;; ------------------------------------------------------------------

(defun make-mcp-error (code message &optional data)
  (make-condition 'mcp-error :code code :message message :data data))

(defun signal-mcp-error (code message &optional data)
  (error 'mcp-error :code code :message message :data data))

(defun make-error-response (id code message &optional data)
  (let ((error-obj (make-json-object "code" code "message" message)))
    (when data
      (json-object-set error-obj "data" data))
    (make-json-object "jsonrpc" "2.0"
                      "id" id
                      "error" error-obj)))

;;; ------------------------------------------------------------------
;;; Maxima Error Capture (Subprocess version)
;;; ------------------------------------------------------------------

(defvar *last-subprocess-error* nil
  "Stores the last error message captured from subprocess output.")

(defun capture-maxima-error ()
  "Return the last captured error message from subprocess mode.
   In subprocess mode, error details are typically included in the evaluation
   output rather than captured separately. This returns the stored error if
   available, or a generic message otherwise."
  (or *last-subprocess-error*
      "Maxima evaluation failed (check expression syntax)"))

(defun set-subprocess-error (message)
  "Store an error message for later retrieval by capture-maxima-error."
  (setf *last-subprocess-error* message))

(defun clear-subprocess-error ()
  "Clear the stored subprocess error."
  (setf *last-subprocess-error* nil))

(defun maxima-expr-to-string (expr)
  "Convert expression to string."
  (format nil "~A" expr))

;;; ------------------------------------------------------------------
;;; Safe Evaluation Wrapper (Subprocess version)
;;; ------------------------------------------------------------------

(defmacro with-maxima-error-handling (&body body)
  "Execute BODY with error handling."
  `(handler-case
       (values (progn ,@body) nil)
     (error (c)
       (values nil (format nil "Error: ~A" c)))))

(defmacro with-error-response ((id) &body body)
  (let ((err (gensym "ERR")))
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
