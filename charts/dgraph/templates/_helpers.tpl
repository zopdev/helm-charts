{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dgraph.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 -}}
{{- end -}}
{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "dgraph.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 24 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 -}}
{{- end -}}
{{- end -}}
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dgraph.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified data name.
*/}}
{{- define "dgraph.zero.fullname" -}}
{{ template "dgraph.fullname" . }}-zero
{{- end -}}

{{/*
Create a default fully qualified data name.
*/}}
{{- define "dgraph.backups.fullname" -}}
{{ template "dgraph.fullname" . }}-{{ .Values.backups.name }}
{{- end -}}

{{/*
Create a semVer/calVer version from image.tag so that it can be safely use in
version comparisions used to toggle features or behavior.
*/}}
{{- define "dgraph.version" -}}
{{- $safeVersion := "v24.0.5" -}}
{{- if (eq $safeVersion "shuri") -}}
  {{- $safeVersion = "v20.07.1" -}}
{{- else if  (regexMatch "^[^v].*" $safeVersion) -}}
  {{- $safeVersion = "v50.0.0" -}}
{{- end -}}
{{- printf "%s" $safeVersion -}}
{{- end -}}


{{/*
Return the backups image name
*/}}
{{- define "dgraph.backups.image" -}}
{{- $registryName := .Values.backups.image.registry -}}
{{- $repositoryName := .Values.backups.image.repository -}}
{{- $tag := .Values.backups.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}

{{/*
Return the ratel image name
*/}}
{{- define "dgraph.ratel.image" -}}
{{- $registryName := .Values.ratel.image.registry -}}
{{- $repositoryName := .Values.ratel.image.repository -}}
{{- $tag := .Values.ratel.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}


{{/*
Return empty string if minio keys are not defined
*/}}
{{- define "dgraph.backups.keys.minio.enabled" -}}
{{- $minioEnabled := "" -}}
{{- $backupsEnabled := or .Values.backups.full.enabled .Values.backups.incremental.enabled }}
{{- if $backupsEnabled -}}
  {{- if .Values.backups.keys -}}
    {{- if .Values.backups.keys.minio -}}
      {{- if and .Values.backups.keys.minio.access .Values.backups.keys.minio.secret -}}
        {{- $minioEnabled = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $minioEnabled -}}
{{- end -}}

{{/*
Return empty string if s3 keys are not defined
*/}}
{{- define "dgraph.backups.keys.s3.enabled" -}}
{{- $s3Enabled := "" -}}
{{- $backupsEnabled := or .Values.backups.full.enabled .Values.backups.incremental.enabled }}
{{- if $backupsEnabled -}}
  {{- if .Values.backups.keys -}}
    {{- if .Values.backups.keys.s3 -}}
      {{- if and .Values.backups.keys.s3.access .Values.backups.keys.s3.secret -}}
        {{- $s3Enabled = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $s3Enabled -}}
{{- end -}}

{{/*
Return the initContainers image name
*/}}
{{- define "dgraph.initContainers.init.image" -}}
{{- $registryName := .Values.alpha.initContainers.init.image.registry -}}
{{- $repositoryName := .Values.alpha.initContainers.init.image.repository -}}
{{- $tag := .Values.alpha.initContainers.init.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}

{{/*
Return the proper image name (for the metrics image)
*/}}
{{- define "dgraph.image" -}}
{{- $registryName := "docker.io" -}}
{{- $repositoryName := "dgraph/dgraph" -}}
{{- $tag := "v24.0.5" -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}

{{/*
Create a default fully qualified alpha name.
*/}}
{{- define "dgraph.alpha.fullname" -}}
{{ template "dgraph.fullname" . }}-alpha
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "dgraph.serviceAccountName" -}}
{{- default (include "dgraph.fullname" .) "dgraph" }}
{{- end }}

{{/*
Create a default fully qualified ratel name.
*/}}
{{- define "dgraph.ratel.fullname" -}}
{{ template "dgraph.fullname" . }}-{{ .Values.ratel.name }}
{{- end -}}

{{/*
Allow overriding namespace
*/}}
{{- define "dgraph.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}
