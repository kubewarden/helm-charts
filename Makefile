SHELL:=bash

.PHONY: check-common-values
check-common-values:
	@./scripts/check-common-values.sh

.PHONY: generate-policies-file
generate-policies-file:
	@./scripts/extract_policies.sh ./charts

.PHONY: shellcheck
shellcheck:
	shellcheck scripts/*

test:
	helm unittest --color ./charts/kubewarden-crds ./charts/kubewarden-defaults ./charts/kubewarden-controller
