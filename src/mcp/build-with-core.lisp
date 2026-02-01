;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-with-core.lisp - Build MCP executable using Maxima core
;;;
;;; Usage:
;;;   cd src/mcp
;;;   sbcl --core ../binary-sbcl/maxima.core --noinform --disable-debugger \
;;;        --eval '(load "build-with-core.lisp")' \
;;;        --eval '(build-maxima-mcp)'

(in-package :cl-user)

(format *error-output* "~%=== Maxima MCP Build Script ===~%~%")

;; Check if Maxima is loaded
(unless (find-package :maxima)
  (error "Maxima not loaded. Start SBCL with: sbcl --core ../binary-sbcl/maxima.core"))

(format *error-output* "Maxima package found.~%")

;; Ensure Quicklisp is available
(unless (find-package :quicklisp)
  (format *error-output* "Loading Quicklisp...~%")
  (let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                          (user-homedir-pathname))))
    (if (probe-file quicklisp-init)
        (load quicklisp-init)
        (error "Quicklisp not found. Please install Quicklisp first."))))

;; Load yason
(format *error-output* "Loading yason...~%")
(ql:quickload :yason :silent t)

;; Load the MCP files in order
(format *error-output* "Loading Maxima MCP components...~%")

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
  (format *error-output* "  Loading ~A...~%" file)
  (load file))

(format *error-output* "~%MCP components loaded.~%")

(defun build-maxima-mcp (&optional (output-path "../../maxima-mcp"))
  "Build the Maxima MCP executable."
  (format *error-output* "~%Building executable: ~A~%" output-path)
  (sb-ext:save-lisp-and-die
   output-path
   :toplevel #'maxima-mcp:main
   :executable t
   :compression t
   :save-runtime-options t))
