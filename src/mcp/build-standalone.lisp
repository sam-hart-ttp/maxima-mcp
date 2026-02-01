;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-standalone.lisp - Build standalone Maxima MCP executable
;;;
;;; Usage:
;;;   cd /path/to/maxima-mcp/src/mcp
;;;   sbcl --load build-standalone.lisp

(in-package :cl-user)

(format t "~%=== Building Maxima MCP Standalone Executable ===~%~%")

;;; ------------------------------------------------------------------
;;; Paths
;;; ------------------------------------------------------------------

;; Directory this script is in: src/mcp/
(defparameter *mcp-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

;; src/ directory (parent of mcp/)
(defparameter *src-dir*
  (truename (merge-pathnames "../" *mcp-dir*)))

;; Project root (parent of src/)
(defparameter *root-dir*
  (truename (merge-pathnames "../../" *mcp-dir*)))

(format t "MCP directory: ~A~%" *mcp-dir*)
(format t "Src directory: ~A~%" *src-dir*)
(format t "Root directory: ~A~%" *root-dir*)

;;; ------------------------------------------------------------------
;;; Load Quicklisp
;;; ------------------------------------------------------------------

(format t "~%Loading Quicklisp...~%")
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                        (user-homedir-pathname))))
  (if (probe-file quicklisp-init)
      (load quicklisp-init)
      (error "Quicklisp not found. Please install Quicklisp first.")))

;;; ------------------------------------------------------------------
;;; Load defsystem from lisp-utils/ in project root
;;; ------------------------------------------------------------------

(format t "Loading defsystem...~%")
(load (merge-pathnames "lisp-utils/defsystem.lisp" *root-dir*))

;;; ------------------------------------------------------------------
;;; Compile and Load Maxima (from src/)
;;; ------------------------------------------------------------------

(let ((*default-pathname-defaults* *src-dir*))
  (format t "Compiling Maxima (this may take a while)...~%")
  (load (merge-pathnames "maxima-build.lisp" *src-dir*))
  (funcall (find-symbol "MAXIMA-COMPILE" :cl-user))

  (format t "Loading Maxima...~%")
  (funcall (find-symbol "MAXIMA-LOAD" :cl-user)))

(format t "Maxima loaded successfully.~%")

;;; ------------------------------------------------------------------
;;; Load yason (JSON library)
;;; ------------------------------------------------------------------

(format t "Loading yason...~%")
(ql:quickload :yason :silent t)

;;; ------------------------------------------------------------------
;;; Load MCP Files
;;; ------------------------------------------------------------------

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
    "tools-session.lisp"
    "tools-meta.lisp"
    "protocol.lisp"
    "transport.lisp"
    "main.lisp"))

(dolist (file *mcp-files*)
  (let ((filepath (merge-pathnames file *mcp-dir*)))
    (format t "  Loading ~A...~%" file)
    (load filepath)))

;;; ------------------------------------------------------------------
;;; Save Executable
;;; ------------------------------------------------------------------

(let ((output-path (merge-pathnames "maxima-mcp" *root-dir*)))
  (format t "~%Saving executable to ~A...~%" output-path)
  (sb-ext:save-lisp-and-die
   (namestring output-path)
   :toplevel #'maxima-mcp:main
   :executable t
   :compression t
   :save-runtime-options t))
