#!/bin/bash
set -euo pipefail

CHART_DIR=$1
IMAGELIST_FILENAME=$2
TMP_CHANGELOG_FILE_PATH=/tmp/changelog.md

CONTROLLER_VERSION=$(grep "kubewarden-controller" < "$IMAGELIST_FILENAME" | sed "s/.*kubewarden-controller:\(\)/\1/g")
CONTROLLER_URL=$(gh release view "$CONTROLLER_VERSION" --repo kubewarden/kubewarden-controller --json "url" | jq -r ".url" )
POLICY_SERVER_VERSION=$(grep "policy-server" < "$IMAGELIST_FILENAME" | sed "s/.*policy-server:\(\)/\1/g")
POLICY_SERVER_URL=$(gh release view "$POLICY_SERVER_VERSION" --repo kubewarden/policy-server --json "url" | jq -r ".url" )
AUDIT_SCANNER_VERSION=$(grep "audit-scanner" < "$IMAGELIST_FILENAME" | sed "s/.*audit-scanner:\(\)/\1/g")
AUDIT_SCANNER_URL=$(gh release view "$AUDIT_SCANNER_VERSION" --repo kubewarden/audit-scanner --json "url" | jq -r ".url" )
{
  echo "Kubewarden controller [changelog]($CONTROLLER_URL)"
  echo "Policy server [changelog]($POLICY_SERVER_URL)"
  echo "Audit scanner [changelog]($AUDIT_SCANNER_URL)"
} >> $TMP_CHANGELOG_FILE_PATH
cp $TMP_CHANGELOG_FILE_PATH "$CHART_DIR/kubewarden-controller/CHANGELOG.md"
cp $TMP_CHANGELOG_FILE_PATH "$CHART_DIR/kubewarden-defaults/CHANGELOG.md"
cp $TMP_CHANGELOG_FILE_PATH "$CHART_DIR/kubewarden-crds/CHANGELOG.md"

