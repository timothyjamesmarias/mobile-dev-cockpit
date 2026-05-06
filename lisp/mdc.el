;;; mdc.el --- Emacs-native command layer for iOS and Android development -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Timothy Marias

;; Author: Timothy Marias
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1") (transient "0.5.0") (compat "30.0.2.0"))
;; Keywords: tools mobile ios android
;; URL: https://github.com/timothyjamesmarias/mobile-dev-cockpit

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Mobile Dev Cockpit (mdc) provides transient menus over platform CLIs
;; (xcodebuild, simctl, adb, gradle) with a unified verb vocabulary
;; across iOS and Android.

;;; Code:

(defgroup mdc nil
  "Mobile Dev Cockpit — iOS and Android development from Emacs."
  :group 'tools
  :prefix "mdc-")

(provide 'mdc)
;;; mdc.el ends here
