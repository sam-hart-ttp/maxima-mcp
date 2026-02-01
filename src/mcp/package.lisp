;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; package.lisp - Package definition for Maxima MCP server
;;;
;;; Defines the MAXIMA-MCP package with imports from MAXIMA and exports
;;; for the public API.

(in-package :cl-user)

(defpackage :maxima-mcp
  (:use :common-lisp)
  ;; Note: We don't import from MAXIMA because some symbols may not exist
  ;; until Maxima is initialized. Use maxima:: prefix to access Maxima symbols.
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
   #:mcp-error-data))
