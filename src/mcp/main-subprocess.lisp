;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; main-subprocess.lisp - Entry point for subprocess-based testing
;;;
;;; This version uses the system Maxima via subprocess for testing.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Enable Subprocess Mode
;;; ------------------------------------------------------------------

(setf *use-subprocess* t)

;;; ------------------------------------------------------------------
;;; Main Entry Point
;;; ------------------------------------------------------------------

(defun main (&optional args)
  "Main entry point for the MCP server executable."
  (declare (ignore args))
  (setf *use-subprocess* t)
  (run-mcp-server :input *standard-input*
                  :output *standard-output*
                  :debug nil))

;;; ------------------------------------------------------------------
;;; Interactive Usage
;;; ------------------------------------------------------------------

(defun start-server (&key (debug nil))
  "Start the MCP server interactively."
  (setf *use-subprocess* t)
  (format *error-output* "Starting Maxima MCP server (subprocess mode)...~%")
  (format *error-output* "Send JSON-RPC requests on stdin.~%")
  (format *error-output* "Press Ctrl+D to exit.~%~%")
  (run-mcp-server :input *standard-input*
                  :output *standard-output*
                  :debug debug))

;;; ------------------------------------------------------------------
;;; Quick Test Functions
;;; ------------------------------------------------------------------

(defun quick-test ()
  "Run a quick test of the MCP server functionality."
  (format t "Testing Maxima MCP server (subprocess mode)...~%")
  (setf *use-subprocess* t)
  (start-maxima-subprocess)
  (unwind-protect
      (run-all-tool-tests :verbose t)
    (stop-maxima-subprocess)))

(defun test-protocol ()
  "Test the JSON-RPC protocol handling."
  (format t "Testing MCP protocol (subprocess mode)...~%~%")

  (setf *use-subprocess* t)
  (start-maxima-subprocess)

  (let ((session (make-mcp-session)))
    (initialize-session session)

    ;; Test initialize
    (format t "1. Testing initialize...~%")
    (let ((response (process-single-request
                     "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}"
                     session)))
      (format t "   Response: ~A~%~%" (subseq response 0 (min 100 (length response)))))

    ;; Test tools/list
    (format t "2. Testing tools/list...~%")
    (let ((response (process-single-request
                     "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\",\"params\":{}}"
                     session)))
      (format t "   Found ~A tools~%~%"
              (length (json-object-get
                       (json-object-get (json-decode response) "result")
                       "tools"))))

    ;; Test tools/call
    (format t "3. Testing tools/call (evaluate)...~%")
    (let ((response (process-single-request
                     "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"evaluate\",\"arguments\":{\"expression\":\"diff(x^2,x)\"}}}"
                     session)))
      (format t "   Response: ~A~%~%" response))

    (format t "Protocol tests completed!~%")
    (stop-maxima-subprocess)))
