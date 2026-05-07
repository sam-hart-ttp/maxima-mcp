;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; run-sbcl-server.lisp - Quiet SBCL launcher for Maxima MCP
;;;
;;; Starts Maxima MCP directly under SBCL without saving a standalone image.
;;; Intended for environments where the native executable is unreliable.

(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf))

(defparameter *runner-mcp-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defparameter *runner-src-dir*
  (truename (merge-pathnames "../" *runner-mcp-dir*)))

(defparameter *runner-root-dir*
  (truename (merge-pathnames "../../" *runner-mcp-dir*)))

(defparameter *runner-mcp-files*
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

(defparameter *runner-core-path*
  (merge-pathnames "binary-sbcl/maxima-base.core" *runner-src-dir*)
  "Path to the preloaded Maxima SBCL core.")

(defun runner-sbcl-program ()
  "Return the current SBCL executable name."
  (or (and (boundp 'sb-ext:*posix-argv*)
           (first sb-ext:*posix-argv*))
      "sbcl"))

(defun runner-log-path ()
  "Return the optional launcher log file path."
  (uiop:getenv "MAXIMA_MCP_RUNNER_LOG"))

(defun runner-log (format-string &rest args)
  "Append a launcher-level diagnostic line when configured."
  (let ((path (runner-log-path)))
    (when path
      (handler-case
          (with-open-file (stream path
                                  :direction :output
                                  :if-exists :append
                                  :if-does-not-exist :create)
            (write-string (multiple-value-bind (sec min hour day month year)
                              (get-decoded-time)
                            (format nil "[~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D] "
                                    year month day hour min sec))
                          stream)
            (apply #'format stream format-string args)
            (terpri stream))
        (error () nil)))))

(defun ensure-quicklisp ()
  "Load Quicklisp from the user's home directory when it is available."
  (runner-log "ensure-quicklisp")
  (unless (find-package :quicklisp)
    (let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                           (user-homedir-pathname))))
      (if (probe-file quicklisp-init)
          (load quicklisp-init)
          (error "Quicklisp not found at ~A" quicklisp-init)))))

(defun ensure-windows-source-configuration ()
  "Generate Maxima autoconf variables on Windows when absent."
  (when (and (uiop:os-windows-p)
             (not (probe-file (merge-pathnames "autoconf-variables.lisp"
                                               *runner-src-dir*))))
    (runner-log "configuring source tree for Windows")
    (let ((*default-pathname-defaults* *runner-root-dir*))
      (load (merge-pathnames "configure.lisp" *runner-root-dir*))
      (funcall (find-symbol "CONFIGURE" :cl-user)
               :interactive nil
               :is-win32 t
               :maxima-directory (uiop:native-namestring *runner-root-dir*)
               :sbcl-name (runner-sbcl-program)))))

(defun load-maxima-runtime ()
  "Load precompiled Maxima and the MCP sources with stdout suppressed."
  (runner-log "load-maxima-runtime start")
  (let ((*standard-output* (make-broadcast-stream))
        (*error-output* (make-broadcast-stream))
        (*trace-output* (make-broadcast-stream))
        (*compile-verbose* nil)
        (*compile-print* nil)
        (*load-verbose* nil))
    (ensure-quicklisp)
    (ensure-windows-source-configuration)
    (unless (find-package :maxima)
      (runner-log "loading defsystem")
      (load (merge-pathnames "lisp-utils/defsystem.lisp" *runner-root-dir*))
      (runner-log "loading maxima-build")
      (let ((*default-pathname-defaults* *runner-src-dir*))
        (load (merge-pathnames "maxima-build.lisp" *runner-src-dir*))
        (runner-log "calling MAXIMA-LOAD")
        (funcall (find-symbol "MAXIMA-LOAD" :cl-user))))
    (runner-log "quickloading yason")
    (funcall (find-symbol "QUICKLOAD" :ql) :yason :silent t)
    (dolist (file *runner-mcp-files*)
      (runner-log "loading ~A" file)
      (load (merge-pathnames file *runner-mcp-dir*)))))

(defun call-maxima-mcp-main ()
  "Resolve and call MAXIMA-MCP:MAIN after the package has been loaded."
  (let ((main-fn (find-symbol "MAIN" :maxima-mcp)))
    (unless main-fn
      (error "MAXIMA-MCP:MAIN not found"))
    (funcall main-fn)))

(runner-log "runner start")
(handler-case
    (progn
      (load-maxima-runtime)
      (runner-log "calling maxima-mcp:main")
      (call-maxima-mcp-main)
      (runner-log "maxima-mcp:main returned"))
  (error (e)
    (runner-log "runner error ~A" e)
    (error e)))
