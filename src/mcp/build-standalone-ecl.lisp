;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-standalone-ecl.lisp - Build standalone Maxima MCP executable with ECL
;;;
;;; Usage:
;;;   cd src/mcp
;;;   ecl --load build-standalone-ecl.lisp

(in-package :cl-user)

(format t "~%=== Building Maxima MCP (ECL) ===~%~%")

;;; ------------------------------------------------------------------
;;; Paths
;;; ------------------------------------------------------------------

(defparameter *mcp-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defparameter *src-dir*
  (truename (merge-pathnames "../" *mcp-dir*)))

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
;;; Register local ASDF systems
;;; ------------------------------------------------------------------

(format t "Registering local systems...~%")
(push (truename "./") asdf:*central-registry*)
(push (truename "../") asdf:*central-registry*)

;;; ------------------------------------------------------------------
;;; Load dependencies
;;; ------------------------------------------------------------------

(format t "Loading yason...~%")
(ql:quickload :yason :silent t)

(format t "Loading Maxima (via Quicklisp)...~%")
(ql:quickload :maxima :silent t)

(format t "Loading maxima-mcp...~%")
(asdf:load-system :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Build executable
;;; ------------------------------------------------------------------

(let ((output-path (merge-pathnames "maxima-mcp" *root-dir*)))
  (format t "~%Building executable: ~A~%" output-path)
  (c:build-program
   (namestring output-path)
   :lisp-files nil
   :epilogue-code '(maxima-mcp:main)))

(format t "~%Build complete!~%")
