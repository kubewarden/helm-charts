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
Common labels
*/}}
{{- define "runtime-enforcer.labels" -}}
helm.sh/chart: {{ include "runtime-enforcer.chart" . }}
{{ include "runtime-enforcer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
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
Create the name of the service account to use
*/}}
{{- define "runtime-enforcer.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "runtime-enforcer.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
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
{{- define "runtime-enforcer.otelCollector.certDir" -}}
/etc/otel-collector/certs
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
Print the image pull secrets in the expected format (an array of objects with one possible field, "name").
*/}}
{{- define "imagePullSecrets" }}
    {{- $imagePullSecrets := list }}
    {{- range . }}
        {{- if kindIs "string" . }}
            {{- $imagePullSecrets = append $imagePullSecrets (dict "name" .) }}
        {{- else }}
            {{- $imagePullSecrets = append $imagePullSecrets . }}
        {{- end }}
    {{- end }}
    {{- toYaml $imagePullSecrets }}
{{- end }}

{{/*
Print the otel environment varilable settings.
*/}}
{{- define "runtime-enforcer.otel.config.env" }}
{{- if eq .Values.telemetry.collectorStrategy "default" }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: https://{{ include "runtime-enforcer.fullname" . }}-otel-collector.{{ .Release.Namespace }}.svc.cluster.local:4317
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: grpc
- name: OTEL_EXPORTER_OTLP_CERTIFICATE
  value: {{ include "runtime-enforcer.grpc.certDir" . }}/ca.crt
{{- else if eq .Values.telemetry.collectorStrategy "external" }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ .Values.telemetry.externalCollector.endpoint }}
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: {{ .Values.telemetry.externalCollector.protocol }}
{{- if .Values.telemetry.externalCollector.otelCollectorCertificateSecret }}
- name: OTEL_EXPORTER_OTLP_CERTIFICATE
  value: /tmp/otel-collector-certs/ca.crt
{{- else }}
- name: OTEL_EXPORTER_OTLP_INSECURE
  value: "true"
{{- end }}
{{- if .Values.telemetry.externalCollector.otelCollectorClientCertificateSecret }}
- name: OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE
  value: /tmp/otel-collector-client-certs/tls.crt
- name: OTEL_EXPORTER_OTLP_CLIENT_KEY
  value: /tmp/otel-collector-client-certs/tls.key
{{- end }}
{{- end }}
{{- end }}


{{/*
Print the otel volumeMounts settings
*/}}
{{- define "runtime-enforcer.otel.config.volumeMounts" }}
{{- if .Values.telemetry.externalCollector.otelCollectorCertificateSecret }}
- name: otel-collector-ca-cert
  mountPath: /tmp/otel-collector-certs
  readOnly: true
{{- end }}
{{- if .Values.telemetry.externalCollector.otelCollectorClientCertificateSecret }}
- name: otel-collector-client-cert
  mountPath: /tmp/otel-collector-client-certs
  readOnly: true
{{- end }}
{{- end }}

{{/*
Print the otel volumes settings
*/}}
{{- define "runtime-enforcer.otel.config.volumes" }}
{{- if and (eq .Values.telemetry.collectorStrategy "external") .Values.telemetry.externalCollector.otelCollectorCertificateSecret }}
- name: otel-collector-ca-cert
  secret:
    secretName: {{ .Values.telemetry.externalCollector.otelCollectorCertificateSecret }}
{{- end }}
{{- if and (eq .Values.telemetry.collectorStrategy "external") .Values.telemetry.externalCollector.otelCollectorClientCertificateSecret }}
- name: otel-collector-client-cert
  secret:
    secretName: {{ .Values.telemetry.externalCollector.otelCollectorClientCertificateSecret }}
{{- end }}
{{- end }}
