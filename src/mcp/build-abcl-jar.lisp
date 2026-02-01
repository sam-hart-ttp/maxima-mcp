;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-abcl-jar.lisp - Build ABCL jars + wrapper scripts for Maxima MCP
;;;
;;; Usage:
;;;   cd src/mcp
;;;   abcl --load build-abcl-jar.lisp
;;;
;;; Env:
;;;   MAXIMA_MCP_SUBPROCESS=1  -> package :maxima-mcp/test instead of :maxima-mcp

(in-package :cl-user)

(format t "~%=== Building Maxima MCP (ABCL JAR) ===~%~%")

;;; ------------------------------------------------------------------
;;; Paths
;;; ------------------------------------------------------------------

(defparameter *mcp-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defparameter *root-dir*
  (truename (merge-pathnames "../../" *mcp-dir*)))

(defparameter *lib-jar*
  (merge-pathnames "maxima-mcp-lib.jar" *root-dir*))

(defparameter *launcher-jar*
  (merge-pathnames "maxima-mcp.jar" *root-dir*))

(format t "MCP directory: ~A~%" *mcp-dir*)
(format t "Root directory: ~A~%" *root-dir*)

;;; ------------------------------------------------------------------
;;; Helpers
;;; ------------------------------------------------------------------

(defun getenv (name)
  (or (and (find-package :ext)
           (ignore-errors (funcall (intern "GETENV" :ext) name)))
      (and (find-package :uiop)
           (ignore-errors (funcall (intern "GETENV" :uiop) name)))))

(defun write-file (path content)
  (with-open-file (out path :direction :output :if-exists :supersede)
    (write-string content out)))

;;; ------------------------------------------------------------------
;;; Load ABCL contrib and asdf-jar
;;; ------------------------------------------------------------------

(format t "~%Loading ABCL contrib...~%")
(require :abcl-contrib)
(format t "Loading asdf-jar...~%")
(asdf:make :asdf-jar)

;;; ------------------------------------------------------------------
;;; Decide which system to package
;;; ------------------------------------------------------------------

(defparameter *use-subprocess*
  (string= (or (getenv "MAXIMA_MCP_SUBPROCESS") "") "1"))

(defparameter *system-name*
  (if *use-subprocess* :maxima-mcp/test :maxima-mcp))

(format t "Packaging system: ~A~%" *system-name*)

;;; Try to load Maxima if using the library backend.
(when (and (not *use-subprocess*)
           (not (find-package :maxima)))
  (format t "Loading Maxima (via Quicklisp) if available...~%")
  (let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                         (user-homedir-pathname))))
    (if (not (probe-file quicklisp-init))
        (progn
          (format t "Warning: Quicklisp not found at ~A~%" quicklisp-init)
          (format t "Falling back to subprocess mode.~%")
          (setf *use-subprocess* t)
          (setf *system-name* :maxima-mcp/test))
        (progn
          (load quicklisp-init)
          (handler-case
              (ql:quickload :maxima :silent t)
            (error (e)
              (format t "Warning: Failed to load Maxima via Quicklisp: ~A~%" e)
              (format t "Falling back to subprocess mode.~%")
              (setf *use-subprocess* t)
              (setf *system-name* :maxima-mcp/test)))))))

;;; ------------------------------------------------------------------
;;; Package into jar
;;; ------------------------------------------------------------------

(multiple-value-bind (jar-path mapping)
    (asdf-jar:package *system-name* :out *root-dir* :fasls t :verbose t)
  (declare (ignore mapping))
  (format t "~%Packaged jar: ~A~%" jar-path)
  (when (probe-file jar-path)
    (uiop:copy-file jar-path *lib-jar*)
    (format t "Copied to: ~A~%" *lib-jar*)))

;;; ------------------------------------------------------------------
;;; Create launcher jar with manifest (requires jar tool)
;;; ------------------------------------------------------------------

(let ((jar-tool (uiop:find-program "jar")))
  (if (not jar-tool)
      (format t "~%Warning: 'jar' tool not found; skipping launcher jar.~%")
      (let* ((tmp-dir (uiop:ensure-directory-pathname
                       (merge-pathnames "build-abcl-jar/" (uiop:temporary-directory))))
             (manifest (merge-pathnames "MANIFEST.MF" tmp-dir)))
        (uiop:ensure-all-directories-exist tmp-dir)
        (write-file manifest
                    (format nil "Manifest-Version: 1.0~%Main-Class: org.armedbear.lisp.Main~%Class-Path: abcl.jar maxima-mcp-lib.jar~%"))
        (uiop:run-program (list jar-tool "cfm"
                                (namestring *launcher-jar*)
                                (namestring manifest)
                                "-C" (namestring tmp-dir) ".")
                          :output t :error-output t)
        (format t "~%Launcher jar created: ~A~%" *launcher-jar*))))

;;; ------------------------------------------------------------------
;;; Write wrapper scripts
;;; ------------------------------------------------------------------

;; Always write a library-backed wrapper; write a subprocess wrapper explicitly.
(let* ((wrapper (merge-pathnames "maxima-mcp-abcl" *root-dir*))
       (wrapper-sub (merge-pathnames "maxima-mcp-abcl-subprocess" *root-dir*))
       (common (format nil "java -jar abcl.jar --eval \"(require :abcl-contrib)\" --eval \"(asdf:make :asdf-jar)\" --eval \"(asdf-jar:add-to-asdf \\\"maxima-mcp-lib.jar\\\")\" --eval \"(asdf:load-system :maxima-mcp)\" --eval \"(maxima-mcp:main)\"~%")))
  (write-file wrapper (format nil "#!/bin/sh~%~A" common))
  (write-file wrapper-sub (format nil "#!/bin/sh~%~A"
                                  (format nil "java -jar abcl.jar --eval \"(require :abcl-contrib)\" --eval \"(asdf:make :asdf-jar)\" --eval \"(asdf-jar:add-to-asdf \\\"maxima-mcp-lib.jar\\\")\" --eval \"(asdf:load-system :maxima-mcp/test)\" --eval \"(maxima-mcp:main)\"~%")))
  (ignore-errors (uiop:run-program (list "chmod" "+x" (namestring wrapper)) :output t :error-output t))
  (ignore-errors (uiop:run-program (list "chmod" "+x" (namestring wrapper-sub)) :output t :error-output t))
  (format t "~%Wrote wrappers:~%  ~A~%  ~A~%" wrapper wrapper-sub))

(format t "~%Build complete!~%")
