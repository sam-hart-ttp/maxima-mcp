;;; -*- Mode: Lisp; Syntax: Common-Lisp; Package: MAXIMA-MCP -*-
;;;
;;; tools-plot.lisp - Plotting tools for Maxima MCP
;;;
;;; Provides runtime plotting capability discovery and plot rendering.

(in-package :maxima-mcp)

(defparameter +base64-chars+
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  "Base64 alphabet for encoding binary data.")

(defun read-file-bytes (path)
  "Read PATH into a vector of (unsigned-byte 8)."
  (with-open-file (stream path :direction :input :element-type '(unsigned-byte 8))
    (let* ((size (file-length stream))
           (data (make-array size :element-type '(unsigned-byte 8))))
      (read-sequence data stream)
      data)))

(defun base64-encode-bytes (bytes)
  "Return base64 encoding of BYTES (vector of unsigned-byte 8)."
  (let ((len (length bytes)))
    (with-output-to-string (out)
      (loop for i from 0 below len by 3
            for b1 = (aref bytes i)
            for b2 = (if (< (1+ i) len) (aref bytes (1+ i)) 0)
            for b3 = (if (< (+ i 2) len) (aref bytes (+ i 2)) 0)
            for triple = (logior (ash b1 16) (ash b2 8) b3)
            for c1 = (char +base64-chars+ (ldb (byte 6 18) triple))
            for c2 = (char +base64-chars+ (ldb (byte 6 12) triple))
            for c3 = (char +base64-chars+ (ldb (byte 6 6) triple))
            for c4 = (char +base64-chars+ (ldb (byte 6 0) triple))
            do (write-char c1 out)
               (write-char c2 out)
               (if (< (1+ i) len) (write-char c3 out) (write-char #\= out))
               (if (< (+ i 2) len) (write-char c4 out) (write-char #\= out))))))

(defun program-exists-p (name)
  "Return true if NAME is found on PATH."
  (handler-case
      (let* ((cmd (list "sh" "-c" (format nil "command -v ~A" name)))
             (out (uiop:run-program cmd :ignore-error-status t :output :string :error-output :string)))
        (and (stringp out)
             (> (length (string-trim '(#\Space #\Tab #\Newline) out)) 0)))
    (error ()
      nil)))

(defun display-available-p ()
  "Return true if a GUI display is available."
  (or (uiop:getenv "DISPLAY")
      (uiop:getenv "WAYLAND_DISPLAY")))

(defun plot-capabilities ()
  "Return plotting capabilities as a JSON object."
  (let* ((gnuplot (program-exists-p "gnuplot"))
         (xmaxima (program-exists-p "xmaxima"))
         (mgnuplot (program-exists-p "mgnuplot"))
         (display (display-available-p))
         (png-supported (and gnuplot t))
         (window-supported (and display (or xmaxima gnuplot mgnuplot)))
         (plot-formats (remove nil
                               (list (and gnuplot (if (uiop:os-windows-p) "gnuplot" "gnuplot_pipes"))
                                     (and gnuplot "gnuplot")
                                     (and xmaxima "xmaxima")
                                     (and mgnuplot "mgnuplot"))))
         (outputs (remove nil (list (and png-supported "png")
                                    (and window-supported "window")))))
    (make-json-object
     "outputs" outputs
     "plotFormats" plot-formats
     "display" (if display "available" "none")
     "gnuplot" (if gnuplot t nil)
     "xmaxima" (if xmaxima t nil)
     "mgnuplot" (if mgnuplot t nil))))

(defun wrap-text-content (text &key (is-error nil))
  "Return a tools/call result object containing text content."
  (if is-error
      (make-json-object
       "isError" t
       "content" (list (make-json-object "type" "text" "text" text)))
      (make-json-object
       "content" (list (make-json-object "type" "text" "text" text)))))

(defun wrap-image-content (base64-data &key (mime-type "image/png"))
  "Return a tools/call result object containing image content."
  (make-json-object
   "content" (list (make-json-object
                    "type" "image"
                    "mimeType" mime-type
                    "data" base64-data))))

(defun build-plot-expression (kind exprs x-range y-range options)
  "Build a Maxima plot expression string."
  (let* ((expr (if (and (listp exprs) (not (stringp exprs)))
                   (format nil "[~{~A~^, ~}]" exprs)
                   exprs))
         (args (remove nil (list expr x-range y-range options))))
    (format nil "~A(~{~A~^, ~})"
            (if (string= kind "3d") "plot3d" "plot2d")
            args)))

(defun make-plot-options (output-mode png-path width height extra-options)
  "Build a comma-separated options string for plot2d/plot3d."
  (let ((opts '()))
    (ecase output-mode
      (:png
       (let ((term (if (and width height)
                       (format nil "png size ~A,~A" width height)
                       "png")))
         (push (format nil "[plot_format, gnuplot]") opts)
         (push (format nil "[gnuplot_term, \"~A\"]" term) opts)
         (push (format nil "[gnuplot_out_file, \"~A\"]" png-path) opts)
         (push "[run_viewer, false]" opts)))
      (:window
       (push "[run_viewer, true]" opts)))
    (cond
      ((and extra-options (listp extra-options))
       (setf opts (append opts extra-options)))
      ((and extra-options (stringp extra-options))
       (push extra-options opts)))
    (when opts
      (format nil "~{~A~^, ~}" (nreverse opts)))))

(defun get-file-size (path)
  "Get file size in bytes, or NIL if file doesn't exist or can't be read."
  (ignore-errors
    (with-open-file (s path :direction :input :element-type '(unsigned-byte 8))
      (file-length s))))

(defun wait-for-nonempty-file (path &key (timeout 2.0) (interval 0.05) (stable-count 2))
  "Wait briefly for PATH to exist, have non-zero size, and be stable.
STABLE-COUNT is the number of consecutive checks with unchanged size
required before considering the file complete. This avoids race conditions
where we read the file while gnuplot is still writing to it."
  (let* ((units internal-time-units-per-second)
         (deadline (+ (get-internal-real-time) (* timeout units)))
         (last-size nil)
         (stable 0))
    (loop
      (let ((size (get-file-size path)))
        (cond
          ;; File doesn't exist or is empty - reset stability counter
          ((or (null size) (zerop size))
           (setf last-size nil
                 stable 0))
          ;; Size changed - reset stability counter with new size
          ((not (eql size last-size))
           (setf last-size size
                 stable 1))
          ;; Size unchanged - increment stability counter
          (t
           (incf stable)
           ;; File is stable (size unchanged for stable-count checks)
           (when (>= stable stable-count)
             (return t)))))
      (when (>= (get-internal-real-time) deadline)
        (return nil))
      (sleep interval))))

(defun choose-window-plot-format ()
  "Pick a plot_format for window output."
  (cond
    ((program-exists-p "xmaxima") "xmaxima")
    ((and (program-exists-p "gnuplot") (not (uiop:os-windows-p))) "gnuplot_pipes")
    ((program-exists-p "gnuplot") "gnuplot")
    (t nil)))

(defun choose-output-mode (requested)
  "Return :png or :window, or nil if unsupported."
  (let* ((caps (plot-capabilities))
         (outputs (gethash "outputs" caps)))
    (cond
      ((or (null requested) (string= requested "auto"))
       (if (and outputs (member "png" outputs :test #'string=)) :png
           (and outputs (member "window" outputs :test #'string=) :window)))
      ((string= requested "png") (and outputs (member "png" outputs :test #'string=) :png))
      ((string= requested "window") (and outputs (member "window" outputs :test #'string=) :window))
      (t nil))))

(defun ensure-draw-loaded ()
  "Ensure draw package is loaded."
  (multiple-value-bind (result err) (parse-and-eval "load(\"draw\")")
    (declare (ignore result))
    (when err
      (signal-mcp-error +internal-error+ err))))

(defun ensure-drawdf-loaded ()
  "Ensure drawdf package is loaded."
  (multiple-value-bind (result err) (parse-and-eval "load(\"drawdf\")")
    (declare (ignore result))
    (when err
      (signal-mcp-error +internal-error+ err))))

(defun make-draw-options (output-mode png-path width height extra-options)
  "Build a comma-separated options string for draw2d/draw3d/drawdf."
  (let ((opts '()))
    (ecase output-mode
      (:png
       (push "terminal = 'png" opts)
       (when png-path
         (push (format nil "file_name = \"~A\"" png-path) opts))
       (when (and width height)
         (push (format nil "dimensions = [~A, ~A]" width height) opts)))
      (:window
       (when (program-exists-p "gnuplot")
         (push "terminal = 'wxt" opts))))
    (cond
      ((and extra-options (listp extra-options))
       (setf opts (append opts extra-options)))
      ((and extra-options (stringp extra-options))
       (push extra-options opts)))
    (when opts
      (format nil "~{~A~^, ~}" (nreverse opts)))))

(defun build-draw-expression (fn-name options objects)
  "Build a draw/draw2d/draw3d/drawdf expression string."
  (let ((args (remove nil (append (when options (list options)) objects))))
    (format nil "~A(~{~A~^, ~})" fn-name args)))

(defun run-plot (session arguments &key kind)
  "Shared implementation for plot/plot2d/plot3d."
  (declare (ignore session))
  (let* ((k (or kind (get-argument arguments "kind") "2d"))
         (expr (get-argument arguments "expression"))
         (exprs (get-argument arguments "expressions"))
         (x-range (get-argument arguments "x_range"))
         (y-range (get-argument arguments "y_range"))
         (options (get-argument arguments "options"))
         (output (get-argument arguments "output"))
         (width (get-argument arguments "width"))
         (height (get-argument arguments "height")))
    (unless (or expr exprs)
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression or expressions"))
    (unless x-range
      (signal-mcp-error +invalid-params+ "Missing required parameter: x_range"))
    (when (string= k "3d")
      (unless y-range
        (signal-mcp-error +invalid-params+ "Missing required parameter for 3d: y_range")))
    (let ((mode (choose-output-mode output)))
      (unless mode
        (return-from run-plot
          (wrap-text-content "Plotting output not supported in this environment." :is-error t)))
      (cond
        ((eq mode :png)
         (unless (program-exists-p "gnuplot")
           (return-from run-plot
             (wrap-text-content "PNG output requires gnuplot, which was not found." :is-error t)))
         (let* ((tmpdir (uiop:temporary-directory))
                (png-path (merge-pathnames (format nil "maxima-mcp-plot-~A.png" (get-universal-time)) tmpdir))
                (opt-str (make-plot-options :png png-path width height options))
                (plot-expr (build-plot-expression k (or exprs expr) x-range y-range opt-str)))
           (multiple-value-bind (result err) (parse-and-eval plot-expr)
             (declare (ignore result))
             (when err
               (return-from run-plot (wrap-text-content err :is-error t))))
           (unwind-protect
               (if (and (uiop:file-exists-p png-path)
                        (> (or (ignore-errors (with-open-file (s png-path :direction :input :element-type '(unsigned-byte 8)) (file-length s))) 0) 0))
                   (let* ((bytes (read-file-bytes png-path))
                          (b64 (base64-encode-bytes bytes)))
                     (wrap-image-content b64 :mime-type "image/png"))
                   (wrap-text-content "Plot output file was not created." :is-error t))
             (ignore-errors (delete-file png-path)))))
        ((eq mode :window)
         (let ((plot-format (choose-window-plot-format)))
           (unless plot-format
             (return-from run-plot
               (wrap-text-content "Window output requires a display backend (xmaxima/gnuplot) but none was found." :is-error t)))
           (let* ((format-opt (format nil "[plot_format, ~A]" plot-format))
                  (opt-list (if (and options (listp options))
                                (append options (list format-opt))
                                (list format-opt)))
                  (opt-str (make-plot-options :window nil nil nil opt-list))
                  (plot-expr (build-plot-expression k (or exprs expr) x-range y-range opt-str)))
             (multiple-value-bind (result err) (parse-and-eval plot-expr)
               (declare (ignore result))
               (if err
                   (wrap-text-content err :is-error t)
                   (wrap-text-content "Plot sent to window backend."))))))))))

;;; ------------------------------------------------------------------
;;; plot_capabilities - Detect plotting support at runtime
;;; ------------------------------------------------------------------

(define-mcp-tool "plot_capabilities"
    (:description "Report plotting backends and outputs available at runtime (png, window) based on installed programs and display availability.")
  ()
  (wrap-text-content
   (with-output-to-string (s)
     (let ((caps (plot-capabilities)))
       (format s "{~%  \"outputs\": ~S,~%  \"plotFormats\": ~S,~%  \"display\": ~S,~%  \"gnuplot\": ~S,~%  \"xmaxima\": ~S,~%  \"mgnuplot\": ~S~%}"
               (gethash "outputs" caps)
               (gethash "plotFormats" caps)
               (gethash "display" caps)
               (gethash "gnuplot" caps)
               (gethash "xmaxima" caps)
               (gethash "mgnuplot" caps))))))

;;; ------------------------------------------------------------------
;;; plot - Render a plot (png or window)
;;; ------------------------------------------------------------------

(define-mcp-tool "plot"
    (:description "Render a 2D or 3D plot. Supports PNG output when gnuplot is available, and window output when a display backend is available.")
  (("kind" "string" :description "Plot kind: 2d or 3d" :required nil)
   ("expression" "string" :description "Maxima expression to plot")
   ("expressions" "array" :description "List of Maxima expressions to plot" :required nil)
   ("x_range" "string" :description "X range, e.g. \"[x,-5,5]\"")
   ("y_range" "string" :description "Y range for 3D or optional Y range for 2D, e.g. \"[y,-5,5]\"" :required nil)
   ("options" "array" :description "List of plot option strings, e.g. [\"[legend,\\\"f\\\"]\"]" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))

  (run-plot session arguments))

;;; ------------------------------------------------------------------
;;; plot2d / plot3d - Explicit 2D/3D wrappers
;;; ------------------------------------------------------------------

(define-mcp-tool "plot2d"
    (:description "Render a 2D plot (wrapper around plot).")
  (("expression" "string" :description "Maxima expression to plot")
   ("expressions" "array" :description "List of Maxima expressions to plot" :required nil)
   ("x_range" "string" :description "X range, e.g. \"[x,-5,5]\"")
   ("options" "array" :description "List of plot option strings" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (setf (gethash "kind" arguments) "2d")
  (run-plot session arguments))

(define-mcp-tool "plot3d"
    (:description "Render a 3D plot (wrapper around plot).")
  (("expression" "string" :description "Maxima expression to plot")
   ("expressions" "array" :description "List of Maxima expressions to plot" :required nil)
   ("x_range" "string" :description "X range, e.g. \"[x,-5,5]\"")
   ("y_range" "string" :description "Y range, e.g. \"[y,-5,5]\"")
   ("options" "array" :description "List of plot option strings" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (setf (gethash "kind" arguments) "3d")
  (run-plot session arguments))

;;; ------------------------------------------------------------------
;;; wxplot2d / wxplot3d - wxMaxima aliases (map to plot2d/plot3d)
;;; ------------------------------------------------------------------

(define-mcp-tool "wxplot2d"
    (:description "wxMaxima-compatible 2D plot alias.")
  (("expression" "string" :description "Maxima expression to plot")
   ("expressions" "array" :description "List of Maxima expressions to plot" :required nil)
   ("x_range" "string" :description "X range, e.g. \"[x,-5,5]\"")
   ("options" "array" :description "List of plot option strings" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (setf (gethash "kind" arguments) "2d")
  (run-plot session arguments))

(define-mcp-tool "wxplot3d"
    (:description "wxMaxima-compatible 3D plot alias.")
  (("expression" "string" :description "Maxima expression to plot")
   ("expressions" "array" :description "List of Maxima expressions to plot" :required nil)
   ("x_range" "string" :description "X range, e.g. \"[x,-5,5]\"")
   ("y_range" "string" :description "Y range, e.g. \"[y,-5,5]\"")
   ("options" "array" :description "List of plot option strings" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (setf (gethash "kind" arguments) "3d")
  (run-plot session arguments))

;;; ------------------------------------------------------------------
;;; draw2d / draw3d - draw package plotting
;;; ------------------------------------------------------------------

(define-mcp-tool "draw2d"
    (:description "Render a 2D draw scene (draw package).")
  (("objects" "array" :description "Draw graphic objects, e.g. [\"explicit(x^2,x,-1,1)\"]")
   ("options" "array" :description "Draw options as strings, e.g. [\"title=\\\"Plot\\\"\"]" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (let* ((objects (get-argument arguments "objects"))
         (options (get-argument arguments "options"))
         (output (get-argument arguments "output"))
         (width (get-argument arguments "width"))
         (height (get-argument arguments "height")))
    (unless (and objects (listp objects))
      (signal-mcp-error +invalid-params+ "Missing required parameter: objects"))
    (ensure-draw-loaded)
    (let ((mode (choose-output-mode output)))
      (cond
        ((not mode)
         (wrap-text-content "Plotting output not supported in this environment." :is-error t))
        ((eq mode :png)
         (if (not (program-exists-p "gnuplot"))
             (wrap-text-content "PNG output requires gnuplot, which was not found." :is-error t)
             (let* ((tmpdir (uiop:temporary-directory))
                    (png-path (merge-pathnames (format nil "maxima-mcp-draw2d-~A.png" (get-universal-time)) tmpdir))
                    (opt-str (make-draw-options :png png-path width height options))
                    (expr (build-draw-expression "draw2d" opt-str objects)))
               (multiple-value-bind (result err) (parse-and-eval expr)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (unwind-protect
                         (if (and (uiop:file-exists-p png-path)
                                  (> (or (ignore-errors (with-open-file (s png-path :direction :input :element-type '(unsigned-byte 8)) (file-length s))) 0) 0))
                             (let* ((bytes (read-file-bytes png-path))
                                    (b64 (base64-encode-bytes bytes)))
                               (wrap-image-content b64 :mime-type "image/png"))
                             (wrap-text-content "Draw output file was not created." :is-error t))
                       (ignore-errors (delete-file png-path))))))))
        ((eq mode :window)
         (if (not (display-available-p))
             (wrap-text-content "Window output requires a display." :is-error t)
             (let* ((opt-str (make-draw-options :window nil nil nil options))
                    (expr (build-draw-expression "draw2d" opt-str objects)))
               (multiple-value-bind (result err) (parse-and-eval expr)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (wrap-text-content "Draw2d sent to window backend."))))))))))

(define-mcp-tool "draw3d"
    (:description "Render a 3D draw scene (draw package).")
  (("objects" "array" :description "Draw graphic objects, e.g. [\"explicit(x^2+y^2,x,-1,1,y,-1,1)\"]")
   ("options" "array" :description "Draw options as strings, e.g. [\"title=\\\"Plot\\\"\"]" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (let* ((objects (get-argument arguments "objects"))
         (options (get-argument arguments "options"))
         (output (get-argument arguments "output"))
         (width (get-argument arguments "width"))
         (height (get-argument arguments "height")))
    (unless (and objects (listp objects))
      (signal-mcp-error +invalid-params+ "Missing required parameter: objects"))
    (ensure-draw-loaded)
    (let ((mode (choose-output-mode output)))
      (cond
        ((not mode)
         (wrap-text-content "Plotting output not supported in this environment." :is-error t))
        ((eq mode :png)
         (if (not (program-exists-p "gnuplot"))
             (wrap-text-content "PNG output requires gnuplot, which was not found." :is-error t)
             (let* ((tmpdir (uiop:temporary-directory))
                    (png-path (merge-pathnames (format nil "maxima-mcp-draw3d-~A.png" (get-universal-time)) tmpdir))
                    (opt-str (make-draw-options :png png-path width height options))
                    (expr (build-draw-expression "draw3d" opt-str objects)))
               (multiple-value-bind (result err) (parse-and-eval expr)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (unwind-protect
                         (if (and (uiop:file-exists-p png-path)
                                  (> (or (ignore-errors (with-open-file (s png-path :direction :input :element-type '(unsigned-byte 8)) (file-length s))) 0) 0))
                             (let* ((bytes (read-file-bytes png-path))
                                    (b64 (base64-encode-bytes bytes)))
                               (wrap-image-content b64 :mime-type "image/png"))
                             (wrap-text-content "Draw output file was not created." :is-error t))
                       (ignore-errors (delete-file png-path))))))))
        ((eq mode :window)
         (if (not (display-available-p))
             (wrap-text-content "Window output requires a display." :is-error t)
             (let* ((opt-str (make-draw-options :window nil nil nil options))
                    (expr (build-draw-expression "draw3d" opt-str objects)))
               (multiple-value-bind (result err) (parse-and-eval expr)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (wrap-text-content "Draw3d sent to window backend."))))))))))

;;; ------------------------------------------------------------------
;;; drawdf - Direction field plotting (drawdf package)
;;; ------------------------------------------------------------------

(define-mcp-tool "drawdf"
    (:description "Render a direction field using drawdf (drawdf package).")
  (("field" "string" :description "Direction field, e.g. \"[y,-x]\" or \"exp(-x)+y\"")
   ("x_range" "string" :description "Optional x range, e.g. \"[x,-5,5]\"" :required nil)
   ("y_range" "string" :description "Optional y range, e.g. \"[y,-5,5]\"" :required nil)
   ("options" "array" :description "Drawdf options/objects as strings" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (let* ((field (get-argument arguments "field"))
         (x-range (get-argument arguments "x_range"))
         (y-range (get-argument arguments "y_range"))
         (options (get-argument arguments "options"))
         (output (get-argument arguments "output"))
         (width (get-argument arguments "width"))
         (height (get-argument arguments "height"))
         (objs (remove nil (list field x-range y-range))))
    (unless field
      (signal-mcp-error +invalid-params+ "Missing required parameter: field"))
    (ensure-drawdf-loaded)
    (let ((mode (choose-output-mode output)))
      (cond
        ((not mode)
         (wrap-text-content "Plotting output not supported in this environment." :is-error t))
        ((eq mode :png)
         (if (not (program-exists-p "gnuplot"))
             (wrap-text-content "PNG output requires gnuplot, which was not found." :is-error t)
             (let* ((tmpdir (uiop:temporary-directory))
                    (png-path (merge-pathnames (format nil "maxima-mcp-drawdf-~A.png" (get-universal-time)) tmpdir))
                    (opt-str (make-draw-options :png png-path width height options))
                    (expr (build-draw-expression "drawdf" opt-str objs)))
               (multiple-value-bind (result err) (parse-and-eval expr)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (unwind-protect
                         (if (and (uiop:file-exists-p png-path)
                                  (> (or (ignore-errors (with-open-file (s png-path :direction :input :element-type '(unsigned-byte 8)) (file-length s))) 0) 0))
                             (let* ((bytes (read-file-bytes png-path))
                                    (b64 (base64-encode-bytes bytes)))
                               (wrap-image-content b64 :mime-type "image/png"))
                             (wrap-text-content "Drawdf output file was not created." :is-error t))
                       (ignore-errors (delete-file png-path))))))))
        ((eq mode :window)
         (if (not (display-available-p))
             (wrap-text-content "Window output requires a display." :is-error t)
             (let* ((opt-str (make-draw-options :window nil nil nil options))
                    (expr (build-draw-expression "drawdf" opt-str objs)))
               (multiple-value-bind (result err) (parse-and-eval expr)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (wrap-text-content "Drawdf sent to window backend."))))))))))

;;; ------------------------------------------------------------------
;;; with_slider_draw - Interactive slider helper (not supported headless)
;;; ------------------------------------------------------------------

(define-mcp-tool "with_slider_draw"
    (:description "Interactive draw slider (wxMaxima). Not supported in headless MCP.")
  (("expression" "string" :description "Full with_slider_draw expression to evaluate")
   ("format" "string" :description "Output format: text, latex, mathml, or lisp" :required nil))
  (let ((expr (get-argument arguments "expression")))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (wrap-text-content "with_slider_draw is interactive and not supported in headless MCP. Use plot/draw tools instead."
                       :is-error t)))

;;; ------------------------------------------------------------------
;;; implicit_plot / wximplicit_plot - Implicit plotting
;;; ------------------------------------------------------------------

(defun ensure-implicit-plot-loaded ()
  "Ensure implicit_plot package is loaded."
  (unless (using-subprocess-p)
    (multiple-value-bind (result err) (parse-and-eval "load(\"implicit_plot\")")
      (declare (ignore result))
      (when err
        (signal-mcp-error +internal-error+ err)))))

(defun run-implicit-plot (arguments)
  "Render an implicit plot to PNG or window."
  (let* ((expr (get-argument arguments "expression"))
         (x-range (get-argument arguments "x_range"))
         (y-range (get-argument arguments "y_range"))
         (options (get-argument arguments "options"))
         (output (get-argument arguments "output"))
         (width (get-argument arguments "width"))
         (height (get-argument arguments "height")))
    (unless expr
      (signal-mcp-error +invalid-params+ "Missing required parameter: expression"))
    (unless x-range
      (signal-mcp-error +invalid-params+ "Missing required parameter: x_range"))
    (unless y-range
      (signal-mcp-error +invalid-params+ "Missing required parameter: y_range"))
    (ensure-implicit-plot-loaded)
    (let ((mode (choose-output-mode output)))
      (cond
        ((not mode)
         (wrap-text-content "Plotting output not supported in this environment." :is-error t))
        ((eq mode :png)
         (if (not (program-exists-p "gnuplot"))
             (wrap-text-content "PNG output requires gnuplot, which was not found." :is-error t)
             (let* ((tmpdir (uiop:temporary-directory))
                    (png-path (merge-pathnames (format nil "maxima-mcp-implicit-~A.png" (get-universal-time)) tmpdir))
                    (opt-str (make-plot-options :png png-path width height options))
                    (base-call (format nil "implicit_plot(~A, ~A, ~A~@[ , ~A~])" expr x-range y-range opt-str))
                    (call (if (using-subprocess-p)
                              (format nil "load(\"implicit_plot\")$ ~A" base-call)
                              base-call)))
               (multiple-value-bind (result err) (parse-and-eval call)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (unwind-protect
                         (if (wait-for-nonempty-file png-path)
                             (let* ((bytes (read-file-bytes png-path))
                                    (b64 (base64-encode-bytes bytes)))
                               (wrap-image-content b64 :mime-type "image/png"))
                             (wrap-text-content "Implicit plot output file was not created." :is-error t))
                       (ignore-errors (delete-file png-path))))))))
        ((eq mode :window)
         (if (not (display-available-p))
             (wrap-text-content "Window output requires a display." :is-error t)
             (let* ((format-opt (format nil "[plot_format, ~A]" (or (choose-window-plot-format) "gnuplot")))
                    (opt-list (if (and options (listp options))
                                  (append options (list format-opt))
                                  (list format-opt)))
                    (opt-str (make-plot-options :window nil nil nil opt-list))
                    (base-call (format nil "implicit_plot(~A, ~A, ~A~@[ , ~A~])" expr x-range y-range opt-str))
                    (call (if (using-subprocess-p)
                              (format nil "load(\"implicit_plot\")$ ~A" base-call)
                              base-call)))
               (multiple-value-bind (result err) (parse-and-eval call)
                 (declare (ignore result))
                 (if err
                     (wrap-text-content err :is-error t)
                     (wrap-text-content "Implicit plot sent to window backend."))))))))))

(define-mcp-tool "implicit_plot"
    (:description "Render an implicit plot (implicit_plot package).")
  (("expression" "string" :description "Implicit equation, e.g. \"x^2+y^2=1\"")
   ("x_range" "string" :description "X range, e.g. \"[x,-2,2]\"")
   ("y_range" "string" :description "Y range, e.g. \"[y,-2,2]\"")
   ("options" "array" :description "Plot option strings" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (run-implicit-plot arguments))

(define-mcp-tool "wximplicit_plot"
    (:description "wxMaxima-compatible implicit plot alias.")
  (("expression" "string" :description "Implicit equation, e.g. \"x^2+y^2=1\"")
   ("x_range" "string" :description "X range, e.g. \"[x,-2,2]\"")
   ("y_range" "string" :description "Y range, e.g. \"[y,-2,2]\"")
   ("options" "array" :description "Plot option strings" :required nil)
   ("output" "string" :description "Output mode: png, window, or auto" :required nil)
   ("width" "number" :description "PNG width in pixels" :required nil)
   ("height" "number" :description "PNG height in pixels" :required nil))
  (run-implicit-plot arguments))
