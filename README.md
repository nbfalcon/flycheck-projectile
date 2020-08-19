# About
Ever wanted to have live-updating list of all flycheck errors in your project?
You've come to the right place! flycheck-projectile is an Emacs plugin that can
gather all errors in your project and display them in a
`flycheck-list-errors`-like table.

# Usage
Call `flycheck-projectile-list-errors`. This will pop up a list of all flycheck
errors in your project, prompting you to supply it if needed. You can bind the
function to "SPC p E", for example. To close the list again press q. This will
also remove any hooks set up by the plugin, making Emacs fast again.

# Installation
This package is currently not on MELPA. However, you can install it manually by
cloning the repository:
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
that is always at the bottom. Note that you still should use q to quit it, as
otherwise Emacs' performance might be impaired.

# Limitations
Unlike `flycheck-list-errors`, `flycheck-projectile-list-errors` currently does
not highlight the errors corresponding to the current buffer line in the error
list.
