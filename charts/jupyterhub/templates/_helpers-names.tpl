{{- define "jupyterhub.fullname" -}}
    {{- printf "%s-jupyterhub" .Release.Name }}
{{- end }}


{{- define "jupyterhub.fullname.dash" -}}
    {{- printf "%s-jupyterhub" .Release.Name }}
{{- end }}


{{- define "jupyterhub.hub.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}hub
{{- end }}

{{- define "jupyterhub.hub-serviceaccount.fullname" -}}
    {{ include "jupyterhub.hub.fullname" . }}-sa
{{- end }}

{{- /* hub PVC */}}
{{- define "jupyterhub.hub-pvc.fullname" -}}
    jupyterhub-db-dir
{{- end }}

{{- /* proxy Deployment */}}
{{- define "jupyterhub.proxy.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}proxy
{{- end }}

{{- /* proxy-api Service */}}
{{- define "jupyterhub.proxy-api.fullname" -}}
    {{- include "jupyterhub.proxy.fullname" . }}-api
{{- end }}

{{- /* proxy-http Service */}}
{{- define "jupyterhub.proxy-http.fullname" -}}
    {{- include "jupyterhub.proxy.fullname" . }}-http
{{- end }}

{{- /* proxy-public Service */}}
{{- define "jupyterhub.proxy-public.fullname" -}}
    jupyterhub-public
{{- end }}

{{- /* proxy-public-tls Secret */}}
{{- define "jupyterhub.proxy-public-tls.fullname" -}}
    {{- include "jupyterhub.proxy-public.fullname" . }}-tls-acme
{{- end }}

{{- /* proxy-public-manual-tls Secret */}}
{{- define "jupyterhub.proxy-public-manual-tls.fullname" -}}
    {{- include "jupyterhub.proxy-public.fullname" . }}-manual-tls
{{- end }}

{{- /* autohttps Deployment */}}
{{- define "jupyterhub.autohttps.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}autohttps
{{- end }}

{{- /* autohttps-serviceaccount ServiceAccount */}}
{{- define "jupyterhub.autohttps-serviceaccount.fullname" -}}
    {{- printf "%s-sa" (include "jupyterhub.autohttps.fullname" .) }}
{{- end }}

{{- /* user-scheduler Deployment */}}
{{- define "jupyterhub.user-scheduler-deploy.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}user-scheduler
{{- end }}

{{- /* user-scheduler-serviceaccount ServiceAccount */}}
{{- define "jupyterhub.user-scheduler-serviceaccount.fullname" -}}
    {{- printf "%s-sa" (include "jupyterhub.user-scheduler-deploy.fullname" .) }}
{{- end }}

{{- /* user-scheduler leader election lock resource */}}
{{- define "jupyterhub.user-scheduler-lock.fullname" -}}
    {{- include "jupyterhub.user-scheduler-deploy.fullname" . }}-lock
{{- end }}

{{- /* user-placeholder StatefulSet */}}
{{- define "jupyterhub.user-placeholder.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}user-placeholder
{{- end }}

{{- /* image-awaiter Job */}}
{{- define "jupyterhub.hook-image-awaiter.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}hook-image-awaiter
{{- end }}

{{- /* image-awaiter-serviceaccount ServiceAccount */}}
{{- define "jupyterhub.hook-image-awaiter-serviceaccount.fullname" -}}
    {{- include "jupyterhub.hook-image-awaiter.fullname" . }}-sa
{{- end }} 


{{- /* hook-image-puller DaemonSet */}}
{{- define "jupyterhub.hook-image-puller.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}hook-image-puller
{{- end }}

{{- /* hook-image-puller ServiceAccount */}}
{{- define "jupyterhub.hook-image-puller-serviceaccount.fullname" -}}
    {{- include "jupyterhub.hook-image-puller.fullname" . }}-sa
{{- end }} 

{{- /* continuous-image-puller DaemonSet */}}
{{- define "jupyterhub.continuous-image-puller.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}continuous-image-puller
{{- end }}

{{- /* continuous-image-puller ServiceAccount */}}
{{- define "jupyterhub.continuous-image-puller-serviceaccount.fullname" -}}
    {{- include "jupyterhub.continuous-image-puller.fullname" . }}-sa
{{- end }} 

{{- /* singleuser NetworkPolicy */}}
{{- define "jupyterhub.singleuser.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}singleuser
{{- end }}

{{- /* image-pull-secret Secret */}}
{{- define "jupyterhub.image-pull-secret.fullname" -}}
    {{- include "jupyterhub.fullname.dash" . }}image-pull-secret
{{- end }}

{{- /* Ingress */}}
{{- define "jupyterhub.ingress.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.fullname" . }}
    {{- else -}}
        jupyterhub
    {{- end }}
{{- end }}





{{- /* Priority */}}
{{- define "jupyterhub.priority.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.fullname" . }}
    {{- else }}
        {{- .Release.Name }}-default-priority
    {{- end }}
{{- end }}

{{- /* user-placeholder Priority */}}
{{- define "jupyterhub.user-placeholder-priority.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.user-placeholder.fullname" . }}
    {{- else }}
        {{- .Release.Name }}-user-placeholder-priority
    {{- end }}
{{- end }}

{{- /* image-puller Priority */}}
{{- define "jupyterhub.image-puller-priority.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.fullname.dash" . }}image-puller
    {{- else }}
        {{- .Release.Name }}-image-puller-priority
    {{- end }}
{{- end }}

{{- /* user-scheduler's registered name */}}
{{- define "jupyterhub.user-scheduler.fullname" -}}
    {{- if (include "jupyterhub.fullname" .) }}
        {{- include "jupyterhub.user-scheduler-deploy.fullname" . }}
    {{- else }}
        {{- .Release.Name }}-user-scheduler
    {{- end }}
{{- end }}



{{- /*
    A template to render all the named templates in this file for use in the
    hub's ConfigMap.

    It is important we keep this in sync with the available templates.
*/}}
{{- define "jupyterhub.name-templates" -}}
fullname: {{ include "jupyterhub.fullname" . | quote }}
fullname-dash: {{ include "jupyterhub.fullname.dash" . | quote }}
hub: {{ include "jupyterhub.hub.fullname" . | quote }}
hub-serviceaccount: {{ include "jupyterhub.hub-serviceaccount.fullname" . | quote }}
hub-pvc: {{ include "jupyterhub.hub-pvc.fullname" . | quote }}
proxy: {{ include "jupyterhub.proxy.fullname" . | quote }}
proxy-api: {{ include "jupyterhub.proxy-api.fullname" . | quote }}
proxy-http: {{ include "jupyterhub.proxy-http.fullname" . | quote }}
proxy-public: {{ include "jupyterhub.proxy-public.fullname" . | quote }}
proxy-public-tls: {{ include "jupyterhub.proxy-public-tls.fullname" . | quote }}
proxy-public-manual-tls: {{ include "jupyterhub.proxy-public-manual-tls.fullname" . | quote }}
autohttps: {{ include "jupyterhub.autohttps.fullname" . | quote }}
autohttps-serviceaccount: {{ include "jupyterhub.autohttps-serviceaccount.fullname" . | quote }}
user-scheduler-deploy: {{ include "jupyterhub.user-scheduler-deploy.fullname" . | quote }}
user-scheduler-serviceaccount: {{ include "jupyterhub.user-scheduler-serviceaccount.fullname" . | quote }}
user-scheduler-lock: {{ include "jupyterhub.user-scheduler-lock.fullname" . | quote }}
user-placeholder: {{ include "jupyterhub.user-placeholder.fullname" . | quote }}
image-puller-priority: {{ include "jupyterhub.image-puller-priority.fullname" . | quote }}
hook-image-awaiter: {{ include "jupyterhub.hook-image-awaiter.fullname" . | quote }}
hook-image-awaiter-serviceaccount: {{ include "jupyterhub.hook-image-awaiter-serviceaccount.fullname" . | quote }}
hook-image-puller: {{ include "jupyterhub.hook-image-puller.fullname" . | quote }}
hook-image-puller-serviceaccount: {{ include "jupyterhub.hook-image-puller-serviceaccount.fullname" . | quote }}
continuous-image-puller: {{ include "jupyterhub.continuous-image-puller.fullname" . | quote }}
continuous-image-puller-serviceaccount: {{ include "jupyterhub.continuous-image-puller-serviceaccount.fullname" . | quote }}
singleuser: {{ include "jupyterhub.singleuser.fullname" . | quote }}
image-pull-secret: {{ include "jupyterhub.image-pull-secret.fullname" . | quote }}
ingress: {{ include "jupyterhub.ingress.fullname" . | quote }}
priority: {{ include "jupyterhub.priority.fullname" . | quote }}
user-placeholder-priority: {{ include "jupyterhub.user-placeholder-priority.fullname" . | quote }}
user-scheduler: {{ include "jupyterhub.user-scheduler.fullname" . | quote }}
{{- end }}
