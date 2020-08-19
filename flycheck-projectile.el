;;; flycheck-projectile.el --- Project-wide errors -*- lexical-binding: t -*-

;; Copyright (C) 2020  Nikita Bloshchanevich

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Author: Nikita Bloshchanevich <nikblos@outlook.com>
;; URL: https://github.com/nbfalcon/flycheck-projectile
;; Package-Requires: ((emacs "25.1"))
;; Version: 0.1

;;; Commentary:
;; Implement per-project errors by leveraging flycheck and projectile.

;;; Code:

(require 'tabulated-list)
(require 'flycheck) ;; for error-list constants
(require 'projectile)
(require 'cl-lib)

(defconst flycheck-projectile-error-list-buffer "*Project errors*")

;; (flycheck-projectile-buffer-errors :: Buffer -> [flycheck-error])
(defun flycheck-projectile-buffer-errors (buffer)
  "Return BUFFER's flycheck errors."
  (buffer-local-value 'flycheck-current-errors buffer))

;; (flycheck-projectile-gather-errors :: String -> [flycheck-error])
(defun flycheck-projectile-gather-errors (project)
  "Gather PROJECT's flycheck errors into a list."
  (when-let ((buffers (projectile-project-buffers project)))
    (seq-mapcat #'flycheck-projectile-buffer-errors buffers)))

(defvar flycheck-projectile--project nil "Project whose errors are shown.")

(defcustom flycheck-projectile-blacklisted-checkers '()
  "Flycheck backends to be ignored in the project-wide error list."
  :group 'flycheck-projectile
  :type '(repeat symbol))

(defun flycheck-projectile-make-list-entries ()
  "Generate the list entries for the project-wide error list."
  (mapcar
   #'flycheck-error-list-make-entry
   (cl-delete-if
    (lambda (err) (memq (flycheck-error-checker err)
                        flycheck-projectile-blacklisted-checkers))
    (sort (flycheck-projectile-gather-errors flycheck-projectile--project)
          (lambda (a b) (or (string< (flycheck-error-filename a)
                                     (flycheck-error-filename b))
                            (< (flycheck-error-line a)
                               (flycheck-error-line b))))))))

(defun flycheck-projectile-error-list-goto-error (&optional list-pos)
  "Go to the error in current error-list at LIST-POS.
LIST-POS defaults to (`point')."
  (interactive)
  (when-let ((err (tabulated-list-get-id list-pos))
             (buf (flycheck-error-buffer err))
             (pos (flycheck-error-pos err)))
    (pop-to-buffer buf 'other-window)
    (goto-char pos)))

(defun flycheck-projectile--reload-errors ()
  "Refresh the errors in the project-wide error list."
  (with-current-buffer flycheck-projectile-error-list-buffer
    (revert-buffer)))

(defun flycheck-projectile--maybe-reload ()
  "Reload the project-wide error list for its projects' buffers only.
If the current buffer is part of `flycheck-projectile--project',
reload the project-wide error list."
  (when (projectile-project-buffer-p (current-buffer)
                                     flycheck-projectile--project)
    (flycheck-projectile--reload-errors)))

(defun flycheck-projectile--handle-flycheck-off ()
  "Handle flycheck-mode being turned off.
Reloads the project-wide error list, without the errors of the
buffer whose `flycheck-mode' was just turned off, if it is part
of `flycheck-projectile--project'."
  (unless flycheck-mode
    (flycheck-projectile--maybe-reload)))

(define-minor-mode flycheck-projectile--project-buffer-mode
  "Minor mode to help auto-reload the project's error list.
It sets up various hooks for the current buffer so that the
project-wide error list gets auto-updated."
  :init-value nil
  :lighter nil
  (cond
   (flycheck-projectile--project-buffer-mode
    ;; When flycheck is turned off, all errors must disappear.
    (add-hook 'flycheck-mode-hook #'flycheck-projectile--handle-flycheck-off
              nil t)
    ;; after syntax checking, new errors could have appeared.
    (add-hook 'flycheck-after-syntax-check-hook
              #'flycheck-projectile--reload-errors nil t)
    ;; remove the buffer's errors after it is gone
    (add-hook 'kill-buffer-hook #'flycheck-projectile--reload-errors nil t))
   (t
    (remove-hook 'flycheck-mode-hook
                 #'flycheck-projectile--handle-flycheck-off t)
    (remove-hook 'flycheck-after-syntax-check-hook
                 #'flycheck-projectile--reload-errors t)
    (remove-hook 'kill-buffer-hook #'flycheck-projectile--reload-errors t))))

(defun flycheck-projectile--handle-flycheck ()
  "Enable `flycheck-projectile--project-buffer-mode' for project buffers.
If flycheck was enabled, track the buffer with
`flycheck-projectile--project-buffer-mode'. Disable that mode otherwise."
  (when (projectile-project-buffer-p (current-buffer) flycheck-projectile--project)
    (flycheck-projectile--project-buffer-mode (if flycheck-mode 1 -1))))

(defun flycheck-projectile--disable-project-buffer-mode ()
  "Disable `flycheck-projectile--project-buffer-mode' for all buffers."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (flycheck-projectile--project-buffer-mode -1))))

(defun flycheck-projectile--enable-project-buffer-mode (project)
  "Enable `flycheck-projectile--project-buffer-mode' for PROJECT's buffers."
  (dolist (buffer (projectile-project-buffers project))
    (with-current-buffer buffer
      ;; only buffers with flycheck-mode on can contribute and as such only
      ;; those should be watched
      (when flycheck-mode
        (flycheck-projectile--project-buffer-mode 1)))))

(defun flycheck-projectile--global-setup ()
  "Set up hooks so that new project buffers are handled correctly."
  (add-hook 'flycheck-mode-hook #'flycheck-projectile--handle-flycheck))

(defun flycheck-projectile--global-teardown ()
  "Remove the hooks set up by `flycheck-projectile--global-setup'."
  (remove-hook 'flycheck-mode-hook #'flycheck-projectile--handle-flycheck)
  (flycheck-projectile--disable-project-buffer-mode)
  ;; tell `flycheck-projectile-list-errors' that cleanup already happened.
  (setq flycheck-projectile--project nil))

(defun flycheck-projectile--quit-kill-window ()
  "Quit and kill the buffer of the current window."
  (interactive)
  (quit-window t))

(defvar flycheck-projectile-error-list-mode-map
  (let ((map (copy-keymap flycheck-error-list-mode-map)))
    (define-key map (kbd "RET") #'flycheck-projectile-error-list-goto-error)
    (define-key map (kbd "q") #'flycheck-projectile--quit-kill-window)
    map))
(define-derived-mode flycheck-projectile-error-list-mode tabulated-list-mode
  "Flycheck project errors"
  "The mode for this plugins' project-wide error list."
  (setq tabulated-list-format flycheck-error-list-format
        tabulated-list-padding flycheck-error-list-padding
        ;; we must sort manually, because there are two sort keys: first File
        ;; then Line.
        tabulated-list-sort-key nil
        tabulated-list-entries #'flycheck-projectile-make-list-entries)
  (tabulated-list-init-header))

(defconst flycheck-projectile-error-list-buffer "*Project errors*"
  "Name of the project-wide error list buffer.")

;;;###autoload
(defun flycheck-projectile-list-errors (&optional dir)
  "Show a list of all the errors in the current project.
Start the project search at DIR."
  (interactive)
  (unless (get-buffer flycheck-projectile-error-list-buffer)
    (with-current-buffer (get-buffer-create flycheck-projectile-error-list-buffer)
      ;; Make it not part of any project, so that
      ;; `flycheck-projectile--project-buffer-mode' wont get enabled for it.
      (setq default-directory nil)
      ;; If the user kills the buffer, leave no hooks behind; for they would
      ;; impair the performance. Pressing `q' kills the buffer.
      (add-hook 'kill-buffer-hook #'flycheck-projectile--global-teardown nil t)
      (flycheck-projectile-error-list-mode)))

  (when flycheck-projectile--project ;; the user didn't press q
    (flycheck-projectile--global-teardown))

  (let ((project (projectile-ensure-project (projectile-project-root dir))))
    (flycheck-projectile--enable-project-buffer-mode project)
    (with-current-buffer flycheck-projectile-error-list-buffer
      (setq flycheck-projectile--project project)

      ;; even if the user presses C-g here, the kill hook was already set up;
      ;; this way, he can just kill the buffer to restore performance.
      (flycheck-projectile--global-setup)
      (revert-buffer) ;; reload the list
      ))

  (display-buffer flycheck-projectile-error-list-buffer))

(provide 'flycheck-projectile)
;;; flycheck-projectile.el ends here
