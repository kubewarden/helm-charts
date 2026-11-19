{{/*
Expand the name of the chart.
*/}}
{{- define "runtime-enforcer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "runtime-enforcer.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "runtime-enforcer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Namespace for all namespaced resources of the chart.
It is namespaceOverride, or the release namespace when namespaceOverride is empty.
*/}}
{{- define "runtime-enforcer.namespace" -}}
{{- $override := .Values.namespaceOverride | default "" -}}
{{- $override | default .Release.Namespace -}}
{{- end -}}

{{/*
Registry prefix for the chart images, with a trailing "/".
global.imageRegistry wins over the image.registry of the workload block.
*/}}
{{- define "system_default_registry" -}}
{{- $global := .root.Values.global | default dict -}}
{{- with $global.imageRegistry | default (include "runtime-enforcer._image" . | fromYaml).registry -}}
{{- printf "%s/" . -}}
{{- end -}}
{{- end -}}

{{/*
runtime-enforcer._image renders the image map of the workload block as YAML,
or an empty map when the block has no image.
It takes the context dict of the workload helpers.
*/}}
{{- define "runtime-enforcer._image" -}}
{{- $block := index .root.Values .workload | default dict -}}
{{- toYaml ($block.image | default dict) -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "runtime-enforcer.labels" -}}
helm.sh/chart: {{ include "runtime-enforcer.chart" . }}
{{ include "runtime-enforcer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/part-of: runtime-enforcer
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "runtime-enforcer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "runtime-enforcer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Certificates helpers
*/}}
{{- define "runtime-enforcer.grpc.certDir" -}}
/etc/runtime-enforcer/certs
{{- end -}}
{{- define "runtime-enforcer.caIssuerName" -}}
{{ include "runtime-enforcer.fullname" . }}-ca
{{- end -}}
{{- define "runtime-enforcer.caSecretName" -}}
{{ include "runtime-enforcer.fullname" . }}-ca
{{- end -}}

{{/* Agent label selector string derived from agent pod labels */}}
{{- define "runtime-enforcer.agent.labelSelector" -}}
app.kubernetes.io/component: agent
{{ include "runtime-enforcer.selectorLabels" . }}
{{- end -}}

{{/*
Convert labels rendered as YAML (e.g. "k: v\nk2: v2") into a comma-separated selector string "k=v,k2=v2".
Usage:
  {{ include "runtime-enforcer.labelSelectorToString" (include "runtime-enforcer.agent.labelSelector" .) }}
*/}}
{{- define "runtime-enforcer.labelSelectorToString" -}}
{{- $yaml := . | default "" -}}
{{- $m := (fromYaml $yaml) | default dict -}}
{{- $keys := keys $m | sortAlpha -}}
{{- $out := list -}}
{{- range $k := $keys -}}
  {{- $out = append $out (printf "%s=%v" $k (get $m $k)) -}}
{{- end -}}
{{- join "," $out -}}
{{- end -}}

{{/* Convenience: agent selector string */}}
{{- define "runtime-enforcer.agent.labelSelectorString" -}}
{{- include "runtime-enforcer.labelSelectorToString" (include "runtime-enforcer.agent.labelSelector" .) -}}
{{- end -}}

{{/*
Values of the workloads

The workload templates read their values through the public helpers below.
Each public helper takes a context dict:
  root:      the root context ($)
  workload:  the name of the workload block in .Values: "controller", "agent", or "debugger"
  component: the value of the app.kubernetes.io/component label, for example "controller"
A context dict can also have:
  fixedWorkloadLabels: a map of extra fixed labels for the workload resource
                       (not the pod), for example the control-plane label.

A template builds the context dict once:
  {{- $ctx := dict "root" $ "workload" "controller" "component" "controller" }}

Each public helper reads one key with one private helper. The private helper sets the rule:
  runtime-enforcer._scalar: the workload value, else the common value, else the global value.
  runtime-enforcer._list:   the same rule as runtime-enforcer._scalar, for a list.
  runtime-enforcer._map:    the global, common, and workload maps merged. The workload wins on a duplicate key.
  runtime-enforcer._concat: the global, common, and workload lists, in this order.
An empty value ("", [] or {}) counts as unset.
The image registry and the pull policy of a workload are in its image map:
  system_default_registry (above): global.imageRegistry, else the workload image.registry.
  runtime-enforcer.imagePullPolicy: the workload image.pullPolicy, else common.imagePullPolicy,
                                    else global.imagePullPolicy.

The private helpers take dict "ctx" <context dict> "key" <key>.
A key with a dot, for example "serviceAccount.annotations", reads a nested map.
Templates do not call the private helpers.
*/}}

{{/*
runtime-enforcer._levels renders a YAML list with three items:
the value of the key in global, in common, and in the workload block.
The other private helpers decode this list, so they work on copies of .Values.
*/}}
{{- define "runtime-enforcer._levels" -}}
{{- $values := .ctx.root.Values -}}
{{- $blocks := list ($values.global | default dict) ($values.common | default dict) (index $values .ctx.workload | default dict) -}}
{{- $out := list -}}
{{- range $block := $blocks -}}
{{- $value := $block -}}
{{- range $part := splitList "." $.key -}}
{{- $value = index ($value | default dict) $part -}}
{{- end -}}
{{- $out = append $out $value -}}
{{- end -}}
{{- toYaml $out -}}
{{- end -}}

{{- define "runtime-enforcer._scalar" -}}
{{- $l := include "runtime-enforcer._levels" . | fromYamlArray -}}
{{- index $l 2 | default (index $l 1) | default (index $l 0) | default "" -}}
{{- end -}}

{{- define "runtime-enforcer._list" -}}
{{- $l := include "runtime-enforcer._levels" . | fromYamlArray -}}
{{- toYaml (index $l 2 | default (index $l 1) | default (index $l 0) | default list) -}}
{{- end -}}

{{- define "runtime-enforcer._map" -}}
{{- $l := include "runtime-enforcer._levels" . | fromYamlArray -}}
{{- toYaml (mergeOverwrite (dict) (index $l 0 | default dict) (index $l 1 | default dict) (index $l 2 | default dict)) -}}
{{- end -}}

{{- define "runtime-enforcer._concat" -}}
{{- $l := include "runtime-enforcer._levels" . | fromYamlArray -}}
{{- toYaml (concat (index $l 0 | default list) (index $l 1 | default list) (index $l 2 | default list)) -}}
{{- end -}}

{{/*
runtime-enforcer._field renders "<name>:" and the value as YAML.
It renders nothing when the value is empty.
It takes dict "name" <field name> "value" <value>.
*/}}
{{- define "runtime-enforcer._field" -}}
{{- with .value -}}
{{ $.name }}:
  {{- toYaml . | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
runtime-enforcer._labels renders "labels:" with the merged map of the key
and the fixed chart labels. The fixed chart labels win on a duplicate key.
It takes dict "ctx" <context dict> "key" <key> and an optional "fixed" map
of extra fixed labels.
*/}}
{{- define "runtime-enforcer._labels" -}}
{{- $labels := include "runtime-enforcer._map" . | fromYaml -}}
{{- $fixed := include "runtime-enforcer.labels" .ctx.root | fromYaml -}}
{{- $_ := set $fixed "app.kubernetes.io/component" .ctx.component -}}
{{- $fixed = mergeOverwrite $fixed (.fixed | default dict) -}}
labels:
  {{- toYaml (mergeOverwrite $labels $fixed) | nindent 2 }}
{{- end -}}

{{/* Public helpers that render a bare value. */}}

{{- define "runtime-enforcer.imagePullPolicy" -}}
{{- $l := include "runtime-enforcer._levels" (dict "ctx" . "key" "imagePullPolicy") | fromYamlArray -}}
{{- (include "runtime-enforcer._image" . | fromYaml).pullPolicy | default (index $l 1) | default (index $l 0) | default "" -}}
{{- end -}}

{{- define "runtime-enforcer.logLevel" -}}
{{- include "runtime-enforcer._scalar" (dict "ctx" . "key" "logLevel") -}}
{{- end -}}

{{/* Public helpers that render a whole field, or nothing when the value is empty. */}}

{{/*
runtime-enforcer.priorityClassName renders "priorityClassName:".
The name is the workload value, else common, else global.
When none is set, the controller and the agent use priorityClass.name,
and the debugger renders nothing.
*/}}
{{- define "runtime-enforcer.priorityClassName" -}}
{{- $name := include "runtime-enforcer._scalar" (dict "ctx" . "key" "priorityClassName") -}}
{{- if and (not $name) (has .workload (list "controller" "agent")) -}}
{{- $name = .root.Values.priorityClass.name | default "" -}}
{{- end -}}
{{- with $name -}}
priorityClassName: {{ . | quote }}
{{- end -}}
{{- end -}}

{{- define "runtime-enforcer.tolerations" -}}
{{- include "runtime-enforcer._field" (dict "name" "tolerations" "value" (include "runtime-enforcer._list" (dict "ctx" . "key" "tolerations") | fromYamlArray)) -}}
{{- end -}}

{{- define "runtime-enforcer.topologySpreadConstraints" -}}
{{- include "runtime-enforcer._field" (dict "name" "topologySpreadConstraints" "value" (include "runtime-enforcer._list" (dict "ctx" . "key" "topologySpreadConstraints") | fromYamlArray)) -}}
{{- end -}}

{{- define "runtime-enforcer.extraEnvFrom" -}}
{{- include "runtime-enforcer._field" (dict "name" "envFrom" "value" (include "runtime-enforcer._list" (dict "ctx" . "key" "extraEnvFrom") | fromYamlArray)) -}}
{{- end -}}

{{- define "runtime-enforcer.nodeSelector" -}}
{{- include "runtime-enforcer._field" (dict "name" "nodeSelector" "value" (include "runtime-enforcer._map" (dict "ctx" . "key" "nodeSelector") | fromYaml)) -}}
{{- end -}}

{{- define "runtime-enforcer.affinity" -}}
{{- include "runtime-enforcer._field" (dict "name" "affinity" "value" (include "runtime-enforcer._map" (dict "ctx" . "key" "affinity") | fromYaml)) -}}
{{- end -}}

{{- define "runtime-enforcer.workloadAnnotations" -}}
{{- include "runtime-enforcer._field" (dict "name" "annotations" "value" (include "runtime-enforcer._map" (dict "ctx" . "key" "annotations") | fromYaml)) -}}
{{- end -}}

{{/*
runtime-enforcer.podAnnotations renders "annotations:" for the pod template.
It takes the context dict and an optional "fixedPodAnnotations" map in it.
The fixed annotations win on a duplicate key.
*/}}
{{- define "runtime-enforcer.podAnnotations" -}}
{{- $annotations := include "runtime-enforcer._map" (dict "ctx" . "key" "podAnnotations") | fromYaml -}}
{{- $annotations = mergeOverwrite $annotations (.fixedPodAnnotations | default dict) -}}
{{- include "runtime-enforcer._field" (dict "name" "annotations" "value" $annotations) -}}
{{- end -}}

{{- define "runtime-enforcer.serviceAccountAnnotations" -}}
{{- include "runtime-enforcer._field" (dict "name" "annotations" "value" (include "runtime-enforcer._map" (dict "ctx" . "key" "serviceAccount.annotations") | fromYaml)) -}}
{{- end -}}

{{- define "runtime-enforcer.workloadLabels" -}}
{{- include "runtime-enforcer._labels" (dict "ctx" . "key" "labels" "fixed" .fixedWorkloadLabels) -}}
{{- end -}}

{{- define "runtime-enforcer.podLabels" -}}
{{- include "runtime-enforcer._labels" (dict "ctx" . "key" "podLabels") -}}
{{- end -}}

{{/*
runtime-enforcer.imagePullSecrets renders "imagePullSecrets:" with the global,
common, and workload lists, in this order.
Each item is a Secret name or a map with a name key. The helper renders a
name as a map. It skips an item with an empty or missing name.
It keeps an item of any other type, and Kubernetes rejects it.
*/}}
{{- define "runtime-enforcer.imagePullSecrets" -}}
{{- $secrets := list -}}
{{- range include "runtime-enforcer._concat" (dict "ctx" . "key" "imagePullSecrets") | fromYamlArray -}}
{{- if kindIs "string" . -}}
{{- if . -}}
{{- $secrets = append $secrets (dict "name" .) -}}
{{- end -}}
{{- else if kindIs "map" . -}}
{{- if .name -}}
{{- $secrets = append $secrets . -}}
{{- end -}}
{{- else -}}
{{- $secrets = append $secrets . -}}
{{- end -}}
{{- end -}}
{{- include "runtime-enforcer._field" (dict "name" "imagePullSecrets" "value" $secrets) -}}
{{- end -}}

{{/* Public helpers that render list entries, or nothing when the list is empty. */}}

{{- define "runtime-enforcer.extraEnv" -}}
{{- with include "runtime-enforcer._concat" (dict "ctx" . "key" "extraEnv") | fromYamlArray -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}

{{- define "runtime-enforcer.extraVolumes" -}}
{{- with include "runtime-enforcer._concat" (dict "ctx" . "key" "extraVolumes") | fromYamlArray -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}

{{- define "runtime-enforcer.extraVolumeMounts" -}}
{{- with include "runtime-enforcer._concat" (dict "ctx" . "key" "extraVolumeMounts") | fromYamlArray -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}
