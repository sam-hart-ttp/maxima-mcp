;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-mcp-core.lisp - Build a preloaded Maxima MCP core for fast startup
;;;
;;; Usage:
;;;   cd src/mcp
;;;   sbcl --load build-mcp-core.lisp

(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf))

(defparameter *windows-host-p*
  (uiop:os-windows-p)
  "True when building on Windows.")

(defparameter *mcp-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defparameter *src-dir*
  (truename (merge-pathnames "../" *mcp-dir*)))

(defparameter *root-dir*
  (truename (merge-pathnames "../../" *mcp-dir*)))

(defparameter *mcp-core-output-path*
  (merge-pathnames "binary-sbcl/maxima-mcp.core" *src-dir*)
  "Path to the preloaded Maxima MCP core.")

(format t "~%=== Building Maxima MCP Core ===~%~%")
(format t "MCP directory: ~A~%" *mcp-dir*)
(format t "Src directory: ~A~%" *src-dir*)
(format t "Root directory: ~A~%" *root-dir*)
(format t "Core path: ~A~%" *mcp-core-output-path*)

(when *windows-host-p*
  (format t "~%Configuring Maxima source tree for Windows...~%")
  (let ((*default-pathname-defaults* *root-dir*))
    (load (merge-pathnames "configure.lisp" *root-dir*))
    (funcall (find-symbol "CONFIGURE" :cl-user)
             :interactive nil
             :is-win32 t
             :maxima-directory (uiop:native-namestring *root-dir*)
             :sbcl-name (or (and (boundp 'sb-ext:*posix-argv*)
                                 (first sb-ext:*posix-argv*))
                            "sbcl"))))

(format t "~%Loading defsystem...~%")
(load (merge-pathnames "lisp-utils/defsystem.lisp" *root-dir*))

(let ((*default-pathname-defaults* *src-dir*))
  (format t "Loading maxima-build.lisp...~%")
  (load (merge-pathnames "maxima-build.lisp" *src-dir*))
  (format t "Compiling Maxima (if needed)...~%")
  (funcall (find-symbol "MAXIMA-COMPILE" :cl-user))
  (format t "Loading Maxima...~%")
  (funcall (find-symbol "MAXIMA-LOAD" :cl-user)))

(unless (find-package :quicklisp)
  (format t "Loading Quicklisp...~%")
  (let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                         (user-homedir-pathname))))
    (if (probe-file quicklisp-init)
        (load quicklisp-init)
        (error "Quicklisp not found. Please install Quicklisp first."))))

(format t "Loading yason...~%")
(ql:quickload :yason :silent t)

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
  (load (merge-pathnames file *mcp-dir*)))

(format t "~%Saving MCP core to ~A...~%" *mcp-core-output-path*)
(ensure-directories-exist *mcp-core-output-path*)

#+sbcl
(sb-ext:save-lisp-and-die
 (namestring *mcp-core-output-path*)
 :toplevel (symbol-function (find-symbol "MAIN" :maxima-mcp))
 :save-runtime-options t)

