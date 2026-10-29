SHELL:=bash

.PHONY: check-common-values
check-common-values:
	@./scripts/check-common-values.sh

.PHONY: shellcheck
shellcheck:
	shellcheck scripts/*

CHARTS ?= $(shell find . -type f -name 'Chart.yaml' -exec dirname {} \; | sort | tr '\n' ' ')

.PHONY: test
test:
	helm unittest --color=always $(CHARTS)
