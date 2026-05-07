;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-maxima-core.lisp - Build a preloaded Maxima core for fast MCP startup
;;;
;;; Usage:
;;;   cd src/mcp
;;;   sbcl --load build-maxima-core.lisp

(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf))

(defparameter *windows-host-p*
  (uiop:os-windows-p)
  "True when building on Windows.")

(defun sbcl-program ()
  "Return the current SBCL executable name."
  (or (and (boundp 'sb-ext:*posix-argv*)
           (first sb-ext:*posix-argv*))
      "sbcl"))

(defun getenv-or (name default)
  "Return environment variable NAME or DEFAULT when it is unset."
  (or (uiop:getenv name) default))

(defparameter *mcp-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defparameter *src-dir*
  (truename (merge-pathnames "../" *mcp-dir*)))

(defparameter *root-dir*
  (truename (merge-pathnames "../../" *mcp-dir*)))

(defparameter *core-path*
  (merge-pathnames "binary-sbcl/maxima-base.core" *src-dir*)
  "Output path for the preloaded Maxima SBCL core.")

(format t "~%=== Building Maxima Preloaded Core ===~%~%")
(format t "MCP directory: ~A~%" *mcp-dir*)
(format t "Src directory: ~A~%" *src-dir*)
(format t "Root directory: ~A~%" *root-dir*)
(format t "Core path: ~A~%" *core-path*)

(when *windows-host-p*
  (format t "~%Configuring Maxima source tree for Windows...~%")
  (let ((*default-pathname-defaults* *root-dir*))
    (load (merge-pathnames "configure.lisp" *root-dir*))
    (funcall (find-symbol "CONFIGURE" :cl-user)
             :interactive nil
             :is-win32 t
             :maxima-directory (uiop:native-namestring *root-dir*)
             :sbcl-name (sbcl-program))))

#+sbcl
(let* ((requested-stack-mb (getenv-or "MAXIMA_MCP_CONTROL_STACK_MB" "512"))
       (requested-dyn-mb (getenv-or "MAXIMA_MCP_DYNAMIC_SPACE_MB" "4096"))
       (reexec (member :maxima-mcp-core-reexec *features*)))
  (when (and (not reexec)
             (or (string/= requested-stack-mb "") (string/= requested-dyn-mb "")))
    (let* ((stack-mb (or (parse-integer requested-stack-mb :junk-allowed t) 512))
           (stack-kb (* stack-mb 1024))
           (dyn-mb (or (parse-integer requested-dyn-mb :junk-allowed t) 4096))
           (script (namestring *load-truename*))
           (args (list "--control-stack-size" (princ-to-string stack-kb)
                       "--dynamic-space-size" (princ-to-string dyn-mb)
                       "--noinform"
                       "--non-interactive"
                       "--eval" "(pushnew :maxima-mcp-core-reexec *features*)"
                       "--load" script)))
      (format t "~%Re-executing SBCL with --control-stack-size ~A KB and --dynamic-space-size ~A MB...~%"
              stack-kb dyn-mb)
      (sb-ext:run-program (sbcl-program) args
                          :output t
                          :error t
                          :search t)
      (sb-ext:exit :code 0))))

(format t "~%Loading defsystem...~%")
(load (merge-pathnames "lisp-utils/defsystem.lisp" *root-dir*))

(let ((*default-pathname-defaults* *src-dir*))
  (format t "Loading maxima-build.lisp...~%")
  (load (merge-pathnames "maxima-build.lisp" *src-dir*))
  (format t "Compiling Maxima (if needed)...~%")
  (funcall (find-symbol "MAXIMA-COMPILE" :cl-user))
  (format t "Loading Maxima...~%")
  (funcall (find-symbol "MAXIMA-LOAD" :cl-user)))

(format t "~%Saving preloaded core to ~A...~%" *core-path*)
(ensure-directories-exist *core-path*)

#+sbcl
(sb-ext:save-lisp-and-die
 (namestring *core-path*)
 :toplevel #'cl-user::run
 :purify t)

