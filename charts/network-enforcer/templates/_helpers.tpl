{{/*
Expand the name of the chart.
*/}}
{{- define "network-enforcer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "network-enforcer.fullname" -}}
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
{{- define "network-enforcer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "network-enforcer.labels" -}}
helm.sh/chart: {{ include "network-enforcer.chart" . }}
{{ include "network-enforcer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "network-enforcer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "network-enforcer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod labels for the controller Deployment.
Chart-owned labels (selector labels, component, common labels) always win over
user-supplied controller.podLabels, so overriding a reserved key such as
app.kubernetes.io/name cannot desync the Pod template from spec.selector.
*/}}
{{- define "network-enforcer.controller.podLabels" -}}
{{- $chartLabels := dict "app.kubernetes.io/component" "controller" -}}
{{- $chartLabels = merge $chartLabels (include "network-enforcer.labels" . | fromYaml) -}}
{{- $userLabels := default dict .Values.controller.podLabels -}}
{{- toYaml (merge $chartLabels $userLabels) -}}
{{- end -}}

{{/*
Print the image pull secrets in the expected format (an array of objects with one possible field, "name").
Each entry of .Values.imagePullSecrets can be a plain string or a {name: ...} object.
*/}}
{{- define "network-enforcer.imagePullSecrets" }}
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
Name of the controller OTLP service used to reach the istio scraper.
*/}}
{{- define "network-enforcer.controller.istioService" -}}
{{ include "network-enforcer.fullname" . }}-istio-otlp
{{- end -}}

{{/*
Resolved provider name.
*/}}
{{- define "network-enforcer.provider.name" -}}
{{- default "istio" .Values.controller.provider.name -}}
{{- end -}}

{{/*
Active provider config object (controller.provider.<name>).
*/}}
{{- define "network-enforcer.provider.active" -}}
{{- $name := include "network-enforcer.provider.name" . -}}
{{- if not (has $name (list "istio" "cilium" "calico")) -}}
{{- fail (printf "unsupported controller.provider.name %q" $name) -}}
{{- end -}}
{{- $cfg := index .Values.controller.provider $name | default dict -}}
{{- if not $cfg -}}
{{- fail (printf "controller.provider.%s is required when controller.provider.name=%q" $name $name) -}}
{{- end -}}
{{- $cfg | toJson -}}
{{- end -}}

{{/*
TLS values for the active provider.
*/}}
{{- define "network-enforcer.provider.tls.values" -}}
{{- $cfg := include "network-enforcer.provider.active" . | fromJson -}}
{{- default dict $cfg.tls | toJson -}}
{{- end -}}

{{/*
Resolved provider endpoint from controller.provider.<name>.endpoint.
Cilium: when tls.mode=insecure and endpoint is still the TLS default (...:443),
rewrite the port to 80. This only adjusts the endpoint; plaintext also requires
clearing tls.serverName (the chart rejects a non-empty serverName when insecure).
*/}}
{{- define "network-enforcer.controller.providerEndpoint" -}}
{{- $name := include "network-enforcer.provider.name" . -}}
{{- $cfg := include "network-enforcer.provider.active" . | fromJson -}}
{{- $endpoint := $cfg.endpoint | default "" | toString -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- if and (eq $name "cilium") (eq $mode "insecure") (or (empty $endpoint) (eq $endpoint "hubble-relay.kube-system.svc:443")) -}}
hubble-relay.kube-system.svc:80
{{- else if empty $endpoint -}}
{{- fail (printf "controller.provider.%s.endpoint is required" $name) -}}
{{- else -}}
{{- $endpoint -}}
{{- end -}}
{{- end -}}

{{/*
Validated Istio OTLP port.
Accepts configured int/string from controller.provider.istio.endpoint.
*/}}
{{- define "network-enforcer.controller.istioPort" -}}
{{- $raw := include "network-enforcer.controller.providerEndpoint" . | trim -}}
{{- if not (regexMatch "^[0-9]{1,5}$" $raw) -}}
{{- fail (printf "controller.provider.istio.endpoint must be a numeric port when controller.provider.name=istio (got %q)" $raw) -}}
{{- end -}}
{{- $port := atoi $raw -}}
{{- if or (lt $port 1) (gt $port 65535) -}}
{{- fail (printf "controller.provider.istio.endpoint must be in range 1-65535 when controller.provider.name=istio (got %d)" $port) -}}
{{- end -}}
{{- $port -}}
{{- end -}}

{{/*
Port the controller health/readiness probe endpoint binds to.
Internal wiring: kept in a single place so the --health-probe-bind-address flag
and the liveness/readiness probes cannot drift. Not user configurable.
*/}}
{{- define "network-enforcer.controller.probePort" -}}
8081
{{- end -}}

{{/*
Directory where generic provider TLS material is mounted (CSI or a local Secret).
*/}}
{{- define "network-enforcer.provider.tls.certDir" -}}
/etc/provider/certs
{{- end -}}

{{/*
TLS mode for the active provider.
*/}}
{{- define "network-enforcer.provider.tls.mode" -}}
{{- $tls := include "network-enforcer.provider.tls.values" . | fromJson -}}
{{- $mode := default "" $tls.mode -}}
{{- if not $mode -}}
{{- fail (printf "controller.provider.%s.tls.mode is required" (include "network-enforcer.provider.name" .)) -}}
{{- end -}}
{{- $mode -}}
{{- end -}}

{{/*
cert-manager Issuer name used when mode=issuer.
Falls back to the chart CA Issuer when issuerRef.name is empty.
*/}}
{{- define "network-enforcer.provider.tls.issuerName" -}}
{{- $tls := include "network-enforcer.provider.tls.values" . | fromJson -}}
{{- $issuer := default dict $tls.issuerRef -}}
{{- if $issuer.name -}}
{{- $issuer.name -}}
{{- else -}}
{{- include "network-enforcer.caIssuerName" . -}}
{{- end -}}
{{- end -}}

{{/*
DNS SANs for the provider TLS certificate issued via CSI.
Istio is a server hop, so the names must match the istio-otlp Service.
Cilium's client certificate only has to sit in Cilium's own name space.
*/}}
{{- define "network-enforcer.provider.tls.dnsNames" -}}
{{- $provider := include "network-enforcer.provider.name" . -}}
{{- if eq $provider "istio" -}}
{{- $svc := include "network-enforcer.controller.istioService" . -}}
{{- printf "%s,%s.%s,%s.%s.svc,%s.%s.svc.%s" $svc $svc .Release.Namespace $svc .Release.Namespace $svc .Release.Namespace .Values.kubernetesClusterDomain -}}
{{- else if eq $provider "cilium" -}}
network-enforcer.hubble-relay.cilium.io
{{- else -}}
{{ include "network-enforcer.fullname" . }}-controller-manager
{{- end -}}
{{- end -}}

{{/*
True when the chart should create the self-signed CA Issuer used by issuer
mode and the shipped OTel collector.
*/}}
{{- define "network-enforcer.caIssuer.enabled" -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- if or (eq .Values.telemetry.collectorStrategy "default") (eq $mode "issuer") -}}
true
{{- end -}}
{{- end -}}

{{/*
Existing Secret settings for the active provider.
*/}}
{{- define "network-enforcer.provider.tls.existingSecret" -}}
{{- $tls := include "network-enforcer.provider.tls.values" . | fromJson -}}
{{- $secret := default dict $tls.existingSecret -}}
{{- dict "name" (default "" $secret.name) "namespace" (default "" $secret.namespace) "caBundleConfigMap" (default "" $secret.caBundleConfigMap) "caBundleKey" (default "ca.crt" $secret.caBundleKey) | toJson -}}
{{- end -}}

{{/*
Resolved TLS server name; empty defers to the endpoint host.
*/}}
{{- define "network-enforcer.provider.tls.serverName" -}}
{{- $tls := include "network-enforcer.provider.tls.values" . | fromJson -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- if eq $mode "insecure" -}}
{{- else if $tls.serverName -}}
{{- $tls.serverName -}}
{{- end -}}
{{- end -}}

{{/*
True when provider TLS material is read from the API server (cross-namespace Secret).
*/}}
{{- define "network-enforcer.provider.tls.apiSecret" -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- $secret := include "network-enforcer.provider.tls.existingSecret" . | fromJson -}}
{{- if and (eq $mode "existingSecret") $secret.name $secret.namespace -}}
true
{{- end -}}
{{- end -}}

{{/*
Validate provider TLS values and fail at template time.
*/}}
{{- define "network-enforcer.provider.tls.validate" -}}
{{- $path := printf "controller.provider.%s.tls" (include "network-enforcer.provider.name" .) -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- $tls := include "network-enforcer.provider.tls.values" . | fromJson -}}
{{- $secret := include "network-enforcer.provider.tls.existingSecret" . | fromJson -}}
{{- $provider := include "network-enforcer.provider.name" . -}}
{{- if and (eq $provider "calico") (eq $mode "insecure") -}}
{{- fail (printf "%s.mode=insecure is not supported when controller.provider.name=calico; Goldmane requires mTLS (use existingSecret or issuer)" $path) -}}
{{- end -}}
{{- if not (has $mode (list "issuer" "existingSecret" "insecure")) -}}
{{- fail (printf "%s.mode must be issuer, existingSecret, or insecure (got %q)" $path $mode) -}}
{{- end -}}
{{- if and (eq $mode "issuer") (not (include "network-enforcer.provider.tls.issuerName" . | trim)) -}}
{{- fail (printf "%s.issuerRef.name is required when %s.mode=issuer" $path $path) -}}
{{- end -}}
{{- if and (eq $mode "existingSecret") (not $secret.name) -}}
{{- fail (printf "%s.existingSecret.name is required when %s.mode=existingSecret" $path $path) -}}
{{- end -}}
{{/*
Istio is a TLS server, so it needs tls.crt/tls.key mounted: only a same-namespace Secret or issuer CSI works.
*/}}
{{- if and (eq $provider "istio") (eq (include "network-enforcer.provider.tls.apiSecret" . | trim) "true") -}}
{{- fail (printf "%s.existingSecret.namespace cannot be set when controller.provider.name=istio; the Istio scraper is a TLS server and needs tls.crt/tls.key mounted in the pod" $path) -}}
{{- end -}}
{{- if and (eq $mode "insecure") $tls.serverName -}}
{{- fail (printf "%s.serverName is not accepted when %s.mode=insecure" $path $path) -}}
{{- end -}}
{{- end -}}

{{/*
Controller flags for the provider TLS hop.
*/}}
{{- define "network-enforcer.provider.tls.args" -}}
{{- include "network-enforcer.provider.tls.validate" . -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim }}
- --provider-tls-mode={{ $mode }}
{{- if eq $mode "issuer" }}
- --provider-tls-cert-dir={{ include "network-enforcer.provider.tls.certDir" . }}
{{- else if and (eq $mode "existingSecret") (eq (include "network-enforcer.provider.tls.apiSecret" . | trim) "true") }}
{{- $secret := include "network-enforcer.provider.tls.existingSecret" . | fromJson }}
- --provider-tls-cert-secret={{ $secret.namespace }}/{{ $secret.name }}
{{- if $secret.caBundleConfigMap }}
- --provider-tls-ca-configmap={{ $secret.namespace }}/{{ $secret.caBundleConfigMap }}
- --provider-tls-ca-bundle-key={{ default "ca.crt" $secret.caBundleKey }}
{{- end }}
{{- else if eq $mode "existingSecret" }}
- --provider-tls-cert-dir={{ include "network-enforcer.provider.tls.certDir" . }}
{{- end }}
{{- $serverName := include "network-enforcer.provider.tls.serverName" . | trim }}
{{- if $serverName }}
- --provider-tls-server-name={{ $serverName }}
{{- end }}
{{- end -}}

{{/*
Volume mounts for provider TLS material.
*/}}
{{- define "network-enforcer.provider.tls.volumeMounts" -}}
{{- include "network-enforcer.provider.tls.validate" . -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- if eq $mode "issuer" }}
- name: provider-tls
  mountPath: {{ include "network-enforcer.provider.tls.certDir" . }}
  readOnly: true
{{- else if and (eq $mode "existingSecret") (ne (include "network-enforcer.provider.tls.apiSecret" . | trim) "true") }}
{{- $secret := include "network-enforcer.provider.tls.existingSecret" . | fromJson -}}
{{- if and $secret.name (not $secret.namespace) }}
- name: provider-tls
  mountPath: {{ include "network-enforcer.provider.tls.certDir" . }}
  readOnly: true
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Volumes for provider TLS material.
*/}}
{{- define "network-enforcer.provider.tls.volumes" -}}
{{- include "network-enforcer.provider.tls.validate" . -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- $tls := include "network-enforcer.provider.tls.values" . | fromJson -}}
{{- $issuer := default dict $tls.issuerRef -}}
{{- $secret := include "network-enforcer.provider.tls.existingSecret" . | fromJson -}}
{{- if eq $mode "issuer" }}
- name: provider-tls
  csi:
    driver: "csi.cert-manager.io"
    readOnly: true
    volumeAttributes:
      csi.cert-manager.io/issuer-name: {{ include "network-enforcer.provider.tls.issuerName" . }}
      csi.cert-manager.io/issuer-kind: {{ default "Issuer" $issuer.kind }}
      {{- if $issuer.group }}
      csi.cert-manager.io/issuer-group: {{ $issuer.group }}
      {{- end }}
      csi.cert-manager.io/dns-names: {{ include "network-enforcer.provider.tls.dnsNames" . }}
{{- else if and (eq $mode "existingSecret") $secret.name (not $secret.namespace) }}
- name: provider-tls
  secret:
    secretName: {{ $secret.name }}
{{- end -}}
{{- end -}}

{{/*
Certificate directory for the shipped OTel collector's own (server-side) mTLS
keys, mounted via cert-manager CSI.
*/}}
{{- define "network-enforcer.otelCollector.certDir" -}}
/etc/otel-collector/certs
{{- end -}}

{{/*
CA certificate path used by the controller when sending OTLP logs to the
shipped in-cluster collector.
*/}}
{{- define "network-enforcer.otel.caCertDir" -}}
/tmp/otel-collector-certs
{{- end -}}
{{- define "network-enforcer.otel.caCertPath" -}}
{{ include "network-enforcer.otel.caCertDir" . }}/ca.crt
{{- end -}}


{{/*
Print the otel environment variable settings.
*/}}
{{- define "network-enforcer.otel.config.env" }}
{{- if eq .Values.telemetry.collectorStrategy "default" }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: https://{{ include "network-enforcer.fullname" . }}-otel-collector.{{ .Release.Namespace }}.svc.cluster.local:4317
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: grpc
- name: OTEL_EXPORTER_OTLP_CERTIFICATE
  value: {{ include "network-enforcer.otel.caCertPath" . }}
{{- else if eq .Values.telemetry.collectorStrategy "external" }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ .Values.telemetry.externalCollector.endpoint }}
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: {{ .Values.telemetry.externalCollector.protocol }}
{{- if .Values.telemetry.externalCollector.otelCollectorCertificateSecret }}
- name: OTEL_EXPORTER_OTLP_CERTIFICATE
  value: {{ include "network-enforcer.otel.caCertPath" . }}
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
Print the otel volumeMounts settings.
The strategy gate mirrors network-enforcer.otel.config.volumes so mounts and
volumes are always emitted (or omitted) as a pair.
*/}}
{{- define "network-enforcer.otel.config.volumeMounts" }}
{{- if or (eq .Values.telemetry.collectorStrategy "default") (and (eq .Values.telemetry.collectorStrategy "external") .Values.telemetry.externalCollector.otelCollectorCertificateSecret) }}
- name: otel-collector-ca-cert
  mountPath: {{ include "network-enforcer.otel.caCertDir" . }}
  readOnly: true
{{- end }}
{{- if and (eq .Values.telemetry.collectorStrategy "external") .Values.telemetry.externalCollector.otelCollectorClientCertificateSecret }}
- name: otel-collector-client-cert
  mountPath: /tmp/otel-collector-client-certs
  readOnly: true
{{- end }}
{{- end }}

{{/*
Print the otel volumes settings.
*/}}
{{- define "network-enforcer.otel.config.volumes" }}
{{- if eq .Values.telemetry.collectorStrategy "default" }}
- name: otel-collector-ca-cert
  secret:
    secretName: {{ include "network-enforcer.caSecretName" . }}
    items:
    - key: ca.crt
      path: ca.crt
{{- end }}
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

{{/*
Volume mounts for the Istio fluent-bit client certificate.
*/}}
{{- define "network-enforcer.istio.fluentBit.tls.volumeMounts" -}}
{{- include "network-enforcer.provider.tls.validate" . -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- if or (eq $mode "issuer") (and (eq $mode "existingSecret") (ne (include "network-enforcer.provider.tls.apiSecret" . | trim) "true")) }}
- name: provider-tls
  mountPath: {{ include "network-enforcer.provider.tls.certDir" . }}
  readOnly: true
{{- end -}}
{{- end -}}

{{/*
Volumes for the Istio fluent-bit client certificate.
Issuer mode uses cert-manager CSI with a per-Pod client cert. A same-namespace
existingSecret is mounted as-is.
*/}}
{{- define "network-enforcer.istio.fluentBit.tls.volumes" -}}
{{- include "network-enforcer.provider.tls.validate" . -}}
{{- $mode := include "network-enforcer.provider.tls.mode" . | trim -}}
{{- $tls := include "network-enforcer.provider.tls.values" . | fromJson -}}
{{- $issuer := default dict $tls.issuerRef -}}
{{- $secret := default dict $tls.existingSecret -}}
{{- if eq $mode "issuer" }}
- name: provider-tls
  csi:
    driver: "csi.cert-manager.io"
    readOnly: true
    volumeAttributes:
      csi.cert-manager.io/issuer-name: {{ include "network-enforcer.provider.tls.issuerName" . }}
      csi.cert-manager.io/issuer-kind: {{ default "Issuer" $issuer.kind }}
      {{- if $issuer.group }}
      csi.cert-manager.io/issuer-group: {{ $issuer.group }}
      {{- end }}
      csi.cert-manager.io/dns-names: {{ include "network-enforcer.fullname" . }}-istio-fluent-bit
{{- else if and (eq $mode "existingSecret") $secret.name (not $secret.namespace) }}
- name: provider-tls
  secret:
    secretName: {{ $secret.name }}
{{- end -}}
{{- end -}}

{{/*
Certificate helpers for mTLS (CA issuer and secret share a name).
*/}}
{{- define "network-enforcer.caIssuerName" -}}
{{ include "network-enforcer.fullname" . }}-ca
{{- end -}}
{{- define "network-enforcer.caSecretName" -}}
{{ include "network-enforcer.fullname" . }}-ca
{{- end -}}
