
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
