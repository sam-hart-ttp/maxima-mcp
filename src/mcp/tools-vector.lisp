;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-vector.lisp - Vector calculus tools (vect package)
;;;
;;; Provides tools for grad, div, curl, scalefactors, express, potential, etc.

(in-package :maxima-mcp)

(defun ensure-vect-loaded ()
  "Ensure vect package is loaded."
  (multiple-value-bind (result err) (parse-and-eval "load(\"vect\")")
    (declare (ignore result))
    (when err
      (signal-mcp-error +internal-error+ err))))

;;; ------------------------------------------------------------------
;;; scalefactors - Set scale factors for coordinate system
;;; ------------------------------------------------------------------

(define-mcp-tool "scalefactors"
    (:description "Set scale factors for a coordinate system using vect package.")
  (("expression" "string" :description "Arguments to scalefactors, e.g. \"[[x,y],x,y]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (ensure-vect-loaded)
    (let ((call (format nil "scalefactors(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; express - Simplify vector expressions
;;; ------------------------------------------------------------------

(define-mcp-tool "express"
    (:description "Simplify a vector expression using vect package.")
  (("expression" "string" :description "Expression to simplify, e.g. \"grad(f)\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (ensure-vect-loaded)
    (let ((call (format nil "express(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; grad - Gradient
;;; ------------------------------------------------------------------

(define-mcp-tool "grad"
    (:description "Compute the gradient of a scalar field.")
  (("expression" "string" :description "Scalar field, e.g. \"x*y^2\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (ensure-vect-loaded)
    (let ((call (format nil "grad(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; div - Divergence
;;; ------------------------------------------------------------------

(define-mcp-tool "div"
    (:description "Compute the divergence of a vector field.")
  (("vector" "string" :description "Vector field, e.g. \"[x,y,z]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((vec (get-argument arguments "vector"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless vec
      (signal-mcp-error +invalid-params+ "Missing required parameter: vector"))
    (ensure-vect-loaded)
    (let ((call (format nil "div(~A)" vec)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; curl - Curl
;;; ------------------------------------------------------------------

(define-mcp-tool "curl"
    (:description "Compute the curl of a vector field.")
  (("vector" "string" :description "Vector field, e.g. \"[x,y,z]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((vec (get-argument arguments "vector"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless vec
      (signal-mcp-error +invalid-params+ "Missing required parameter: vector"))
    (ensure-vect-loaded)
    (let ((call (format nil "curl(~A)" vec)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; potential - Scalar potential
;;; ------------------------------------------------------------------

(define-mcp-tool "potential"
    (:description "Compute a scalar potential for a vector field.")
  (("vector" "string" :description "Vector field, e.g. \"[2*x, 2*y, 2*z]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((vec (get-argument arguments "vector"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless vec
      (signal-mcp-error +invalid-params+ "Missing required parameter: vector"))
    (ensure-vect-loaded)
    (let ((call (format nil "potential(~A)" vec)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; vectorpotential - Vector potential
;;; ------------------------------------------------------------------

(define-mcp-tool "vectorpotential"
    (:description "Compute a vector potential for a vector field.")
  (("vector" "string" :description "Vector field, e.g. \"[y,z,x]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((vec (get-argument arguments "vector"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless vec
      (signal-mcp-error +invalid-params+ "Missing required parameter: vector"))
    (ensure-vect-loaded)
    (let ((call (format nil "vectorpotential(~A)" vec)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
