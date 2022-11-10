#!/bin/bash

CHART_DIR=$1
CHARTS_DIRS=`find $CHART_DIR -type d -exec test -e '{}'/values.yaml \; -print`
TMP_IMAGE_FILE=/tmp/imageslist.txt

if [ -e imagelist.txt ]; then
	rm imagelist.txt
fi
for chart in $CHARTS_DIRS; do
	helm template --values $chart/values.yaml $chart/ | yq -r "..|.image?" | sort -u | grep -v "null"  > $TMP_IMAGE_FILE
	sed --in-place '/---/d' $TMP_IMAGE_FILE
	cat $TMP_IMAGE_FILE | sort -u > $chart/imagelist.txt
	# Unified imagelist.txt file. Containing image from all charts.
	cat $chart/imagelist.txt >> imagelist.txt
done
