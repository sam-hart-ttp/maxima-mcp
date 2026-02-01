;;; Build a Maxima core without the auto-start toplevel
;;; Usage: cd src && sbcl --load maxima-build.lisp, then (maxima-compile), (maxima-load), then load this file

(in-package :cl-user)

(defun maxima-mcp-dump ()
  "Save a Maxima core that can accept SBCL command-line options."
  (sb-ext:save-lisp-and-die "binary-sbcl/maxima-base.core"
   ;; No toplevel - SBCL will process command line normally
   :toplevel nil
   :compression t
   :save-runtime-options t))
