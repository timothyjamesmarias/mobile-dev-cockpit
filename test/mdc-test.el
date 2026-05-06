;;; mdc-test.el --- Tests for mobile-dev-cockpit -*- lexical-binding: t; -*-

;;; Commentary:

;; Baseline test to verify the test infrastructure works.

;;; Code:

(require 'ert)
(require 'mdc)

(ert-deftest mdc-test-package-loads ()
  "Verify that mdc loads without error."
  (should (featurep 'mdc)))

;;; mdc-test.el ends here
