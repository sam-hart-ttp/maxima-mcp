;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-misc.lisp - Miscellaneous utility tools
;;;
;;; Covers common Maxima functions used in OU tutorials.

(in-package :maxima-mcp)

(define-mcp-tool "abs"
    (:description "Absolute value of an expression.")
  (("expression" "string" :description "Expression to take absolute value of")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (format nil "abs(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "maxmod"
    (:description "Maximum modulus of a list or matrix (maxmod).")
  (("expression" "string" :description "Expression, e.g. \"[1,-3,2]\" or \"matrix([1],[-3],[2])\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((expr (get-argument arguments "expression"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (let ((call (format nil "maxmod(~A)" expr)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "ident"
    (:description "Identity matrix of size n (ident).")
  (("size" "number" :description "Matrix size n")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((n (get-argument arguments "size"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless n
      (signal-mcp-error +invalid-params+ "Missing required parameter: size"))
    (let ((call (format nil "ident(~A)" n)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "length"
    (:description "Length of a list.")
  (("list" "string" :description "List expression, e.g. \"[1,2,3]\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((lst (get-argument arguments "list"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless lst
      (signal-mcp-error +invalid-params+ "Missing required parameter: list"))
    (let ((call (format nil "length(~A)" lst)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "random"
    (:description "Random integer in [0, n-1].")
  (("limit" "number" :description "Upper bound n")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((n (get-argument arguments "limit"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless n
      (signal-mcp-error +invalid-params+ "Missing required parameter: limit"))
    (let ((call (format nil "random(~A)" n)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "evenp"
    (:description "Test if an integer is even.")
  (("value" "number" :description "Integer to test")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((val (get-argument arguments "value"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless val
      (signal-mcp-error +invalid-params+ "Missing required parameter: value"))
    (let ((call (format nil "evenp(~A)" val)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "concat"
    (:description "Concatenate strings or symbols.")
  (("items" "array" :description "Items to concatenate, e.g. [\"\\\"F\\\"\", \"N\"]")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((items (get-argument arguments "items"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless (and items (listp items))
      (signal-mcp-error +invalid-params+ "Missing required parameter: items"))
    (let ((call (format nil "concat(~{~A~^, ~})" items)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "sconcat"
    (:description "String concatenation (sconcat).")
  (("items" "array" :description "Items to concatenate, e.g. [\"\\\"t=\\\"\", \"t0\"]")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((items (get-argument arguments "items"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless (and items (listp items))
      (signal-mcp-error +invalid-params+ "Missing required parameter: items"))
    (let ((call (format nil "sconcat(~{~A~^, ~})" items)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "cons"
    (:description "Construct a list with cons.")
  (("head" "string" :description "Head element")
   ("tail" "string" :description "Tail list expression")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((head (get-argument arguments "head"))
         (tail (get-argument arguments "tail"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless head
      (signal-mcp-error +invalid-params+ "Missing required parameter: head"))
    (unless tail
      (signal-mcp-error +invalid-params+ "Missing required parameter: tail"))
    (let ((call (format nil "cons(~A, ~A)" head tail)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))

(define-mcp-tool "facts"
    (:description "List current assumptions (facts).")
  (("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (multiple-value-bind (result err) (parse-and-eval "facts()")
      (if err
          (wrap-tool-result nil :is-error t :error-message err)
          (wrap-tool-result result :format format)))))

(define-mcp-tool "kill"
    (:description "Kill variables or properties (alias to kill).")
  (("target" "string" :description "Target to kill, e.g. \"x\" or \"all\"")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let* ((target (get-argument arguments "target"))
         (format-str (get-argument arguments "format"))
         (format (session-get-format session format-str)))
    (unless target
      (signal-mcp-error +invalid-params+ "Missing required parameter: target"))
    (let ((call (format nil "kill(~A)" target)))
      (multiple-value-bind (result err) (parse-and-eval call)
        (if err
            (wrap-tool-result nil :is-error t :error-message err)
            (wrap-tool-result result :format format))))))
