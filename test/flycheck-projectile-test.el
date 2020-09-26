;;; flycheck-projectile-test.el --- ert test suite -*- lexical-binding: t -*-

;;; Commentary:
;; This module implements the `ert' testsuite of `flycheck-projectile'.

;;; Code:
(require 'ert)
(require 'flycheck-projectile)

(ert-deftest flycheck-projectile-lazy-loading ()
  "Assert that lazy-loading works correctly.
When executed in a clean Emacs instance, modules like `flycheck'
and `projectile' aren't loaded. To ensure that
`flycheck-projectile' still works in that case \(it should lazily
load them\), run its core function and hope that there are no
errors.

Meaningless in an environment where these modules are loaded, so
must be the first test run with `ert-runner'."
  (flycheck-projectile-list-errors))

;;; flycheck-projectile-test.el ends here
(provide 'flycheck-projectile-test)
