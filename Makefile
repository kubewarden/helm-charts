SHELL:=bash

.PHONY: check-common-values
check-common-values:
	@./scripts/check-common-values.sh

.PHONY: generate-images-file
generate-images-file:
	@./scripts/extract_images.sh ./charts

.PHONY: generate-policies-file
generate-policies-file:
	@./scripts/extract_policies.sh ./charts

.PHONY: generate-changelog-files
generate-changelog-files:
	@./scripts/generate_changelog_files.sh ./charts imagelist.txt

.PHONY: shellcheck
shellcheck:
	shellcheck scripts/*

test:
	helm unittest --color ./charts/kubewarden-crds ./charts/kubewarden-defaults ./charts/kubewarden-controller
