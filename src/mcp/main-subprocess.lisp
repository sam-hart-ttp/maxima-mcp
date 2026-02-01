;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; main-subprocess.lisp - Entry point for subprocess-based testing
;;;
;;; This version uses the system Maxima via subprocess for testing.

(in-package :maxima-mcp)

;;; ------------------------------------------------------------------
;;; Enable Subprocess Mode
;;; ------------------------------------------------------------------

(setf *use-subprocess* t)

;;; ------------------------------------------------------------------
;;; Main Entry Point
;;; ------------------------------------------------------------------

(defun main (&optional args)
  "Main entry point for the MCP server executable."
  (declare (ignore args))
  (setf *use-subprocess* t)
  (run-mcp-server :input *standard-input*
                  :output *standard-output*
                  :debug nil))

;;; ------------------------------------------------------------------
;;; Interactive Usage
;;; ------------------------------------------------------------------

(defun start-server (&key (debug nil))
  "Start the MCP server interactively."
  (setf *use-subprocess* t)
  (format *error-output* "Starting Maxima MCP server (subprocess mode)...~%")
  (format *error-output* "Send JSON-RPC requests on stdin.~%")
  (format *error-output* "Press Ctrl+D to exit.~%~%")
  (run-mcp-server :input *standard-input*
                  :output *standard-output*
                  :debug debug))

;;; ------------------------------------------------------------------
;;; Quick Test Functions
;;; ------------------------------------------------------------------

(defun quick-test ()
  "Run a quick test of the MCP server functionality."
  (format t "Testing Maxima MCP server (subprocess mode)...~%~%")

  (setf *use-subprocess* t)
  (start-maxima-subprocess)

  (let ((session (make-mcp-session)))
    (initialize-session session)

    ;; Test evaluate
    (format t "1. Testing evaluate tool...~%")
    (let ((result (test-tool "evaluate" "expression" "2+2")))
      (format t "   2+2 = ~A~%~%" (json-object-get
                                   (first (json-object-get result "content"))
                                   "text")))

    ;; Test differentiate
    (format t "2. Testing differentiate tool...~%")
    (let ((result (test-tool "differentiate" "expression" "x^3" "variable" "x")))
      (format t "   d/dx(x^3) = ~A~%~%" (json-object-get
                                          (first (json-object-get result "content"))
                                          "text")))

    ;; Test integrate
    (format t "3. Testing integrate tool...~%")
    (let ((result (test-tool "integrate" "expression" "x^2" "variable" "x")))
      (format t "   integral(x^2, x) = ~A~%~%" (json-object-get
                                                 (first (json-object-get result "content"))
                                                 "text")))

    ;; Test solve
    (format t "4. Testing solve tool...~%")
    (let ((result (test-tool "solve" "equation" "x^2-4=0" "variable" "x")))
      (format t "   solve(x^2-4=0, x) = ~A~%~%" (json-object-get
                                                  (first (json-object-get result "content"))
                                                  "text")))

    ;; Test factor
    (format t "5. Testing factor tool...~%")
    (let ((result (test-tool "factor" "expression" "x^2-1")))
      (format t "   factor(x^2-1) = ~A~%~%" (json-object-get
                                              (first (json-object-get result "content"))
                                              "text")))

    ;; Test limit
    (format t "6. Testing limit tool...~%")
    (let ((result (test-tool "limit" "expression" "sin(x)/x" "variable" "x" "point" "0")))
      (format t "   limit(sin(x)/x, x, 0) = ~A~%~%" (json-object-get
                                                     (first (json-object-get result "content"))
                                                     "text")))

    ;; Test linsolve
    (format t "7. Testing linsolve tool...~%")
    (let ((result (test-tool "linsolve"
                             "equations" "[x+y=1, x-y=1]"
                             "variables" "[x,y]")))
      (format t "   linsolve = ~A~%~%" (json-object-get
                                         (first (json-object-get result "content"))
                                         "text")))

    ;; Test ode2 + ic1
    (format t "8. Testing ode2/ic1 tools...~%")
    (let* ((sol (test-tool "ode2" "equation" "'diff(y,x)=y" "function" "y" "variable" "x"))
           (sol-text (json-object-get (first (json-object-get sol "content")) "text"))
           (ic (test-tool "ic1" "solution" "ode2('diff(y,x)=y,y,x)" "xval" "x=0" "yval" "y=1")))
      (format t "   ode2 = ~A~%~%" sol-text)
      (format t "   ic1  = ~A~%~%" (json-object-get
                                     (first (json-object-get ic "content"))
                                     "text")))

    ;; Test desolve
    (format t "9. Testing desolve tool...~%")
    (let ((result (test-tool "desolve"
                             "equations" "[diff(x(t),t)=x(t), diff(y(t),t)=y(t)]"
                             "functions" "[x(t), y(t)]")))
      (format t "   desolve = ~A~%~%" (json-object-get
                                        (first (json-object-get result "content"))
                                        "text")))

    ;; Test Fourier tools
    (format t "10. Testing fourier tools...~%")
    (let* ((coeff (test-tool "fourier" "expression" "t" "variable" "t" "period" "%pi"))
           (coeff-text (json-object-get (first (json-object-get coeff "content")) "text"))
           (series (test-tool "fourexpand" "coeffs" coeff-text "variable" "t" "period" "%pi" "limit" "5")))
      (format t "   fourier = ~A~%~%" coeff-text)
      (format t "   fourexpand = ~A~%~%" (json-object-get
                                           (first (json-object-get series "content"))
                                           "text")))

    ;; Test vector calculus tools
    (format t "11. Testing vector tools...~%")
    (let* ((grad (test-tool "grad" "expression" "x*y^2"))
           (div (test-tool "div" "vector" "[x,y,z]")))
      (format t "   grad = ~A~%~%" (json-object-get
                                     (first (json-object-get grad "content"))
                                     "text"))
      (format t "   div  = ~A~%~%" (json-object-get
                                     (first (json-object-get div "content"))
                                     "text")))

    ;; Test list/subst tools
    (format t "12. Testing list/subst tools...~%")
    (let* ((ml (test-tool "makelist" "expression" "n^2" "variable" "n" "range" "1,5"))
           (sb (test-tool "subst" "substitution" "x=2" "expression" "x^2+y"))
           (ev (test-tool "ev" "expression" "x^2" "rules" "x=3"))
           (ap (test-tool "append" "lists" '("[1,2]" "[3,4]"))))
      (format t "   makelist = ~A~%~%" (json-object-get
                                         (first (json-object-get ml "content"))
                                         "text"))
      (format t "   subst    = ~A~%~%" (json-object-get
                                         (first (json-object-get sb "content"))
                                         "text"))
      (format t "   ev       = ~A~%~%" (json-object-get
                                         (first (json-object-get ev "content"))
                                         "text"))
      (format t "   append   = ~A~%~%" (json-object-get
                                         (first (json-object-get ap "content"))
                                         "text")))

    ;; Test misc tools
    (format t "13. Testing misc tools...~%")
    (let* ((ab (test-tool "abs" "expression" "-5"))
           (mm (test-tool "maxmod" "expression" "[1,-3,2]"))
           (id (test-tool "ident" "size" 3))
           (ln (test-tool "length" "list" "[1,2,3]"))
           (rd (test-tool "random" "limit" 10))
           (ep (test-tool "evenp" "value" 4))
           (cc (test-tool "concat" "items" '("\"F\"" "3")))
           (sc (test-tool "sconcat" "items" '("\"t=\"" "3")))
           (cs (test-tool "cons" "head" "1" "tail" "[2,3]"))
           (fa (test-tool "facts"))
           (kl (test-tool "kill" "target" "x")))
      (format t "   abs     = ~A~%~%" (json-object-get
                                       (first (json-object-get ab "content"))
                                       "text"))
      (format t "   maxmod  = ~A~%~%" (json-object-get
                                       (first (json-object-get mm "content"))
                                       "text"))
      (format t "   ident   = ~A~%~%" (json-object-get
                                       (first (json-object-get id "content"))
                                       "text"))
      (format t "   length  = ~A~%~%" (json-object-get
                                       (first (json-object-get ln "content"))
                                       "text"))
      (format t "   random  = ~A~%~%" (json-object-get
                                       (first (json-object-get rd "content"))
                                       "text"))
      (format t "   evenp   = ~A~%~%" (json-object-get
                                       (first (json-object-get ep "content"))
                                       "text"))
      (format t "   concat  = ~A~%~%" (json-object-get
                                       (first (json-object-get cc "content"))
                                       "text"))
      (format t "   sconcat = ~A~%~%" (json-object-get
                                       (first (json-object-get sc "content"))
                                       "text"))
      (format t "   cons    = ~A~%~%" (json-object-get
                                       (first (json-object-get cs "content"))
                                       "text"))
      (format t "   facts   = ~A~%~%" (json-object-get
                                       (first (json-object-get fa "content"))
                                       "text"))
      (format t "   kill    = ~A~%~%" (json-object-get
                                       (first (json-object-get kl "content"))
                                       "text")))

    ;; Test plot capabilities and plot2d (best effort)
    (format t "14. Testing plot capabilities...~%")
    (let ((caps (test-tool "plot_capabilities")))
      (format t "   plot_capabilities = ~A~%~%" (json-object-get
                                                   (first (json-object-get caps "content"))
                                                   "text")))
    (format t "15. Testing plot2d (best effort)...~%")
    (let ((plot (test-tool "plot2d"
                           "expression" "sin(x)"
                           "x_range" "[x,-2,2]"
                           "output" "png")))
      (if (json-object-get plot "isError")
          (format t "   plot2d error: ~A~%~%" (json-object-get
                                              (first (json-object-get plot "content"))
                                              "text"))
          (format t "   plot2d: image bytes returned~%~%")))

    (format t "15b. Testing implicit_plot (best effort)...~%")
    (let ((impl (test-tool "implicit_plot"
                           "expression" "x^2+y^2=1"
                           "x_range" "[x,-2,2]"
                           "y_range" "[y,-2,2]"
                           "output" "png")))
      (if (json-object-get impl "isError")
          (format t "   implicit_plot error: ~A~%~%" (json-object-get
                                                     (first (json-object-get impl "content"))
                                                     "text"))
          (format t "   implicit_plot: image bytes returned~%~%")))

    ;; Test extra tools (OU guides/manual)
    (format t "16. Testing extra tools...~%")
    (let* ((fr (test-tool "fullratsimp" "expression" "(2*x+4*x^2)/x"))
           (lc-log (test-tool "logcontract" "expression" "log(a)+log(b)"))
           (tr (test-tool "trigrat" "expression" "tan(x)/sin(2*x)"))
           (rr (test-tool "realroots" "expression" "x^2-2*x+1"))
           (ar (test-tool "allroots" "expression" "x^2+1"))
           (rh (test-tool "rhs" "equation" "4*x+1=2*x-2"))
           (lh (test-tool "lhs" "equation" "4*x+1=2*x-2"))
           (mp (test-tool "map" "function" "lambda([x],x^2)" "list" "[1,2,3]"))
           (qt (test-tool "quotient" "dividend" "x^2" "divisor" "x-1"))
           (rm (test-tool "remainder" "dividend" "x^2" "divisor" "x-1"))
           (gx (test-tool "gcdex" "a" "108" "b" "93"))
           (qq (test-tool "quad_qags" "expression" "exp(-x^2)" "variable" "x" "lower" "0" "upper" "1"))
           (rk (test-tool "rk" "expression" "y-(x-2)^2" "dependent" "y" "initial" "1.9" "range" "[x,0,1,0.5]"))
           (sr (test-tool "solve_rec" "equation" "u[n]=2*u[n-1]+3" "term" "u[n]" "initials" "u[1]=5"))
           (sp (test-tool "set_plot_option" "option" "[gnuplot_preamble,\"set size ratio -1\"]"))
           (dp (test-tool "depends" "targets" "y" "variables" "x"))
           (deps (test-tool "dependencies"))
           (rdep (test-tool "remove_dependency" "symbol" "y"))
           (decl (test-tool "declare" "variable" "k" "property" "constant"))
           (pv (test-tool "propvars" "property" "constant"))
           (gr (test-tool "gradef" "function" "tan(x)" "derivatives" (list "1+tan(x)^2")))
           (dt (test-tool "differentiate" "expression" "tan(x)" "variable" "x")))
      (format t "   fullratsimp = ~A~%~%" (json-object-get (first (json-object-get fr "content")) "text"))
      (format t "   logcontract = ~A~%~%" (json-object-get (first (json-object-get lc-log "content")) "text"))
      (format t "   trigrat     = ~A~%~%" (json-object-get (first (json-object-get tr "content")) "text"))
      (format t "   realroots   = ~A~%~%" (json-object-get (first (json-object-get rr "content")) "text"))
      (format t "   allroots    = ~A~%~%" (json-object-get (first (json-object-get ar "content")) "text"))
      (format t "   rhs         = ~A~%~%" (json-object-get (first (json-object-get rh "content")) "text"))
      (format t "   lhs         = ~A~%~%" (json-object-get (first (json-object-get lh "content")) "text"))
      (format t "   map         = ~A~%~%" (json-object-get (first (json-object-get mp "content")) "text"))
      (format t "   quotient    = ~A~%~%" (json-object-get (first (json-object-get qt "content")) "text"))
      (format t "   remainder   = ~A~%~%" (json-object-get (first (json-object-get rm "content")) "text"))
      (format t "   gcdex       = ~A~%~%" (json-object-get (first (json-object-get gx "content")) "text"))
      (format t "   quad_qags   = ~A~%~%" (json-object-get (first (json-object-get qq "content")) "text"))
      (format t "   rk          = ~A~%~%" (json-object-get (first (json-object-get rk "content")) "text"))
      (format t "   solve_rec   = ~A~%~%" (json-object-get (first (json-object-get sr "content")) "text"))
      (format t "   set_plot_option = ~A~%~%" (json-object-get (first (json-object-get sp "content")) "text"))
      (format t "   depends     = ~A~%~%" (json-object-get (first (json-object-get dp "content")) "text"))
      (format t "   dependencies = ~A~%~%" (json-object-get (first (json-object-get deps "content")) "text"))
      (format t "   remove_dependency = ~A~%~%" (json-object-get (first (json-object-get rdep "content")) "text"))
      (format t "   declare     = ~A~%~%" (json-object-get (first (json-object-get decl "content")) "text"))
      (format t "   propvars    = ~A~%~%" (json-object-get (first (json-object-get pv "content")) "text"))
      (format t "   gradef      = ~A~%~%" (json-object-get (first (json-object-get gr "content")) "text"))
      (format t "   gradef diff = ~A~%~%" (json-object-get (first (json-object-get dt "content")) "text")))

    (format t "All tests completed!~%")
    (stop-maxima-subprocess)))

(defun test-protocol ()
  "Test the JSON-RPC protocol handling."
  (format t "Testing MCP protocol (subprocess mode)...~%~%")

  (setf *use-subprocess* t)
  (start-maxima-subprocess)

  (let ((session (make-mcp-session)))
    (initialize-session session)

    ;; Test initialize
    (format t "1. Testing initialize...~%")
    (let ((response (process-single-request
                     "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}"
                     session)))
      (format t "   Response: ~A~%~%" (subseq response 0 (min 100 (length response)))))

    ;; Test tools/list
    (format t "2. Testing tools/list...~%")
    (let ((response (process-single-request
                     "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\",\"params\":{}}"
                     session)))
      (format t "   Found ~A tools~%~%"
              (length (json-object-get
                       (json-object-get (json-decode response) "result")
                       "tools"))))

    ;; Test tools/call
    (format t "3. Testing tools/call (evaluate)...~%")
    (let ((response (process-single-request
                     "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"evaluate\",\"arguments\":{\"expression\":\"diff(x^2,x)\"}}}"
                     session)))
      (format t "   Response: ~A~%~%" response))

    (format t "Protocol tests completed!~%")
    (stop-maxima-subprocess)))
