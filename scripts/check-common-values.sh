#!/bin/bash
set -euo pipefail

# Check that there's no divergence between ./common-values.yaml, key `global`,
# and the `global` key on the helm-chart values.yaml

diff <(yq --sort-keys .global common-values.yaml) <(yq --sort-keys .global charts/kubewarden-controller/values.yaml) || (
	echo
	echo "kubewaden-controller values.yaml diverges from common-values.yaml"
	exit 1
)
diff <(yq --sort-keys .global common-values.yaml) <(yq --sort-keys .global charts/kubewarden-defaults/values.yaml) || (
	echo
	echo "kubewaden-defaults values.yaml diverges from common-values.yaml"
	exit 1
)
