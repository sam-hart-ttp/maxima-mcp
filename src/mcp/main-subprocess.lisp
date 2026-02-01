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
  (format t "Testing Maxima MCP server (subprocess mode)...~%~%")

  (setf *use-subprocess* t)
  (start-maxima-subprocess)

  (let ((session (make-mcp-session)))
    (initialize-session session)

    ;; Test evaluate
    (format t "1. Testing evaluate tool...~%")
    (let ((result (test-tool "evaluate" "expression" "2+2")))
      (format t "   2+2 = ~A~%~%" (json-object-get
                                   (first (json-object-get result "content"))
                                   "text")))

    ;; Test differentiate
    (format t "2. Testing differentiate tool...~%")
    (let ((result (test-tool "differentiate" "expression" "x^3" "variable" "x")))
      (format t "   d/dx(x^3) = ~A~%~%" (json-object-get
                                          (first (json-object-get result "content"))
                                          "text")))

    ;; Test integrate
    (format t "3. Testing integrate tool...~%")
    (let ((result (test-tool "integrate" "expression" "x^2" "variable" "x")))
      (format t "   integral(x^2, x) = ~A~%~%" (json-object-get
                                                 (first (json-object-get result "content"))
                                                 "text")))

    ;; Test solve
    (format t "4. Testing solve tool...~%")
    (let ((result (test-tool "solve" "equation" "x^2-4=0" "variable" "x")))
      (format t "   solve(x^2-4=0, x) = ~A~%~%" (json-object-get
                                                  (first (json-object-get result "content"))
                                                  "text")))

    ;; Test factor
    (format t "5. Testing factor tool...~%")
    (let ((result (test-tool "factor" "expression" "x^2-1")))
      (format t "   factor(x^2-1) = ~A~%~%" (json-object-get
                                              (first (json-object-get result "content"))
                                              "text")))

    ;; Test limit
    (format t "6. Testing limit tool...~%")
    (let ((result (test-tool "limit" "expression" "sin(x)/x" "variable" "x" "point" "0")))
      (format t "   limit(sin(x)/x, x, 0) = ~A~%~%" (json-object-get
                                                     (first (json-object-get result "content"))
                                                     "text")))

    (format t "All tests completed!~%")
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

;;; ------------------------------------------------------------------
;;; Test a Single Tool
;;; ------------------------------------------------------------------

(defun test-tool (tool-name &rest arg-pairs)
  "Test a tool interactively."
  (let ((session (make-mcp-session))
        (args (make-hash-table :test #'equal)))
    (loop for (key value) on arg-pairs by #'cddr
          do (setf (gethash key args) value))
    (handler-case
        (invoke-tool tool-name session args)
      (error (e)
        (format t "Error: ~A~%" e)))))
