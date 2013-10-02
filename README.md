This is an Emacs minor mode (following the example of rainbow-delimiters) to change the color of Lisp code based on the backquote depth.

![once-only](/images/once-only.png "once-only")

![pandoric-eval](/images/pandoric-eval.png "pandoric-eval")

![too-many-unquotes](/images/too-many-unquotes.png "too-many-unquotes")

Known issues:
The previous colorization may not always reappear once the mode is disabled.

Unknown issues:
Not tested for Lisps other than Common Lisp. I'm not entirely sure whether the readers for other Lisps work entirely the same in regards to pathological corner cases.

Future work:
Make this work as an extra layer on top of lisp-mode so keywords are highlighted but still appear somewhat distinct at different backquote levels.