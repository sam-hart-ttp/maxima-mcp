;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-fourier.lisp - Fourier series tools (fourie package)
;;;
;;; Provides tools for fourier, fourexpand, etc.

(in-package :maxima-mcp)

(defun ensure-fourie-loaded ()
  "Ensure fourie package is loaded."
  (multiple-value-bind (result err) (parse-and-eval "load(\"fourie\")")
    (declare (ignore result))
    (when err
      (signal-mcp-error +internal-error+ err))))

;;; ------------------------------------------------------------------
;;; fourier - Fourier coefficients
;;; ------------------------------------------------------------------

(define-mcp-tool "fourier"
    (:description "Compute Fourier coefficients for f(x) on interval [-p, p].")
  (("expression" "string" :description "Function f(x)")
   ("variable" "string" :description "Variable, e.g. \"x\"")
   ("period" "string" :description "Half-period p, e.g. \"%pi\" or \"1\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (var (get-argument arguments "variable"))
         (period (get-argument arguments "period"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless period
      (signal-mcp-error +invalid-params+ "Missing required parameter: period"))
    (ensure-fourie-loaded)
    (let ((call (format nil "fourier(~A, ~A, ~A)" expr var period)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; fourexpand - Expand Fourier series
;;; ------------------------------------------------------------------

(define-mcp-tool "fourexpand"
    (:description "Construct a Fourier series from coefficients.")
  (("coeffs" "string" :description "Coefficient list from fourier")
   ("variable" "string" :description "Variable, e.g. \"x\"")
   ("period" "string" :description "Half-period p")
   ("limit" "string" :description "Number of terms, e.g. \"5\" or \"inf\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((coeffs (get-argument arguments "coeffs"))
         (var (get-argument arguments "variable"))
         (period (get-argument arguments "period"))
         (limit (get-argument arguments "limit"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless coeffs
      (signal-mcp-error +invalid-params+ "Missing required parameter: coeffs"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless period
      (signal-mcp-error +invalid-params+ "Missing required parameter: period"))
    (unless limit
      (signal-mcp-error +invalid-params+ "Missing required parameter: limit"))
    (ensure-fourie-loaded)
    (let ((call (format nil "fourexpand(~A, ~A, ~A, ~A)" coeffs var period limit)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; foursimp - Simplify Fourier terms
;;; ------------------------------------------------------------------

(define-mcp-tool "foursimp"
    (:description "Simplify Fourier series terms.")
  (("expression" "string" :description "Expression or coefficient list to simplify")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (ensure-fourie-loaded)
    (let ((call (format nil "foursimp(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; fourcos - Fourier cosine coefficients
;;; ------------------------------------------------------------------

(define-mcp-tool "fourcos"
    (:description "Compute Fourier cosine coefficients.")
  (("expression" "string" :description "Function f(x)")
   ("variable" "string" :description "Variable, e.g. \"x\"")
   ("period" "string" :description "Half-period p")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (var (get-argument arguments "variable"))
         (period (get-argument arguments "period"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless period
      (signal-mcp-error +invalid-params+ "Missing required parameter: period"))
    (ensure-fourie-loaded)
    (let ((call (format nil "fourcos(~A, ~A, ~A)" expr var period)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; foursin - Fourier sine coefficients
;;; ------------------------------------------------------------------

(define-mcp-tool "foursin"
    (:description "Compute Fourier sine coefficients.")
  (("expression" "string" :description "Function f(x)")
   ("variable" "string" :description "Variable, e.g. \"x\"")
   ("period" "string" :description "Half-period p")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (var (get-argument arguments "variable"))
         (period (get-argument arguments "period"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless period
      (signal-mcp-error +invalid-params+ "Missing required parameter: period"))
    (ensure-fourie-loaded)
    (let ((call (format nil "foursin(~A, ~A, ~A)" expr var period)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

;;; ------------------------------------------------------------------
;;; totalfourier - Full Fourier series
;;; ------------------------------------------------------------------

(define-mcp-tool "totalfourier"
    (:description "Compute the full Fourier series expansion.")
  (("expression" "string" :description "Function f(x)")
   ("variable" "string" :description "Variable, e.g. \"x\"")
   ("period" "string" :description "Half-period p")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (var (get-argument arguments "variable"))
         (period (get-argument arguments "period"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless var
      (signal-mcp-error +invalid-params+ "Missing required parameter: variable"))
    (unless period
      (signal-mcp-error +invalid-params+ "Missing required parameter: period"))
    (ensure-fourie-loaded)
    (let ((call (format nil "totalfourier(~A, ~A, ~A)" expr var period)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
