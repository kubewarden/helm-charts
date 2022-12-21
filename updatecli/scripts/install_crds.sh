#!/bin/bash

tar -xf /tmp/crds.tar.gz
find . -maxdepth 1 -name "*_policyserver*" -exec  mv \{\} /tmp/helm-charts/charts/kubewarden-crds/templates/policyservers.yaml \;
find . -maxdepth 1 -name "*_admissionpolicies*" -exec  mv \{\} /tmp/helm-charts/charts/kubewarden-crds/templates/admissionpolicies.yaml \;
find . -maxdepth 1 -name "*_clusteradmissionpolicies*" -exec  mv \{\} /tmp/helm-charts/charts/kubewarden-crds/templates/clusteradmissionpolicies.yaml \;

# updatecli expects something in the stdout when a change happen.
echo "Changed!"
