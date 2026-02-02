{{- define "mosquitto.name" -}}
mosquitto
{{- end -}}

{{- define "mosquitto.fullname" -}}
{{ include "mosquitto.name" . }}-{{ .Release.Name }}
{{- end -}}
