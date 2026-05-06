EMACS ?= emacs

.PHONY: compile test lint check clean test-apps

compile:
	eask compile

test:
	eask test ert ./test/*.el

lint:
	eask lint package

check: compile lint test

clean:
	eask clean elc

test-apps:
	git clone --depth 1 https://github.com/apple/sample-food-truck test-apps/ios
	git clone --depth 1 https://github.com/android/nowinandroid test-apps/android
