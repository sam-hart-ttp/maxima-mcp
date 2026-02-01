;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-standalone-ecl-subprocess.lisp - Build standalone MCP using Maxima subprocess
;;;
;;; Usage:
;;;   cd src/mcp
;;;   ecl --load build-standalone-ecl-subprocess.lisp

(in-package :cl-user)

(format t "~%=== Building Maxima MCP (ECL, subprocess backend) ===~%~%")

;;; ------------------------------------------------------------------
;;; Paths
;;; ------------------------------------------------------------------

(defparameter *mcp-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defparameter *root-dir*
  (truename (merge-pathnames "../../" *mcp-dir*)))

(format t "MCP directory: ~A~%" *mcp-dir*)
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

(format t "Loading maxima-mcp/test...~%")
(asdf:load-system :maxima-mcp/test)

;;; ------------------------------------------------------------------
;;; Build executable
;;; ------------------------------------------------------------------

(let ((output-path (merge-pathnames "maxima-mcp-subprocess" *root-dir*)))
  (format t "~%Building executable: ~A~%" output-path)
  (c:build-program
   (namestring output-path)
   :lisp-files nil
   :epilogue-code '(maxima-mcp:main)))

(format t "~%Build complete!~%")
