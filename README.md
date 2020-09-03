# About
Ever wanted to have a live-updating list of all flycheck errors in your project?
You've come to the right place! flycheck-projectile is an Emacs plugin that can
gather all errors in your project and display them in a
`flycheck-list-errors`-like table.

# Usage
Call `flycheck-projectile-list-errors`. This will pop up a list of all flycheck
errors in your project, prompting you to supply it if needed. You can bind the
function to "SPC p E", for example. To close the list again press q, which will
also remove any hooks set up.

# Installation
## Melpa (package-install)
This package is on `MELPA`, so you can install it using `package-install` if you
have configured `MELPA` as a package source.

## From github
Even though this package is on `MELPA`, you can install it from GitHub:

```console
$ mkdir ~/.emacs.d/packages/
$ git clone https://github.com/nbfalcon/flycheck-projectile.git ~/.emacs.d/packages/
```

And calling use-package:

```elisp
(use-package flycheck-projectile
  :load-path "~/.emacs.d/packages/")
```

To integrate the plugin with spacemacs' popwin, you can use the following
use-package block instead:

# Integration
## Spacemacs (popwin)

If you use `popwin` (installed by default in spacemacs), you can use the
following snippet to make `flycheck-projectile-list-errors`' popup behave like
that of `flycheck-list-errors`:

```elisp
(use-package flycheck-projectile
  :load-path "~/Projects/emacs/plugins/"
  :config
  (add-to-list 'popwin:special-display-config
               `(,flycheck-projectile-error-list-buffer
                 :regexp nil :dedicated t :position bottom :stick t
                 :noselect nil)))
```

This will make the buffer created by flycheck-projectile-list-errors a popup
that is always at the bottom. Note that you still should use q to quit it (you
**can**, but **shouldn't**, use `C-g`), as otherwise `flycheck-projectile`
cannot remove its hooks to restore Emacs' performance.

# Limitations
Unlike `flycheck-list-errors`, `flycheck-projectile-list-errors` currently does
not highlight the errors corresponding to the current buffer line in the error
list.
