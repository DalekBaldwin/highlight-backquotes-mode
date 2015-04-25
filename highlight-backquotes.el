;;; highlight-backquotes.el --- Highlight nested parens, brackets, braces a different color at each depth.

;; Author: Kyle Littler
;; Github: https://github.com/DalekBaldwin/highlight-backquotes-mode - improvements welcome!
;; Created with generous reuse of code from rainbow-delimiters.el



;; License info for rainbow-delimiters.el:

;; Copyright (C) 2010-2012 Jeremy L. Rayman.
;; Author: Jeremy L. Rayman <jeremy.rayman@gmail.com>
;; Maintainer: Jeremy L. Rayman <jeremy.rayman@gmail.com>
;; Created: 2010-09-02
;; Version: 1.3.4
;; Keywords: faces, convenience, lisp, matching, tools, rainbow, rainbow parentheses, rainbow parens
;; EmacsWiki: http://www.emacswiki.org/emacs/RainbowDelimiters
;; Github: http://github.com/jlr/rainbow-delimiters
;; URL: http://github.com/jlr/rainbow-delimiters/raw/master/rainbow-delimiters.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; Rainbow-delimiters is a “rainbow parentheses”-like mode which highlights
;; parentheses, brackets, and braces according to their depth. Each
;; successive level is highlighted in a different color. This makes it easy
;; to spot matching delimiters, orient yourself in the code, and tell which
;; statements are at a given level.
;;
;; Great care has been taken to make this mode FAST. You shouldn't see
;; any discernible change in scrolling or editing speed while using it,
;; even in delimiter-rich languages like Clojure, Lisp, and Scheme.
;;
;; Default colors are subtle, with the philosophy that syntax highlighting
;; shouldn't be visually intrusive. Color schemes are always a matter of
;; taste.  If you take the time to design a new color scheme, please share
;; (even a simple list of colors works) on the EmacsWiki page or via github.
;; EmacsWiki: http://www.emacswiki.org/emacs/RainbowDelimiters
;; Github: http://github.com/jlr/rainbow-delimiters


;;; Installation:

;; 1. Place rainbow-delimiters.el on your emacs load-path.
;;
;; 2. Compile the file (necessary for speed):
;; M-x byte-compile-file <location of rainbow-delimiters.el>
;;
;; 3. Add the following to your dot-emacs/init file:
;; (require 'rainbow-delimiters)
;;
;; 4. Activate the mode in your init file.
;;    You can choose to enable it only in certain modes, or Emacs-wide:
;;
;; - To enable it only in certain modes, add lines like the following:
;; (add-hook 'clojure-mode-hook 'rainbow-delimiters-mode)
;;
;; - To enable it in all programming-related emacs modes (Emacs 24+):
;; (add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
;;
;; - To activate the mode globally, add to your init file:
;; (global-rainbow-delimiters-mode)
;;
;; - To temporarily activate rainbow-delimiters mode in an open buffer:
;; M-x rainbow-delimiters-mode
;;
;; - To toggle global-rainbow-delimiters-mode:
;; M-x global-rainbow-delimiters-mode

;;; Customization:

;; To customize various options, including the color scheme:
;; M-x customize-group rainbow-delimiters
;;
;; deftheme / color-theme.el users:
;; You can specify custom colors by adding the appropriate faces to your theme.
;; - Faces take the form of:
;;   'rainbow-delimiters-depth-#-face' with # being the depth.
;;   Depth begins at 1, the outermost color.
;;   Faces exist for depths 1-9.
;; - The unmatched delimiter face (normally colored red) is:
;;   'rainbow-delimiters-unmatched-face'


;;; Code:

(eval-when-compile (require 'cl))


;; Note: some of the functions in this file have been inlined for speed.
;; Inlining functions can cause problems with debugging. To debug these
;; functions more easily, change defsubst -> defun.
;; http://www.gnu.org/s/emacs/manual/html_node/elisp/Compilation-Tips.html

;;; Customize interface:

(defgroup highlight-backquotes nil
  "Highlight nested parentheses, brackets, and braces according to their depth."
  :prefix "highlight-backquotes-"
  :link '(url-link :tag "Website for rainbow-delimiters (EmacsWiki)"
                   "http://www.emacswiki.org/emacs/RainbowDelimiters")
  :group 'applications)

(defgroup highlight-backquotes-faces nil
  "Faces for quotation levels.

When depth exceeds innermost defined face, colors cycle back through."
  :tag "Color Scheme"
  :group 'highlight-backquotes
  :link '(custom-group-link "highlight-backquotes")
  ;;:link '(custom-group-link :tag "Toggle Delimiters" "highlight-backquotes-toggle-delimiter-highlighting")
  :prefix 'highlight-backquotes-faces-)

;; Choose which delimiters you want to highlight in your preferred language:

;;; Faces:

;; Unmatched comma face:
(defface highlight-backquotes-unmatched-face
  '((((background light)) (:background "#68040B"))
    (((background dark)) (:background "#68040B")))
  "Face to highlight commas without matching backquotes."
  :group 'highlight-backquotes-faces)

(defface highlight-backquotes-normal-face
  ;;'((((background light)) (:foreground "#FFFFFF")))
  '()
  "Empty face for unquoted forms."
  :tag "Fall-through for unquoted forms."
  :group 'highlight-backquotes-faces)

(defcustom highlight-backquotes-colors
  '("#a0ffff"
    "#6080ff" "#a06060" "#409040" "#ff2040" "#4020ff" "#20d020")
  "colors"
  :type '(repeat color)
  :group 'highlight-backquotes
  )

;; Faces for highlighting delimiters by nested level:
(defface highlight-backquotes-depth-1-face
  `((((background light)) (:foreground ,(nth 0 highlight-backquotes-colors)))
    (((background dark)) (:foreground ,(nth 0 highlight-backquotes-colors))))
  "Backquote face, depth 1 - outermost set."
  :tag "Highlight Backquotes Depth 1 Face -- OUTERMOST"
  :group 'highlight-backquotes-faces)

(defface highlight-backquotes-depth-2-face
  `((((background light)) (:foreground ,(nth 1 highlight-backquotes-colors)))
    (((background dark)) (:foreground ,(nth 1 highlight-backquotes-colors))))
  "Backquote face, depth 2."
  :group 'highlight-backquotes-faces)

(defface highlight-backquotes-depth-3-face
  `((((background light)) (:foreground ,(nth 2 highlight-backquotes-colors)))
    (((background dark)) (:foreground ,(nth 2 highlight-backquotes-colors))))
  "Backquote face, depth 3."
  :group 'highlight-backquotes-faces)

(defface highlight-backquotes-depth-4-face
  `((((background light)) (:foreground ,(nth 3 highlight-backquotes-colors)))
    (((background dark)) (:foreground ,(nth 3 highlight-backquotes-colors))))
  "Backquote face, depth 4."
  :group 'highlight-backquotes-faces)

(defface highlight-backquotes-depth-5-face
  `((((background light)) (:foreground ,(nth 4 highlight-backquotes-colors)))
    (((background dark)) (:foreground ,(nth 4 highlight-backquotes-colors))))
  "Backquote face, depth 4."
  :group 'highlight-backquotes-faces)

(defface highlight-backquotes-depth-6-face
  `((((background light)) (:foreground ,(nth 5 highlight-backquotes-colors)))
    (((background dark)) (:foreground ,(nth 5 highlight-backquotes-colors))))
  "Backquote face, depth 4."
  :group 'highlight-backquotes-faces)

(defface highlight-backquotes-depth-7-face
  `((((background light)) (:foreground ,(nth 6 highlight-backquotes-colors)))
    (((background dark)) (:foreground ,(nth 6 highlight-backquotes-colors))))
  "Backquote face, depth 4."
  :group 'highlight-backquotes-faces)

(defconst highlight-backquotes-max-face-count 7
  "Number of faces defined for highlighting delimiter levels.

Determines depth at which to cycle through faces again.")

;;; Face utility functions

(defsubst highlight-backquotes-depth-face (depth)
  "Return face-name for DEPTH as a string 'highlight-backquotes-depth-DEPTH-face'.

For example: 'highlight-backquotes-depth-1-face'."
  (concat "highlight-backquotes-depth-"
          (number-to-string
           (or
            ;; Our nesting depth has a face defined for it.
            (and (< depth highlight-backquotes-max-face-count)
                 depth)
            ;; Deeper than # of defined faces; cycle back through to beginning.
            ;; Depth 1 face is only applied to the outermost quotation level.
            ;; Cycles infinitely through faces 2-9.
            (let ((cycled-depth (mod depth highlight-backquotes-max-face-count)))
              (if (/= cycled-depth 0)
                  ;; Return face # that corresponds to current quotation level.
                  (mod depth highlight-backquotes-max-face-count)
                ;; Special case: depth divides evenly into max, correct face # is max.
                highlight-backquotes-max-face-count))))
          "-face"))

;;; Nesting level

(defsubst highlight-backquotes-depth (loc)
  "Return # of nested levels of parens, brackets, braces LOC is inside of."
  (let ((depth
         (car (syntax-ppss loc))))
    (if (>= depth 0)
        depth
      0))) ; ignore negative depths created by unmatched closing parens.


;;; Text properties

;; Backwards compatibility: Emacs < v23.2 lack macro 'with-silent-modifications'.
(eval-and-compile
  (unless (fboundp 'with-silent-modifications)
    (defmacro with-silent-modifications (&rest body)
      "Defined by highlight-backquotes.el for backwards compatibility with Emacs < 23.2.
 Execute BODY, pretending it does not modify the buffer.
If BODY performs real modifications to the buffer's text, other
than cosmetic ones, undo data may become corrupted.

This macro will run BODY normally, but doesn't count its buffer
modifications as being buffer modifications.  This affects things
like buffer-modified-p, checking whether the file is locked by
someone else, running buffer modification hooks, and other things
of that nature.

Typically used around modifications of text-properties which do
not really affect the buffer's content."
      (declare (debug t) (indent 0))
      (let ((modified (make-symbol "modified")))
        `(let* ((,modified (buffer-modified-p))
                (buffer-undo-list t)
                (inhibit-read-only t)
                (inhibit-modification-hooks t)
                deactivate-mark
                ;; Avoid setting and removing file locks and checking
                ;; buffer's uptodate-ness w.r.t the underlying file.
                buffer-file-name
                buffer-file-truename)
           (unwind-protect
               (progn
                 ,@body)
             (unless ,modified
               (restore-buffer-modified-p nil))))))))


;; bug: does not return true for char that initiates comment,
;;   so initial-whitespace will be set to nil, although if you
;;   rely on this your code is bad and you should feel bad
;; also not checking if we immediately follow a string
;; e.g. `"barf"narf highlights narf as level 1
(defsubst highlight-backquotes-char-ineligible-p (loc)
  "Return t if char at LOC should be skipped, e.g. if inside a comment.

Returns t if char at loc meets one of the following conditions:
- Inside a string.
- Inside a comment.
- Is an escaped char, e.g. ?\)"
  (let ((parse-state (syntax-ppss loc)))
    (or
     (nth 3 parse-state)                ; inside string?
     (nth 4 parse-state)                ; inside comment?
     (and (eq (char-before loc) ?\\)  ; escaped char, e.g. ?\) - not counted
          (and (not (eq (char-before (1- loc)) ?\\)) ; special-case: ignore ?\\
               (eq (char-before (1- loc)) ?\?))))))
;; NOTE: standard char read syntax '?)' is not tested for because emacs manual
;; states punctuation such as delimiters should _always_ use escaped '?\)' form.

(defsubst highlight-backquotes-apply-color (depth loc)
  (with-silent-modifications
    (let ((face
           (cond ((zerop depth)
                  "highlight-backquotes-normal-face")
                 ((< depth 0)
                  "highlight-backquotes-unmatched-face")
                 (t
                  (highlight-backquotes-depth-face depth)))))
      (add-text-properties loc (1+ loc)
                           `(font-lock-face ,face
                                            rear-nonsticky t)))))

(defsubst highlight-backquotes-apply-color-region (depth start end)
  (with-silent-modifications
    (let ((face
           (cond ((zerop depth) ;; find another way to do fallthrough -- this doesn't work
                  "highlight-backquotes-normal-face")
                 ((< depth 0)
                  "highlight-backquotes-unmatched-face")
                 (t
                  (highlight-backquotes-depth-face depth)))))
      (add-text-properties start end
                           `(font-lock-face ,face
                                            rear-nonsticky t)))))

(defsubst highlight-backquotes-unpropertize-delimiter (loc)
  "Remove text properties set by highlight-backquotes mode from char at LOC."
  (with-silent-modifications
    (remove-text-properties loc (1+ loc)
                            '(font-lock-face nil
                              rear-nonsticky nil))))

;;; JIT-Lock functionality

;; todo: merge common code between these two functions
(defun highlight-backquotes-get-backquote-state (&optional pos)
  "Traverse and return backquote state up to POS."
  ;;(interactive)
  (save-excursion
    (or pos (setq pos (point)))
    (let* ((ppss (syntax-ppss pos))
           (start (or
                   ;;1 ;; if we wanted to be really sure... and really slow
                   (car (tenth ppss)) ;; top level paren
                   (third ppss))) ;; beginning of word
           (quote-depth 0)
           (stack nil)
           (initial-whitespace nil)
           (after-comma nil) ;; might be ,. or ,@
           (after-close-paren nil) ;; can omit whitespace before anything;
                                   ;; terminates sexp and thus quotation markers for sure
           (after-plain-char nil)) ;; can omit whitespace before special char
      ;;(message "starting ppss: %s %s %s" ppss pos start)
      (when start ;; when does syntax-ppss not return values we can use???
        (goto-char start)
        
        ;; go to start of line containing top-level form
        (forward-line 0)
        ;; note: not testing for pathological situation where multiple
        ;; backquotes begin an expression on multiple lines like:
        ;; ```
        ;; ``(barf ,narf)
        ;; but lisps should cut off backquoting if backquotes precede nothing
        ;; but whitespace on a top-level line
        
        (while (< (point) pos)
          ;;(message "state: %s %s %s %s %s %s %s %s"
          ;;         (point)
          ;;         (make-string 1 (char-after (point)))
          ;;         quote-depth
          ;;         initial-whitespace
          ;;         after-comma
          ;;         after-close-paren
          ;;         after-plain-char
          ;;         stack)
          (unless (highlight-backquotes-char-ineligible-p (point))
            (let ((char (char-after (point)))
                  (unwind
                   ;; undo quotation level changes up to most recent open paren
                   (lambda ()
                     (while (and stack (not (eq 'paren (car stack))))
                       (cond
                        ((eq 'comma (car stack))
                         (setq quote-depth (1+ quote-depth)
                               ;;depth-changed t
                               ))
                        ((eq 'backquote (car stack))
                         (setq quote-depth (1- quote-depth)
                               ;;depth-changed t
                               )))
                       (setq stack (cdr stack))))))
              (when after-close-paren
                  (funcall unwind)
                  (setq after-close-paren nil))
              (cond ((eq ?\' char)
                     (when after-plain-char
                       (funcall unwind))
                     (setq after-comma nil
                           after-plain-char nil))
                    ((eq ?\` char)
                     (when after-plain-char
                       (funcall unwind))
                     (setq quote-depth (1+ quote-depth)
                           stack (cons 'backquote stack)
                           initial-whitespace t
                           after-comma nil
                           after-plain-char nil))
                    ((eq ?\, char)
                     (when after-plain-char
                       (funcall unwind))
                     (setq quote-depth (1- quote-depth)
                           stack (cons 'comma stack)
                           initial-whitespace t
                           after-comma t
                           after-plain-char nil))
                    
                    ;; is this right?
                    ;; probably shouldn't bother to check dot context error
                    ((or (eq ?\. char) (eq ?\@ char))
                     ;;(setq after-plain-char nil)
                     (if after-comma
                         (setq after-comma nil
                               after-plain-char nil
                               )
                       (setq initial-whitespace nil
                             after-plain-char t
                             )))
                    ((eq ?\( char)
                     (when after-plain-char
                       (funcall unwind))
                     (setq stack (cons 'paren stack)
                           initial-whitespace nil
                           after-comma nil
                           after-plain-char nil))
                    ((eq ?\) char)
                     (funcall unwind)
                     (setq stack (cdr stack) ;; finally pop paren
                           after-comma nil
                           after-close-paren t
                           after-plain-char nil))
                    ((or (eq ?\s char) (eq ?\n char) (eq ?\t char))
                     (unless initial-whitespace
                       (funcall unwind))
                     (setq after-comma nil
                           after-plain-char nil))
                    (t (setq initial-whitespace nil
                             after-comma nil
                             after-plain-char t)))))
          (forward-char)))
      (list quote-depth stack
            initial-whitespace after-comma
            after-close-paren after-plain-char))))



;; to do -- make it work when you're typing at the end of the buffer
(defun highlight-backquotes-propertize-region (start end)
  "Highlight backquote levels in region between START and END."
  (save-excursion
    (goto-char start)
    (let* ((backquote-state (highlight-backquotes-get-backquote-state start))
           (quote-depth (first backquote-state))
           (stack (second backquote-state))
           (initial-whitespace (third backquote-state))
           (after-comma (fourth backquote-state))
           (after-close-paren (fifth backquote-state))
           (after-plain-char (sixth backquote-state)))
      ;;(message "starting post-startup traversal %s %s %s" backquote-state start end)
      (unless nil
        (let ((depth-region-start (point))
              (old-depth quote-depth))
          (while (< (point) end)
            ;;(message "pstate: %s %s %s %s %s %s %s %s %s"
            ;;       (point)
            ;;       (make-string 1 (char-after (point)))
            ;;       quote-depth
            ;;       depth-region-start
            ;;       initial-whitespace
            ;;       after-comma
            ;;       after-close-paren
            ;;       after-plain-char
            ;;       stack)
            (unless (highlight-backquotes-char-ineligible-p (point))
              (let* ((char (char-after (point)))
                     (depth-changed nil ;;(= (point) start)
                      )
                     (unwind (lambda ()
                               (while (and stack (not (eq 'paren (car stack))))
                                 (cond
                                  ((eq 'comma (car stack))
                                   (setq quote-depth (1+ quote-depth)
                                         depth-changed t))
                                  ((eq 'backquote (car stack))
                                   (setq quote-depth (1- quote-depth)
                                         depth-changed t)))
                                 (setq stack (cdr stack)))))
                    ;;(unwind nil)
                    ;;(depth-region-start (point))
                    ;;(old-depth quote-depth)
                    )
                (when after-close-paren
                  (funcall unwind)
                  (setq after-close-paren nil))
                (cond ((eq ?\' char)
                       (when after-plain-char
                         (funcall unwind))
                       (setq after-comma nil
                             after-plain-char nil))
                      ((eq ?\` char)
                       (when after-plain-char
                         (funcall unwind))
                       (setq quote-depth (1+ quote-depth)
                             stack (cons 'backquote stack)
                             initial-whitespace t
                             after-comma nil
                             after-plain-char nil
                             depth-changed t))
                      ((eq ?\, char)
                       (when after-plain-char
                         (funcall unwind))
                       (setq quote-depth (1- quote-depth)
                             stack (cons 'comma stack)
                             initial-whitespace t
                             after-comma t
                             after-plain-char nil
                             depth-changed t))
                      ((or (eq ?\. char) (eq ?\@ char))
                       ;;(setq after-plain-char nil)
                       (if after-comma
                           (setq after-comma nil
                                 after-plain-char nil
                                 )
                         (setq initial-whitespace nil
                               after-plain-char t
                               ))
                       (setq after-close-paren nil))
                      ((eq ?\( char)
                       (when after-plain-char
                         (funcall unwind))
                       (setq stack (cons 'paren stack)
                             initial-whitespace nil
                             after-comma nil
                             after-plain-char nil))
                      ((eq ?\) char)
                       (funcall unwind)
                       (setq stack (cdr stack) ;; finally pop paren
                             after-comma nil
                             after-close-paren t
                             after-plain-char nil
                             ;;unwind t
                             ))
                      ((or (eq ?\s char) (eq ?\n char) (eq ?\t char))
                       (unless initial-whitespace
                         (funcall unwind)
                         ;;(while (and stack (not (eq 'paren (car stack))))
                         ;;  (cond
                         ;;   ((eq 'comma (car stack))
                         ;;    (setq quote-depth (1+ quote-depth)
                         ;;          depth-changed t))
                         ;;   ((eq 'backquote (car stack))
                         ;;    (setq quote-depth (1- quote-depth)
                         ;;          depth-changed t)))
                         ;;  (setq stack (cdr stack)))
                         )
                       (setq after-comma nil
                             after-plain-char nil))
                      (t (setq initial-whitespace nil
                               after-comma nil
                               after-plain-char t)))

                (when depth-changed
                  ;;(message "depth changed %s %s %s" old-depth depth-region-start (point))
                  ;; question: should new color begin with backquote/unquote symbol, or immediately after?
                  (highlight-backquotes-apply-color-region old-depth depth-region-start (point))
                  (setq old-depth quote-depth
                        depth-region-start (point)))
                (unless t ;;(eq ?\n char)
                  (highlight-backquotes-apply-color quote-depth (point)))
                ))
            (forward-char))
          ;;(message "final: %s %s %s" quote-depth depth-region-start (point))
          ;; final region: no necessary depth change at end
          ;; also, this function is not always called over complete top-level sexps
          (highlight-backquotes-apply-color-region quote-depth depth-region-start (point))
          )))))

(defun highlight-backquotes-unpropertize-region (start end)
  "Remove text properties set by highlight-backquotes mode between START and END."
  (with-silent-modifications
    (remove-text-properties start end
                            '(font-lock-face nil
                                             rear-nonsticky nil)))
  ;;(save-excursion
  ;;  (while (< (point) end)
  ;;    ;; re-search-forward places point 1 further than the delim matched:
  ;;    (highlight-backquotes-unpropertize-delimiter (1- (point)))
  ;;    (forward-char)))
  )


;;; Minor mode:

;;;###autoload
(define-minor-mode highlight-backquotes-mode
  "Highlight quotation levels of Lisp forms."
  nil " hl-bq" nil
  (if (not highlight-backquotes-mode)
      (progn
        (jit-lock-unregister 'highlight-backquotes-propertize-region)
        (highlight-backquotes-unpropertize-region (point-min) (point-max)))
    (jit-lock-register 'highlight-backquotes-propertize-region t)))

;;;###autoload
(defun highlight-backquotes-mode-enable ()
  (highlight-backquotes-mode 1))

;;;###autoload
(defun highlight-backquotes-mode-disable ()
  (highlight-backquotes-mode 0))

;;;###autoload
(define-globalized-minor-mode global-highlight-backquotes-mode
  highlight-backquotes-mode highlight-backquotes-mode-enable)

(provide 'highlight-backquotes)

;;; highlight-backquotes.el ends here.
