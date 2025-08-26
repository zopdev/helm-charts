{{- define "langchain-server.name" -}}
langchain-server
{{- end }}

{{- define "langchain-server.fullname" -}}
{{ .Release.Name }}-langchain
{{- end }}
