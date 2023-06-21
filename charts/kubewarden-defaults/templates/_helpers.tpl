{{/*
Expand the name of the chart.
*/}}
{{- define "kubewarden-defaults.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubewarden-defaults.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubewarden-defaults.labels" -}}
helm.sh/chart: {{ include "kubewarden-defaults.chart" . }}
{{ include "kubewarden-defaults.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- else }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: kubewarden
{{- if .Values.additionalLabels }}
{{ toYaml .Values.additionalLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubewarden-defaults.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubewarden-defaults.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Annotations
*/}}
{{- define "kubewarden-defaults.annotations" -}}
{{- if .Values.additionalAnnotations }}
{{ toYaml .Values.additionalAnnotations }}
{{- end }}
{{- end }}

{{- define "policy-namespace-selector" -}}
namespaceSelector:
  matchExpressions:
  - key: "kubernetes.io/metadata.name"
    operator: NotIn
    values:
{{- with .Values.recommendedPolicies.skipNamespaces }}
      {{- toYaml . | nindent 4 }}
{{- end }}
{{- with .Values.recommendedPolicies.skipAdditionalNamespaces }}
      {{- toYaml . | nindent 4 }}
{{- end }}
{{- end -}}

{{- define "system_default_registry" -}}
{{- if .Values.common.cattle.systemDefaultRegistry -}}
{{- printf "%s/" .Values.common.cattle.systemDefaultRegistry -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}

{{- define "policy-module" -}}
{{- if (hasPrefix "http" .module) -}}
{{- printf "%s" .module -}}
{{- else  -}}
{{- if .registry -}}
{{- printf "%s/%s" .registry .module -}}
{{- else  -}}
{{- printf "%s/%s" .systemDefaultRegistry .module -}}
{{- end -}}
{{- end -}}
{{- end -}}

