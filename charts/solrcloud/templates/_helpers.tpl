{{- define "solr.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "solr.fullname" -}}
{{- printf "%s-solrcloud" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "solr.fullname-no-suffix" -}}
{{ include "solr.fullname" . | trimSuffix "-solrcloud" | trimSuffix "-solr" }}
{{- end }}

{{- define "solr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "solr.labels" -}}
helm.sh/chart: {{ include "solr.chart" . }}
{{ include "solr.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{- define "solr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "solr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}