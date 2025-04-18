{{- define "common.labels.standard" -}}
app.kubernetes.io/name: "scylladb"
app.kubernetes.io/instance: {{ .Release.Name | quote}}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
{{- end }}


{{- define "common.labels.matchLabels" -}}
app.kubernetes.io/name: "scylladb"
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
