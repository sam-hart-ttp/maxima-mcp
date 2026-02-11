;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; session.lisp - Session state management for Maxima MCP
;;;
;;; Manages MCP session state including user variables, default format,
;;; and other session-specific settings.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Session Structure
;;; ------------------------------------------------------------------

(defstruct (mcp-session (:constructor %make-mcp-session))
  "MCP session state."
  (id (gensym "SESSION-") :type symbol)
  (variables (make-hash-table :test #'eq) :type hash-table)
  (assumption-count 0 :type integer)
  (default-format :text :type keyword)
  (created-at (get-universal-time) :type integer))

(defvar *current-session* nil
  "The current MCP session.")

(defun make-mcp-session (&key (default-format :text))
  "Create a new MCP session."
  (%make-mcp-session :default-format default-format))

;;; ------------------------------------------------------------------
;;; Session Variable Tracking
;;; ------------------------------------------------------------------

(defun session-track-variable (session var-name)
  "Track that VAR-NAME was assigned in SESSION."
  (setf (gethash var-name (mcp-session-variables session)) t))

(defun session-untrack-variable (session var-name)
  "Remove VAR-NAME from tracked variables in SESSION."
  (remhash var-name (mcp-session-variables session)))

(defun session-tracked-variables (session)
  "Return a list of tracked variable names in SESSION."
  (loop for var being the hash-keys of (mcp-session-variables session)
        collect var))

(defun session-variable-tracked-p (session var-name)
  "Return T if VAR-NAME is tracked in SESSION."
  (gethash var-name (mcp-session-variables session)))

;;; ------------------------------------------------------------------
;;; Format Handling
;;; ------------------------------------------------------------------

(defun valid-format-p (format)
  "Return T if FORMAT is a valid output format."
  (member format '(:text :latex :mathml :lisp) :test #'eq))

(defun normalize-format (format-string)
  "Convert a format string (e.g., \"latex\") to a keyword (:latex).
   Returns :text if invalid."
  (let ((kw (intern (string-upcase format-string) :keyword)))
    (if (valid-format-p kw) kw :text)))

(defun session-get-format (session &optional requested-format)
  "Get the format to use for output. If REQUESTED-FORMAT is provided
   and valid, use it; otherwise use the session default."
  (if requested-format
      (let ((kw (normalize-format requested-format)))
        (if (valid-format-p kw) kw (mcp-session-default-format session)))
      (mcp-session-default-format session)))

;;; ------------------------------------------------------------------
;;; Session Initialization
;;; ------------------------------------------------------------------

(defvar *maxima-initialized* nil
  "Whether Maxima has been initialized.")

(defun find-system-maxima-share-paths ()
  "Find and return system Maxima share paths that should be added to file search.
   Returns a list of directory patterns suitable for file_search_maxima."
  (let ((paths nil))
    ;; Check common system Maxima installation paths
    (dolist (base-dir '("/usr/share/maxima/"
                        "/usr/local/share/maxima/"
                        "/opt/maxima/share/"))
      (when (probe-file base-dir)
        (let ((dir (probe-file base-dir)))
          (when dir
            ;; Find version directories
            (dolist (entry (ignore-errors (uiop:subdirectories dir)))
              (let ((share-dir (merge-pathnames "share/" entry)))
                (when (probe-file share-dir)
                  ;; Add pattern for .mac files in share/**
                  (push (format nil "~A**/*.mac"
                                (namestring (truename share-dir)))
                        paths)
                  (push (format nil "~A**/*.lisp"
                                (namestring (truename share-dir)))
                        paths))))))))
    (nreverse paths)))

(defun add-system-share-paths ()
  "Add system Maxima share directories to file search paths."
  (let ((extra-paths (find-system-maxima-share-paths)))
    (when extra-paths
      ;; Add to $file_search_maxima
      (dolist (path extra-paths)
        (when (search ".mac" path)
          (setf maxima::$file_search_maxima
                (append maxima::$file_search_maxima (list path)))))
      ;; Add to $file_search_lisp
      (dolist (path extra-paths)
        (when (search ".lisp" path)
          (setf maxima::$file_search_lisp
                (append maxima::$file_search_lisp (list path))))))))

(defun ensure-maxima-initialized ()
  "Ensure Maxima runtime is initialized."
  (unless *maxima-initialized*
    (handler-case
        (progn
          ;; Initialize Maxima runtime globals
          (maxima::initialize-runtime-globals)
          ;; Add system share paths as fallback
          (add-system-share-paths)
          ;; Set some defaults for non-interactive use
          (setf maxima::$display2d nil)  ; Use 1D display by default
          (setf *maxima-initialized* t))
      (error (e)
        (format *error-output* "Warning: Maxima initialization error: ~A~%" e)
        (setf *maxima-initialized* t)))))

(defun initialize-session (session)
  "Initialize a new session. Ensures Maxima is ready."
  (ensure-maxima-initialized)
  session)

;;; ------------------------------------------------------------------
;;; Session Reset
;;; ------------------------------------------------------------------

(defun reset-session (session)
  "Reset the session state. Clears tracked variables and resets Maxima."
  ;; Clear our tracking
  (clrhash (mcp-session-variables session))
  (setf (mcp-session-assumption-count session) 0)
  ;; Reset Maxima's state
  (with-maxima-error-handling
    (maxima::mfuncall 'maxima::$reset))
  session)

(defun clear-session-variables (session &optional var-names)
  "Clear specific variables or all tracked variables if VAR-NAMES is nil."
  (let ((vars (or var-names (session-tracked-variables session))))
    (dolist (var vars)
      (with-maxima-error-handling
        (maxima::mfuncall 'maxima::$kill var))
      (session-untrack-variable session var))))
