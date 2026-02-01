;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; main.lisp - Entry point for Maxima MCP server
;;;
;;; Provides the main entry point for running the MCP server
;;; as a standalone executable or from within a running Lisp.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Main Entry Point
;;; ------------------------------------------------------------------

(defun main (&optional args)
  "Main entry point for the MCP server executable.
   ARGS are command-line arguments (if any)."
  (declare (ignore args))

  ;; Suppress any unwanted output during startup
  (let ((*standard-output* (make-broadcast-stream))
        (*error-output* *error-output*))
    ;; Initialize Maxima quietly
    (ensure-maxima-initialized))

  ;; Run the server on stdio
  (run-mcp-server :input *standard-input*
                  :output *standard-output*
                  :debug nil))

;;; ------------------------------------------------------------------
;;; SBCL Executable Build
;;; ------------------------------------------------------------------

#+sbcl
(defun build-executable (output-path)
  "Build a standalone executable at OUTPUT-PATH using SBCL."
  (sb-ext:save-lisp-and-die
   output-path
   :toplevel #'main
   :executable t
   :compression t
   :save-runtime-options t))

;;; ------------------------------------------------------------------
;;; CCL Executable Build
;;; ------------------------------------------------------------------

#+ccl
(defun build-executable (output-path)
  "Build a standalone executable at OUTPUT-PATH using CCL."
  (ccl:save-application
   output-path
   :toplevel-function #'main
   :prepend-kernel t))

;;; ------------------------------------------------------------------
;;; CLISP Executable Build
;;; ------------------------------------------------------------------

#+clisp
(defun build-executable (output-path)
  "Build a standalone executable at OUTPUT-PATH using CLISP."
  (ext:saveinitmem
   output-path
   :init-function #'main
   :executable t
   :quiet t
   :norc t))

;;; ------------------------------------------------------------------
;;; ECL Executable Build
;;; ------------------------------------------------------------------

#+ecl
(defun build-executable (output-path)
  "Build a standalone executable at OUTPUT-PATH using ECL."
  (c:build-program
   output-path
   :lisp-files nil
   :prologue-code '(require :maxima-mcp)
   :epilogue-code '(maxima-mcp:main)))

;;; ------------------------------------------------------------------
;;; Interactive Usage
;;; ------------------------------------------------------------------

(defun start-server (&key (debug nil))
  "Start the MCP server interactively.
   This is useful for testing from a REPL."
  (format *error-output* "Starting Maxima MCP server...~%")
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
  (format t "Testing Maxima MCP server (library mode)...~%")
  (ensure-maxima-initialized)
  (run-all-tool-tests :verbose t))

;;; ------------------------------------------------------------------
;;; Protocol Test
;;; ------------------------------------------------------------------

(defun test-protocol ()
  "Test the JSON-RPC protocol handling."
  (format t "Testing MCP protocol...~%~%")

  (ensure-maxima-initialized)
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

    (format t "Protocol tests completed!~%")))
