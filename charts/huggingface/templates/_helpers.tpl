{{- define "huggingface.name" -}}
huggingface
{{- end }}

{{- define "huggingface.fullname" -}}
{{ .Release.Name }}-huggingface
{{- end }}

{{- define "huggingface.labels" -}}
app.kubernetes.io/name: huggingface
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
