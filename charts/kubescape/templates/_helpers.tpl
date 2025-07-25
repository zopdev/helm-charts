{{/*
Expand the name of the chart.
*/}}
{{- define "kubescape.name" -}}
{{- default .Chart.Name (.Values.nameOverride | default "") | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kubescape.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name (.Values.nameOverride | default "") }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubescape.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubescape.labels" -}}
helm.sh/chart: {{ include "kubescape.chart" . }}
{{ include "kubescape.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubescape.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubescape.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubescape.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubescape.fullname" .) (.Values.serviceAccount.name | default "") }}
{{- else }}
{{- default "default" (.Values.serviceAccount.name | default "") }}
{{- end }}
{{- end }}
