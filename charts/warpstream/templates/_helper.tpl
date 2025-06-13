{{/*
Expand the name of the chart.
*/}}
{{- define "warpstream.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "warpstream.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "warpstream.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "warpstream.labels" -}}
helm.sh/chart: {{ include "warpstream.chart" . }}
{{ include "warpstream.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "warpstream.selectorLabels" -}}
app.kubernetes.io/name: {{ include "warpstream.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "warpstream.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "warpstream.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
WarpStream agent roles as comma-separated string
*/}}
{{- define "warpstream.roles" -}}
{{- join "," .Values.warpstream.agent.roles }}
{{- end }}

{{/*
WarpStream command args
*/}}
{{- define "warpstream.args" -}}
- "agent"
{{- if .Values.warpstream.storage.bucketURL }}
- "-bucketURL"
- {{ .Values.warpstream.storage.bucketURL | quote }}
{{- end }}
- "-defaultVirtualClusterID"
- {{ .Values.warpstream.agent.virtualClusterId | quote }}
- "-region"
- {{ .Values.warpstream.agent.region | quote }}
{{- if .Values.warpstream.agent.agentPoolId }}
- "-agentPoolID"
- {{ .Values.warpstream.agent.agentPoolId | quote }}
{{- end }}
- "-roles"
- {{ include "warpstream.roles" . | quote }}
{{- end }}
