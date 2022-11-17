#!/bin/bash
set -euo pipefail

CHART_DIR="$1"
CHARTS_DIRS=$(find "$CHART_DIR" -type d -exec test -e '{}'/values.yaml \; -print)
POLICYLIST_FILENAME=policylist.txt
TMP_IMAGE_FILE=/tmp/$POLICYLIST_FILENAME

find "$CHART_DIR" -type f -name $POLICYLIST_FILENAME -delete
if [ -e $POLICYLIST_FILENAME ]; then
       rm $POLICYLIST_FILENAME
fi

for chart in $CHARTS_DIRS; do
	if [[ $chart == *"-defaults" ]]; then
		helm template --values "$chart"/values.yaml --set recommendedPolicies.enabled=true "$chart/" \
			| yq -r ". | select(.kind==\"ClusterAdmissionPolicy\" or .kind==\"AdmissionPolicy\") | .spec.module" > "$TMP_IMAGE_FILE"
		sed --in-place '/---/d' $TMP_IMAGE_FILE
		# adds the registry prefix if necessary
		file=$(cat $TMP_IMAGE_FILE)
		for line in $file; do
			if [[ $(echo $line | awk '!/(https:\/\/|registry:\/\/)/') ]]; then
				echo $line | sed 's/^/registry:\/\//'  >> "$chart"/$POLICYLIST_FILENAME 
				continue
			fi
			echo $line >> "$chart"/$POLICYLIST_FILENAME 
		done
	fi
done

# Delete the empty policylist.txt files.
find $CHART_DIR -type f -name $POLICYLIST_FILENAME -empty -delete
# Unified imagelist.txt file. Containing image from all charts.
find $CHART_DIR -type f -name $POLICYLIST_FILENAME | xargs cat > $POLICYLIST_FILENAME
# Sort policylist file
find $CHART_DIR -type f -name $POLICYLIST_FILENAME -exec sort -u -o \{\} \{\} \;
sort -u -o $POLICYLIST_FILENAME $POLICYLIST_FILENAME
