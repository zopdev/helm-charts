{{/*
Names of the objects the upstream `holmes` subchart creates. They are
built from the parent release name, so recompute them here rather than
guessing: the ingress has to point at that Service and the alerts have
to name that Deployment.
*/}}
{{- define "holmesgpt.holmesFullname" -}}
{{- printf "%s-holmes" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "holmesgpt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "holmesgpt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "holmesgpt.labels" -}}
helm.sh/chart: {{ include "holmesgpt.chart" . }}
app.kubernetes.io/name: {{ include "holmesgpt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
