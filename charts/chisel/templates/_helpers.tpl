{{- define "chisel.name" -}}
  {{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "chisel.fullname" -}}
  {{- printf "%s-chisel" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "chisel.reverseServiceName" -}}
  {{- printf "%s-reverse" (include "chisel.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "chisel.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "chisel.labels" -}}
app: {{ include "chisel.name" . }}
chart: {{ include "chisel.chart" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "chisel.selectorLabels" -}}
app: {{ include "chisel.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "chisel.keySecretName" -}}
  {{- .Values.key.existingSecret | default (printf "%s-key" (include "chisel.fullname" .)) -}}
{{- end -}}

{{- define "chisel.authSecretName" -}}
  {{- .Values.auth.existingSecret | default (printf "%s-auth" (include "chisel.fullname" .)) -}}
{{- end -}}

{{/*
True when a reverse port range is set.
*/}}
{{- define "chisel.reversePortsEnabled" -}}
  {{- if and .Values.reversePorts.start .Values.reversePorts.end -}}true{{- end -}}
{{- end -}}

{{- define "chisel.feedPort" -}}
  {{- regexFind "[0-9]+$" .Values.feed.address -}}
{{- end -}}
