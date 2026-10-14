{{/*
Fully qualified name of the MongoDB server: <release>-mongodb, capped for DNS.
*/}}
{{- define "mongodb.fullname" -}}
{{- printf "%s-mongodb" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of the Secret holding the generated root password.
*/}}
{{- define "mongodb.rootSecretName" -}}
{{- printf "%s-mongodb-root-secret" .Release.Name -}}
{{- end -}}

{{- define "mongodb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
