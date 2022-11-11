{{- define "policy-namespace-selector" -}}
namespaceSelector:
  matchExpressions:
    - key: "kubernetes.io/metadata.name"
      operator: NotIn
      values:
{{- range $namespace := .Values.recommendedPolicies.skipNamespaces }}
        - {{ $namespace }}
{{- end }}
{{- end -}}

{{- define "system_default_registry" -}}
{{- if .Values.common.cattle.systemDefaultRegistry -}}
{{- printf "%s/" .Values.common.cattle.systemDefaultRegistry -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}
