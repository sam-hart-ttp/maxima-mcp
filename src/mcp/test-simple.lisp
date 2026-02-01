;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: CL-USER -*-
;;;
;;; test-simple.lisp - Simple test of subprocess communication
;;;

(in-package :cl-user)

(format t "~%=== Simple Maxima Subprocess Test ===~%~%")

;; Load Quicklisp
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))

;; Just load yason and the minimal files we need
(ql:quickload :yason :silent t)

;; Load files manually in order
(load "package-subprocess.lisp")
(load "json.lisp")
(load "errors-subprocess.lisp")
(load "maxima-subprocess.lisp")

(in-package :maxima-mcp)

(format t "Starting Maxima subprocess...~%")
(start-maxima-subprocess)

(format t "~%Testing basic evaluation:~%")

(format t "1. 2+2 = ")
(multiple-value-bind (result err) (subprocess-eval "2+2")
  (format t "~A (err: ~A)~%" result err))

(format t "2. diff(x^3,x) = ")
(multiple-value-bind (result err) (subprocess-eval "diff(x^3,x)")
  (format t "~A (err: ~A)~%" result err))

(format t "3. integrate(x^2,x) = ")
(multiple-value-bind (result err) (subprocess-eval "integrate(x^2,x)")
  (format t "~A (err: ~A)~%" result err))

(format t "4. factor(x^2-1) = ")
(multiple-value-bind (result err) (subprocess-eval "factor(x^2-1)")
  (format t "~A (err: ~A)~%" result err))

(format t "5. solve(x^2-4=0,x) = ")
(multiple-value-bind (result err) (subprocess-eval "solve(x^2-4=0,x)")
  (format t "~A (err: ~A)~%" result err))

(format t "~%Stopping subprocess...~%")
(stop-maxima-subprocess)

(format t "~%=== Test Complete ===~%")
