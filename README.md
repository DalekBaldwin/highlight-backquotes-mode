This is an Emacs minor mode (following the example of rainbow-delimiters) to change the color of Lisp code based on the backquote depth.

It's helpful for writing macros as well as understanding them. After I first got it working, I finally had an intuitive understanding for what the comma + single-quote pattern does and started using it in a more consistent fashion.

![once-only](/images/once-only.png "once-only")

![pandoric-eval](/images/pandoric-eval.png "pandoric-eval")

![too-many-unquotes](/images/too-many-unquotes.png "too-many-unquotes")

Known issues:
- The previous colorization may not always reappear once the mode is disabled.
- Escaped characters like #\\` are not handled.

Unknown issues:
- Not tested for Lisps other than Common Lisp. I'm not entirely sure whether the readers for other Lisps work entirely the same in regards to pathological corner cases.

Future work:
- Make this work as an extra layer on top of lisp-mode so keywords are highlighted but still appear somewhat distinct at different backquote levels.
- Visually indicate symbols that are vulnerable to capture.
- Make color change after backquote or comma, not before. At first I thought the current approach was more helpful during the process of writing a macro, but there are some hairy situations (in which you want an actual comma to appear in the final form) where it's misleading.
