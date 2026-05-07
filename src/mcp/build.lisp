;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build.lisp - Build script for Maxima MCP executable
;;;
;;; This script builds a standalone executable for the Maxima MCP server.
;;;
;;; Usage with SBCL:
;;;   sbcl --load build.lisp
;;;
;;; Usage with other Lisps:
;;;   <lisp> --load build.lisp

(in-package :cl-user)

;;; ------------------------------------------------------------------
;;; Configuration
;;; ------------------------------------------------------------------

(defparameter *output-name* #+windows "maxima-mcp.exe"
                            #-windows "maxima-mcp"
  "Name of the output executable.")

(defparameter *output-directory* (truename "../../")
  "Directory for the output executable.")

;;; ------------------------------------------------------------------
;;; Load Dependencies
;;; ------------------------------------------------------------------

(format t "~%=== Maxima MCP Build Script ===~%~%")

;; Ensure Quicklisp is available
(unless (find-package :quicklisp)
  (format t "Loading Quicklisp...~%")
  (let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                          (user-homedir-pathname))))
    (if (probe-file quicklisp-init)
        (load quicklisp-init)
        (error "Quicklisp not found. Please install Quicklisp first."))))

;; Register the local ASDF systems
(format t "Registering local systems...~%")
(push (truename "./") asdf:*central-registry*)
(push (truename "../") asdf:*central-registry*)

;; Load yason (JSON library)
(format t "Loading yason...~%")
(ql:quickload :yason :silent t)

;; Load Maxima
(format t "Loading Maxima...~%")
(ql:quickload :maxima :silent t)

;; Load maxima-mcp
(format t "Loading maxima-mcp...~%")
(asdf:load-system :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Build Executable
;;; ------------------------------------------------------------------

(let ((output-path (merge-pathnames *output-name* *output-directory*)))
  (format t "~%Building executable: ~A~%" output-path)

  #+sbcl
  (progn
    (format t "Using SBCL save-lisp-and-die...~%")
    (sb-ext:save-lisp-and-die
     (namestring output-path)
     :toplevel #'maxima-mcp:main
     :executable t
     :save-runtime-options t))

  #+ccl
  (progn
    (format t "Using CCL save-application...~%")
    (ccl:save-application
     (namestring output-path)
     :toplevel-function #'maxima-mcp:main
     :prepend-kernel t))

  #+clisp
  (progn
    (format t "Using CLISP saveinitmem...~%")
    (ext:saveinitmem
     (namestring output-path)
     :init-function #'maxima-mcp:main
     :executable t
     :quiet t
     :norc t))

  #+ecl
  (progn
    (format t "Using ECL c:build-program...~%")
    (c:build-program
     (namestring output-path)
     :lisp-files nil
     :epilogue-code '(maxima-mcp:main)))

  #-(or sbcl ccl clisp ecl)
  (error "Unsupported Lisp implementation. Please use SBCL, CCL, CLISP, or ECL."))

(format t "~%Build complete!~%")
