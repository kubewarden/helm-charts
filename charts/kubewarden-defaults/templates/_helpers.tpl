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
