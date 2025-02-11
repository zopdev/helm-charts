{{- define "kafka.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kafka.fullname" -}}
{{- printf "%s-kafka" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kafka.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kafka.labels" -}}
helm.sh/chart: {{ include "kafka.chart" . }}
{{ include "kafka.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "kafka.selectorLabels" -}}
app: {{ .Release.Name }}-{{ include "kafka.name" . }}
app.kubernetes.io/name: {{ include "kafka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "kafka.listener" -}}
{{- $namespace := .Release.Namespace }}
{{- printf "${POD_NAME}.%s-headless.%s.svc.cluster.local" (include "kafka.fullname" .) $namespace | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka.bootstrap.server" -}}
{{- $namespace := .Release.Namespace }}
{{- printf "%s-headless" (include "kafka.fullname" .) | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka.zookeeper.fullname" -}}
{{- $name := default "zookeeper" (index .Values "zookeeper" "nameOverride") -}}
{{- printf "%s-%s-headless" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka.zookeeper.ensemble" }}
{{- if (index .Values "zookeeper" "enabled") -}}
{{- $clientPort := default 2181 (index .Values "zookeeper" "port" "client") | int -}}
{{- printf "%s:%d" (include "kafka.zookeeper.fullname" .) $clientPort }}
{{- else -}}
{{- printf "%s" (index .Values "zookeeper" "url") }}
{{- end -}}
{{- end -}}
