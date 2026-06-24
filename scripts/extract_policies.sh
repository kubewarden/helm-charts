#!/bin/bash
set -euo pipefail

CHART_DIR="$1"
ADMISSION_CONTROLLER_CHART="$CHART_DIR/admission-controller"
POLICYLIST_FILENAME=policylist.txt
TMP_POLICY_FILE=/tmp/$POLICYLIST_FILENAME

# Clean up any existing policy list files
find "$CHART_DIR" -type f -name $POLICYLIST_FILENAME -delete
[ -e $POLICYLIST_FILENAME ] && rm $POLICYLIST_FILENAME

# Extract policies from admission-controller chart
helm template --values "$ADMISSION_CONTROLLER_CHART"/values.yaml --set recommendedPolicies.enabled=true "$ADMISSION_CONTROLLER_CHART/" \
	| yq -r '. | select(.kind=="ConfigMap") | .data[] | select(. != null) | from_yaml | select(.kind=="ClusterAdmissionPolicy" or .kind=="AdmissionPolicy") | .spec.module' > "$TMP_POLICY_FILE"

# Add registry prefix if necessary and write to chart's policylist.txt
while IFS= read -r line; do
	if [[ $(echo "$line" | awk '!/(https:\/\/|registry:\/\/)/') ]]; then
		echo "$line" | sed 's/^/registry:\/\//' >> "$ADMISSION_CONTROLLER_CHART"/$POLICYLIST_FILENAME
	else
		echo "$line" >> "$ADMISSION_CONTROLLER_CHART"/$POLICYLIST_FILENAME
	fi
done < "$TMP_POLICY_FILE"

# Sort the chart's policylist.txt
sort -u -o "$ADMISSION_CONTROLLER_CHART"/$POLICYLIST_FILENAME "$ADMISSION_CONTROLLER_CHART"/$POLICYLIST_FILENAME

# Create master policylist.txt at root
cp "$ADMISSION_CONTROLLER_CHART"/$POLICYLIST_FILENAME $POLICYLIST_FILENAME
