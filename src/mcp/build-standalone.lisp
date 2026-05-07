;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; build-standalone.lisp - Build standalone Maxima MCP executable
;;;
;;; Usage:
;;;   cd /path/to/maxima-mcp/src/mcp
;;;   sbcl --load build-standalone.lisp

(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf))

(defparameter *windows-host-p*
  (uiop:os-windows-p)
  "True when building on Windows.")

(defun getenv-or (name default)
  "Return environment variable NAME or DEFAULT when it is unset."
  (or (uiop:getenv name) default))

(defun sbcl-program ()
  "Return the current SBCL executable name."
  (or (and (boundp 'sb-ext:*posix-argv*)
           (first sb-ext:*posix-argv*))
      "sbcl"))

(defun executable-name (basename)
  "Return BASENAME with a Windows executable extension when needed."
  (if *windows-host-p*
      (format nil "~A.exe" basename)
      basename))

(defun trim-text (string)
  "Trim common surrounding whitespace from STRING."
  (string-trim '(#\Space #\Tab #\Newline #\Return) string))

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
;;; Windows Source-Tree Configuration
;;; ------------------------------------------------------------------

(when *windows-host-p*
  (format t "~%Configuring Maxima source tree for Windows...~%")
  (let ((*default-pathname-defaults* *root-dir*))
    (load (merge-pathnames "configure.lisp" *root-dir*))
    (funcall (find-symbol "CONFIGURE" :cl-user)
             :interactive nil
             :is-win32 t
             :maxima-directory (uiop:native-namestring *root-dir*)
             :sbcl-name (sbcl-program))))

;;; ------------------------------------------------------------------
;;; Optional: Use Prebuilt Core (opt-in)
;;; ------------------------------------------------------------------

(defparameter *maxima-core-path*
  (merge-pathnames "binary-sbcl/maxima-base.core" *src-dir*)
  "Path to a prebuilt Maxima core, if available.")

#+sbcl
(when (and (probe-file *maxima-core-path*)
           (string= (getenv-or "MAXIMA_MCP_USE_CORE" "") "1"))
  (format t "~%Found Maxima core at ~A~%" *maxima-core-path*)
  (format t "Using build-with-core.lisp (MAXIMA_MCP_USE_CORE=1).~%")
  (let* ((sbcl (sbcl-program))
         (build-script (merge-pathnames "build-with-core.lisp" *mcp-dir*))
         (output-path (merge-pathnames (executable-name "maxima-mcp") *root-dir*))
         (args (list "--core" (namestring *maxima-core-path*)
                     "--noinform"
                     "--eval" (format nil "(load ~S)" (namestring build-script))
                     "--eval" (format nil "(build-maxima-mcp ~S)" (namestring output-path))
                     "--quit")))
    (sb-ext:run-program sbcl args
                        :output t
                        :error t
                        :search t
                        :directory (namestring *mcp-dir*))
    (format t "~%Build completed using prebuilt core.~%")
    (sb-ext:exit :code 0)))

;;; ------------------------------------------------------------------
;;; Re-exec with Larger Control Stack (to avoid stack exhaustion)
;;; ------------------------------------------------------------------

#+sbcl
(let* ((requested-stack-mb (getenv-or "MAXIMA_MCP_CONTROL_STACK_MB" "512"))
       (requested-dyn-mb (getenv-or "MAXIMA_MCP_DYNAMIC_SPACE_MB" "4096"))
       (reexec (member :maxima-mcp-reexec *features*)))
  (when (and (not reexec)
             (or (string/= requested-stack-mb "") (string/= requested-dyn-mb "")))
    (let* ((stack-mb (or (parse-integer requested-stack-mb :junk-allowed t) 512))
           (stack-kb (* stack-mb 1024))
           (dyn-mb (or (parse-integer requested-dyn-mb :junk-allowed t) 4096)))
      (format t "~%Re-executing SBCL with --control-stack-size ~A KB and --dynamic-space-size ~A MB...~%"
              stack-kb dyn-mb)
      (let* ((sbcl (sbcl-program))
             (script (namestring *load-truename*))
             (args (list "--control-stack-size" (princ-to-string stack-kb)
                         "--dynamic-space-size" (princ-to-string dyn-mb)
                         "--noinform"
                         "--non-interactive"
                         "--eval" "(pushnew :maxima-mcp-reexec *features*)"
                         "--load" script)))
        (sb-ext:run-program sbcl args
                            :output t
                            :error t
                            :search t)
        (sb-ext:exit :code 0)))))

;;; ------------------------------------------------------------------
;;; Core Files
;;; ------------------------------------------------------------------

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
  #+sbcl
  (let* ((binary-dir (merge-pathnames "binary-sbcl/" *src-dir*))
         (version-file (merge-pathnames ".sbcl-version" binary-dir))
         (current-version (lisp-implementation-version))
         (cached-version (when (probe-file version-file)
                           (with-open-file (in version-file :direction :input)
                             (trim-text (read-line in nil ""))))))
    (when (and (probe-file binary-dir)
               (not (and cached-version (string= cached-version current-version))))
      (format t "Clearing existing SBCL build cache at ~A...~%" binary-dir)
      (uiop:delete-directory-tree binary-dir :validate t :if-does-not-exist :ignore))
    (ensure-directories-exist binary-dir)
    (with-open-file (out version-file :direction :output :if-exists :supersede :if-does-not-exist :create)
      (write-string current-version out)))
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
  (let ((filepath (merge-pathnames file *mcp-dir*)))
    (format t "  Loading ~A...~%" file)
    (load filepath)))

;;; ------------------------------------------------------------------
;;; Save Executable
;;; ------------------------------------------------------------------

(let ((output-path (merge-pathnames (executable-name "maxima-mcp") *root-dir*)))
  (format t "~%Saving executable to ~A...~%" output-path)
  (sb-ext:save-lisp-and-die
   (namestring output-path)
   :toplevel #'maxima-mcp:main
   :executable t
   :save-runtime-options t))
