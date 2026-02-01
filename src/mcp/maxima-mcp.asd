;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: ASDF -*-
;;;
;;; maxima-mcp.asd - ASDF system definition for Maxima MCP server
;;;
;;; This file defines the maxima-mcp system, which provides a Model Context
;;; Protocol (MCP) interface to Maxima, enabling AI agents to interact with
;;; the computer algebra system via JSON-RPC 2.0 over stdio.

(in-package :asdf)

(defsystem "maxima-mcp"
  :description "MCP (Model Context Protocol) interface for Maxima"
  :version "0.1.0"
  :author "Maxima MCP Contributors"
  :license "GPL-2.0"
  :depends-on ("maxima" "yason" "uiop")
  :serial t
  :pathname ""
  :components
  ((:file "package")
   (:file "json")
   (:file "errors")
   (:file "session")
   (:file "format")
   (:file "tools")
   (:file "tools-core")
   (:file "tools-calculus")
   (:file "tools-algebra")
   (:file "tools-matrix")
   (:file "tools-linear")
   (:file "tools-ode")
   (:file "tools-vector")
   (:file "tools-fourier")
   (:file "tools-list")
   (:file "tools-misc")
   (:file "tools-extra")
   (:file "tools-plot")
   (:file "tools-session")
   (:file "tools-meta")
   (:file "protocol")
   (:file "transport")
   (:file "main")))

;; Standalone test system - uses subprocess, doesn't require maxima library
(defsystem "maxima-mcp/test"
  :description "Maxima MCP with subprocess backend for testing"
  :version "0.1.0"
  :depends-on ("yason" "uiop")
  :serial t
  :pathname ""
  :components
  ((:file "package-subprocess")
   (:file "json")
   (:file "errors-subprocess")
   (:file "maxima-subprocess")
   (:file "session-subprocess")
   (:file "format-subprocess")
   (:file "tools")
   (:file "tools-core")
   (:file "tools-calculus")
   (:file "tools-algebra")
   (:file "tools-matrix")
   (:file "tools-linear")
   (:file "tools-ode")
   (:file "tools-vector")
   (:file "tools-fourier")
   (:file "tools-list")
   (:file "tools-misc")
   (:file "tools-extra")
   (:file "tools-plot")
   (:file "tools-session")
   (:file "tools-meta")
   (:file "protocol")
   (:file "transport")
   (:file "main-subprocess")))
