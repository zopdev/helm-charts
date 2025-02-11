{{- define "zookeeper.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "zookeeper.fullname" -}}
{{- printf "%s-zookeeper" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "zookeeper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "zookeeper.labels" -}}
helm.sh/chart: {{ include "zookeeper.chart" . }}
{{ include "zookeeper.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "zookeeper.selectorLabels" -}}
app: {{ .Release.Name }}-{{ include "zookeeper.name" . }}
app.kubernetes.io/name: {{ include "zookeeper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "zookeeper.serverlist" -}}
{{- $namespace := .Release.Namespace }}
{{- $name := include "zookeeper.fullname" . -}}
{{- $peersPort := .Values.port.peers -}}
{{- $leaderElectionPort := .Values.port.leader -}}
{{- $zk := dict "servers" (list) -}}
{{- range $idx, $v := until (int .Values.replicaCount) }}
{{- $noop := printf "%s-%d.%s-headless.%s.svc.cluster.local:%d:%d" $name $idx $name $namespace (int $peersPort) (int $leaderElectionPort) | append $zk.servers | set $zk "servers" -}}
{{- end }}
{{- printf "%s" (join ";" $zk.servers) | quote -}}
{{- end -}}