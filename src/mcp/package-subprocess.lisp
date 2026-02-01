;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; package-subprocess.lisp - Package definition for subprocess-based testing
;;;
;;; This is a standalone package that doesn't depend on Maxima being loaded
;;; as a library. Used for testing with system Maxima via subprocess.

(in-package :cl-user)

(defpackage :maxima-mcp
  (:use :common-lisp)
  (:export
   ;; Main entry points
   #:main
   #:run-mcp-server
   ;; Session management
   #:make-mcp-session
   #:mcp-session-id
   #:mcp-session-default-format
   ;; Tool registration
   #:define-mcp-tool
   #:*mcp-tools*
   ;; Protocol
   #:handle-request
   ;; Errors
   #:mcp-error
   #:mcp-error-code
   #:mcp-error-message
   #:mcp-error-data
   ;; Subprocess testing
   #:test-subprocess
   #:start-maxima-subprocess
   #:stop-maxima-subprocess
   #:*use-subprocess*))
