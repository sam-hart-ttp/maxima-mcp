;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; test.lisp - Test runner for Maxima MCP (subprocess mode)
;;;
;;; Usage:
;;;   sbcl --load test.lisp
;;;
;;; This loads the MCP system with subprocess backend and runs tests.

(in-package :cl-user)

(format t "~%=== Maxima MCP Test Runner ===~%~%")

;; Load Quicklisp
(format t "Loading Quicklisp...~%")
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))

;; Register this directory
(format t "Registering ASDF directory...~%")
(push (truename "./") asdf:*central-registry*)

;; Load yason
(format t "Loading yason...~%")
(ql:quickload :yason :silent t)

;; Load the test system
(format t "Loading maxima-mcp/test...~%")
(asdf:load-system :maxima-mcp/test)

(format t "~%=== Running Tests ===~%~%")

;; Run the subprocess test
(format t "--- Subprocess Backend Test ---~%")
(maxima-mcp:test-subprocess)

(format t "~%--- Quick Test ---~%")
(maxima-mcp:quick-test)

(format t "~%--- Protocol Test ---~%")
(maxima-mcp:test-protocol)

(format t "~%=== All Tests Complete ===~%")
