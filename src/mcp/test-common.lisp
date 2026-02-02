;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; test-common.lisp - Shared test definitions for Maxima MCP
;;;
;;; Provides test case definitions and a runner function used by both
;;; the library and subprocess backends.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Test Case Definitions
;;; ------------------------------------------------------------------

(defparameter *basic-test-cases*
  '(("evaluate" (("expression" "2+2")) "2+2")
    ("differentiate" (("expression" "x^3") ("variable" "x")) "d/dx(x^3)")
    ("integrate" (("expression" "x^2") ("variable" "x")) "integral(x^2, x)")
    ("solve" (("equation" "x^2-4=0") ("variable" "x")) "solve(x^2-4=0, x)")
    ("factor" (("expression" "x^2-1")) "factor(x^2-1)"))
  "Basic test cases: (tool-name args-alist description)")

(defparameter *calculus-test-cases*
  '(("linsolve" (("equations" "[x+y=1, x-y=1]") ("variables" "[x,y]")) "linsolve")
    ("ode2" (("equation" "'diff(y,x)=y") ("function" "y") ("variable" "x")) "ode2")
    ("desolve" (("equations" "[diff(x(t),t)=x(t), diff(y(t),t)=y(t)]")
                ("functions" "[x(t), y(t)]")) "desolve"))
  "Calculus test cases")

(defparameter *vector-test-cases*
  '(("grad" (("expression" "x*y^2")) "grad")
    ("div" (("vector" "[x,y,z]")) "div"))
  "Vector calculus test cases")

(defparameter *list-test-cases*
  '(("makelist" (("expression" "n^2") ("variable" "n") ("range" "1,5")) "makelist")
    ("subst" (("substitution" "x=2") ("expression" "x^2+y")) "subst")
    ("ev" (("expression" "x^2") ("rules" "x=3")) "ev"))
  "List manipulation test cases")

(defparameter *misc-test-cases*
  '(("abs" (("expression" "-5")) "abs")
    ("ident" (("size" 3)) "ident")
    ("length" (("list" "[1,2,3]")) "length")
    ("evenp" (("value" 4)) "evenp"))
  "Miscellaneous test cases")

(defparameter *extra-test-cases*
  '(("fullratsimp" (("expression" "(2*x+4*x^2)/x")) "fullratsimp")
    ("logcontract" (("expression" "log(a)+log(b)")) "logcontract")
    ("realroots" (("expression" "x^2-2*x+1")) "realroots")
    ("allroots" (("expression" "x^2+1")) "allroots")
    ("rhs" (("equation" "4*x+1=2*x-2")) "rhs")
    ("lhs" (("equation" "4*x+1=2*x-2")) "lhs")
    ("map" (("function" "lambda([x],x^2)") ("list" "[1,2,3]")) "map")
    ("quotient" (("dividend" "x^2") ("divisor" "x-1")) "quotient")
    ("remainder" (("dividend" "x^2") ("divisor" "x-1")) "remainder"))
  "Extra test cases from OU guides/manual")

;;; ------------------------------------------------------------------
;;; Test Runner Helper
;;; ------------------------------------------------------------------

(defun get-result-text (result)
  "Extract the text content from a tool result."
  (let ((content (json-object-get result "content")))
    (when (and content (listp content) (first content))
      (json-object-get (first content) "text"))))

(defun run-single-test (tool-name args description)
  "Run a single test case and return (success result-text error-text)."
  (handler-case
      (let* ((arg-hash (make-hash-table :test #'equal)))
        (dolist (pair args)
          (setf (gethash (first pair) arg-hash) (second pair)))
        (let* ((session (initialize-session (make-mcp-session)))
               (result (invoke-tool tool-name session arg-hash))
               (text (get-result-text result))
               (is-error (json-object-get result "isError")))
          (if is-error
              (values nil nil text)
              (values t text nil))))
    (error (e)
      (values nil nil (format nil "~A" e)))))

(defun run-test-group (group-name test-cases &key (verbose t))
  "Run a group of test cases and report results.
   Returns (passed-count failed-count)."
  (when verbose
    (format t "~%=== ~A ===~%" group-name))
  (let ((passed 0)
        (failed 0))
    (dolist (test test-cases)
      (destructuring-bind (tool-name args description) test
        (multiple-value-bind (success result-text error-text)
            (run-single-test tool-name args description)
          (if success
              (progn
                (incf passed)
                (when verbose
                  (format t "  [PASS] ~A = ~A~%" description
                          (if (> (length result-text) 60)
                              (concatenate 'string (subseq result-text 0 57) "...")
                              result-text))))
              (progn
                (incf failed)
                (when verbose
                  (format t "  [FAIL] ~A: ~A~%" description error-text)))))))
    (values passed failed)))

;;; ------------------------------------------------------------------
;;; Main Test Runner
;;; ------------------------------------------------------------------

(defun run-all-tool-tests (&key (verbose t))
  "Run all tool tests and report summary.
   Returns (total-passed total-failed)."
  (let ((total-passed 0)
        (total-failed 0))
    (flet ((run-group (name cases)
             (multiple-value-bind (passed failed)
                 (run-test-group name cases :verbose verbose)
               (incf total-passed passed)
               (incf total-failed failed))))
      (run-group "Basic Tools" *basic-test-cases*)
      (run-group "Calculus Tools" *calculus-test-cases*)
      (run-group "Vector Tools" *vector-test-cases*)
      (run-group "List Tools" *list-test-cases*)
      (run-group "Misc Tools" *misc-test-cases*)
      (run-group "Extra Tools" *extra-test-cases*))
    (when verbose
      (format t "~%=== Summary ===~%")
      (format t "  Passed: ~A~%" total-passed)
      (format t "  Failed: ~A~%" total-failed)
      (format t "  Total:  ~A~%~%" (+ total-passed total-failed)))
    (values total-passed total-failed)))
