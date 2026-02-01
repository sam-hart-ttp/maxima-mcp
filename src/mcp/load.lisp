;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; load.lisp - Load script for Maxima MCP
;;;
;;; This script loads the Maxima MCP system for interactive use or testing.
;;;
;;; Usage (with Maxima core image):
;;;   cd src/mcp
;;;   sbcl --core ../binary-sbcl/maxima.core --load load.lisp
;;;
;;; Then from the REPL:
;;;   (maxima-mcp:run-mcp-server)      ; Start the MCP server
;;;   (maxima-mcp:test-tool "evaluate" '(("expression" . "2+2")))

(in-package :cl-user)

(format t "~%=== Loading Maxima MCP ===~%~%")

;; Check if Maxima is loaded
(unless (find-package :maxima)
  (error "Maxima not loaded. Start SBCL with: sbcl --core ../binary-sbcl/maxima.core"))

(format t "Maxima package found.~%")

;; Ensure Quicklisp is available
(unless (find-package :quicklisp)
  (format t "Loading Quicklisp...~%")
  (let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                          (user-homedir-pathname))))
    (if (probe-file quicklisp-init)
        (load quicklisp-init)
        (error "Quicklisp not found. Please install Quicklisp first."))))

;; Load yason
(format t "Loading yason...~%")
(ql:quickload :yason :silent t)

;; Load the MCP files in order
(format t "Loading Maxima MCP components...~%")

(defparameter *mcp-files*
  '("package.lisp"
    "json.lisp"
    "errors.lisp"
    "session.lisp"
    "format.lisp"
    "tools.lisp"
    "tools-core.lisp"
    "tools-calculus.lisp"
    "tools-algebra.lisp"
    "tools-matrix.lisp"
    "tools-linear.lisp"
    "tools-ode.lisp"
    "tools-vector.lisp"
    "tools-fourier.lisp"
    "tools-list.lisp"
    "tools-misc.lisp"
    "tools-extra.lisp"
    "tools-plot.lisp"
    "tools-session.lisp"
    "tools-meta.lisp"
    "protocol.lisp"
    "transport.lisp"
    "test-common.lisp"
    "main.lisp"))

(dolist (file *mcp-files*)
  (format t "  Loading ~A...~%" file)
  (load file))

(format t "~%Maxima MCP loaded successfully!~%")
(format t "~%To start the MCP server:~%")
(format t "  (maxima-mcp:run-mcp-server)~%")
(format t "~%To test a tool:~%")
(format t "  (maxima-mcp:test-tool \"evaluate\" '((\"expression\" . \"diff(x^2,x)\")))~%")
(format t "~%")
