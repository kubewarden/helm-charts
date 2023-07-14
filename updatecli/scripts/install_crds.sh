#!/bin/bash

tar -xf /tmp/crds-controller.tar.gz
find . -maxdepth 1 -name "*_policyserver*" -exec  mv \{\} /tmp/helm-charts/charts/kubewarden-crds/templates/policyservers.yaml \;
find . -maxdepth 1 -name "*_admissionpolicies*" -exec  mv \{\} /tmp/helm-charts/charts/kubewarden-crds/templates/admissionpolicies.yaml \;
find . -maxdepth 1 -name "*_clusteradmissionpolicies*" -exec  mv \{\} /tmp/helm-charts/charts/kubewarden-crds/templates/clusteradmissionpolicies.yaml \;

tar -xvf /tmp/crds-audit-scanner.tar.gz
find . -maxdepth 1 -name "*_clusterpolicyreports*" -exec  mv \{\} charts/kubewarden-crds/templates/clusterpolicyreports.yaml \;
find . -maxdepth 1 -name "*_policyreports*" -exec  mv \{\} charts/kubewarden-crds/templates/policyreports.yaml \;

# updatecli expects something in stdout when a change happened.
echo "Changed!"
