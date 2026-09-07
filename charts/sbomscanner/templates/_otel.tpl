{{/*
OTel exporter wiring for the instrumented workloads.
All templates render nothing when otel.endpoint is empty.
The TLS environment variables point at the mounts rendered by
sbomscanner.otelVolumeMounts / sbomscanner.otelVolumes.
*/}}

{{- define "sbomscanner.otelEnv" -}}
{{- if .Values.otel.endpoint }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ .Values.otel.endpoint | quote }}
- name: K8S_POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: K8S_POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
{{- if .Values.otel.caSecretName }}
- name: OTEL_EXPORTER_OTLP_CERTIFICATE
  value: /otel/tls/ca/ca.crt
{{- end }}
{{- if .Values.otel.clientCertificateSecretName }}
- name: OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE
  value: /otel/tls/client/tls.crt
- name: OTEL_EXPORTER_OTLP_CLIENT_KEY
  value: /otel/tls/client/tls.key
{{- end }}
{{- end }}
{{- end }}

{{- define "sbomscanner.otelVolumeMounts" -}}
{{- if .Values.otel.endpoint }}
{{- if .Values.otel.caSecretName }}
- name: otel-ca
  mountPath: /otel/tls/ca
  readOnly: true
{{- end }}
{{- if .Values.otel.clientCertificateSecretName }}
- name: otel-client-tls
  mountPath: /otel/tls/client
  readOnly: true
{{- end }}
{{- end }}
{{- end }}

{{- define "sbomscanner.otelVolumes" -}}
{{- if .Values.otel.endpoint }}
{{- if .Values.otel.caSecretName }}
- name: otel-ca
  secret:
    secretName: {{ .Values.otel.caSecretName }}
{{- end }}
{{- if .Values.otel.clientCertificateSecretName }}
- name: otel-client-tls
  secret:
    secretName: {{ .Values.otel.clientCertificateSecretName }}
{{- end }}
{{- end }}
{{- end }}
