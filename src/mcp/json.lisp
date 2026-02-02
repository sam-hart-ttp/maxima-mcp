;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; json.lisp - JSON utilities for Maxima MCP
;;;
;;; Provides JSON encoding/decoding functions wrapping the yason library,
;;; with conveniences for MCP protocol handling.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; JSON Encoding
;;; ------------------------------------------------------------------

;; Wrapper struct for raw JSON output (avoids string escaping)
(defstruct (json-raw-value (:constructor make-json-raw-value (string)))
  "Wrapper for raw JSON values that should be output without escaping."
  (string "" :type string :read-only t))

;; Public yason encoder for raw JSON values
(defmethod yason:encode ((raw json-raw-value) &optional stream)
  "Encode a raw JSON value by writing its string directly."
  (write-string (json-raw-value-string raw) stream)
  raw)

;; Encoder for symbols (handles booleans and keywords in hash-tables)
(defmethod yason:encode ((sym symbol) &optional stream)
  "Encode Lisp symbols as JSON values."
  (cond
    ((eq sym t) (write-string "true" stream) sym)
    ((eq sym nil) (write-string "null" stream) sym)
    ((eq sym :null) (write-string "null" stream) sym)
    ((eq sym :false) (write-string "false" stream) sym)
    ((eq sym :true) (write-string "true" stream) sym)
    (t (yason:encode (string-downcase (symbol-name sym)) stream))))

(defun json-raw (value)
  "Return VALUE as raw JSON output (no string escaping).
   VALUE should be a valid JSON literal string like \"true\", \"false\", or \"null\"."
  (make-json-raw-value value))

(defun json-symbol-encoder (symbol)
  "Encode Lisp symbols as JSON values."
  (cond
    ((eq symbol t) (json-raw "true"))
    ((eq symbol nil) (json-raw "null"))
    ((eq symbol :null) (json-raw "null"))
    ((eq symbol :false) (json-raw "false"))
    ((eq symbol :true) (json-raw "true"))
    ((keywordp symbol) (string-downcase (symbol-name symbol)))
    (t (string-downcase (symbol-name symbol)))))

(defun json-encode (object &optional (stream nil))
  "Encode OBJECT as JSON. If STREAM is nil, return a string.
   Otherwise write to STREAM."
  (let ((yason:*symbol-encoder* #'json-symbol-encoder))
    (if stream
        (yason:encode object stream)
        (with-output-to-string (s)
          (yason:encode object s)))))

(defun json-encode-to-string (object)
  "Encode OBJECT as a JSON string."
  (let ((yason:*symbol-encoder* #'json-symbol-encoder))
    (with-output-to-string (s)
      (yason:encode object s))))

;;; ------------------------------------------------------------------
;;; JSON Decoding
;;; ------------------------------------------------------------------

(defun json-decode (string-or-stream)
  "Decode JSON from STRING-OR-STREAM. Returns a hash-table for objects,
   list for arrays, and appropriate Lisp types for primitives."
  (yason:parse string-or-stream
               :object-key-fn #'identity
               :object-as :hash-table
               :json-arrays-as-vectors nil
               :json-booleans-as-symbols nil
               :json-nulls-as-keyword t))

(defun json-decode-string (string)
  "Decode a JSON string."
  (json-decode string))

;;; ------------------------------------------------------------------
;;; Hash Table Utilities
;;; ------------------------------------------------------------------

(defun make-json-object (&rest key-value-pairs)
  "Create a hash-table suitable for JSON encoding.
   KEY-VALUE-PAIRS is a plist of string keys and values.
   Example: (make-json-object \"name\" \"foo\" \"value\" 42)"
  (let ((ht (make-hash-table :test #'equal)))
    (loop for (key value) on key-value-pairs by #'cddr
          do (setf (gethash key ht) value))
    ht))

(defun json-object-get (object key &optional default)
  "Get KEY from JSON OBJECT (hash-table). Returns DEFAULT if not found."
  (gethash key object default))

(defun json-object-set (object key value)
  "Set KEY to VALUE in JSON OBJECT (hash-table)."
  (setf (gethash key object) value))

(defun json-object-keys (object)
  "Return a list of keys in JSON OBJECT."
  (loop for key being the hash-keys of object
        collect key))

(defun json-object-p (object)
  "Return T if OBJECT is a JSON object (hash-table with string keys)."
  (and (hash-table-p object)
       (eq (hash-table-test object) 'equal)))

;;; ------------------------------------------------------------------
;;; JSON Schema Utilities (for tool definitions)
;;; ------------------------------------------------------------------

(defun make-json-schema (&key type properties required description
                              (additional-properties :false))
  "Create a JSON Schema object.
   TYPE is typically \"object\".
   PROPERTIES is an alist of (name . schema-definition).
   REQUIRED is a list of required property names.
   DESCRIPTION is a human-readable description."
  (let ((schema (make-json-object "type" type)))
    (when description
      (json-object-set schema "description" description))
    (when properties
      (let ((props (make-hash-table :test #'equal)))
        (loop for (name . def) in properties
              do (setf (gethash name props) def))
        (json-object-set schema "properties" props)))
    (when required
      (json-object-set schema "required" required))
    (when (eq type "object")
      (json-object-set schema "additionalProperties" additional-properties))
    schema))

(defun make-property-schema (type &key description enum default)
  "Create a JSON Schema for a single property."
  (let ((schema (make-json-object "type" type)))
    (when description
      (json-object-set schema "description" description))
    (when enum
      (json-object-set schema "enum" enum))
    (when default
      (json-object-set schema "default" default))
    schema))
