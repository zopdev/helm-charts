{{- define "prometheus.fullname" -}}
{{ .Release.Name }}-prometheus
{{- end }}

{{- define "prometheus.labels" -}}
app.kubernetes.io/name: prometheus
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "prometheus.selectorLabels" -}}
app.kubernetes.io/name: prometheus
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
