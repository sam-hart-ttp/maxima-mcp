;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; session-subprocess.lisp - Session management for subprocess-based testing
;;;
;;; Standalone session management that doesn't depend on Maxima library.

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

(defvar *current-session* nil)

(defun make-mcp-session (&key (default-format :text))
  (%make-mcp-session :default-format default-format))

;;; ------------------------------------------------------------------
;;; Session Variable Tracking
;;; ------------------------------------------------------------------

(defun session-track-variable (session var-name)
  (setf (gethash var-name (mcp-session-variables session)) t))

(defun session-untrack-variable (session var-name)
  (remhash var-name (mcp-session-variables session)))

(defun session-tracked-variables (session)
  (loop for var being the hash-keys of (mcp-session-variables session)
        collect var))

(defun session-variable-tracked-p (session var-name)
  (gethash var-name (mcp-session-variables session)))

;;; ------------------------------------------------------------------
;;; Format Handling
;;; ------------------------------------------------------------------

(defun valid-format-p (format)
  (member format '(:text :latex :mathml :lisp) :test #'eq))

(defun normalize-format (format-string)
  (let ((kw (intern (string-upcase format-string) :keyword)))
    (if (valid-format-p kw) kw :text)))

(defun session-get-format (session &optional requested-format)
  (if requested-format
      (let ((kw (normalize-format requested-format)))
        (if (valid-format-p kw) kw (mcp-session-default-format session)))
      (mcp-session-default-format session)))

;;; ------------------------------------------------------------------
;;; Session Initialization (Subprocess version)
;;; ------------------------------------------------------------------

(defvar *maxima-initialized* nil)

(defun ensure-maxima-initialized ()
  "Ensure Maxima subprocess is ready."
  (unless *maxima-initialized*
    (start-maxima-subprocess)
    (setf *maxima-initialized* t)))

(defun initialize-session (session)
  (ensure-maxima-initialized)
  session)

;;; ------------------------------------------------------------------
;;; Session Reset
;;; ------------------------------------------------------------------

(defun reset-session (session)
  (clrhash (mcp-session-variables session))
  (setf (mcp-session-assumption-count session) 0)
  ;; Reset Maxima via subprocess
  (subprocess-eval "reset()")
  session)

(defun clear-session-variables (session &optional var-names)
  (let ((vars (or var-names (session-tracked-variables session))))
    (dolist (var vars)
      (subprocess-eval (format nil "kill(~A)" var))
      (session-untrack-variable session var))))
