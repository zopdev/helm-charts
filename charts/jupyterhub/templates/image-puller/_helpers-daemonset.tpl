{{- /*
Returns an image-puller daemonset. Two daemonsets will be created like this.
- hook-image-puller: for pre helm upgrade image pulling (lives temporarily)
- continuous-image-puller: for newly added nodes image pulling
*/}}
{{- define "jupyterhub.imagePuller.daemonset" -}}
apiVersion: apps/v1
kind: DaemonSet
metadata:
  {{- if .hook }}
  name: {{ include "jupyterhub.hook-image-puller.fullname" . }}
  {{- else }}
  name: {{ include "jupyterhub.continuous-image-puller.fullname" . }}
  {{- end }}
  labels:
    {{- include "jupyterhub.labels" . | nindent 4 }}
    {{- if .hook }}
    hub.jupyter.org/deletable: "true"
    {{- end }}
  {{- if .hook }}
  annotations:
    {{- /*
    Allows the daemonset to be deleted when the image-awaiter job is completed.
    */}}
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    "helm.sh/hook-weight": "-10"
  {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "jupyterhub.matchLabels" . | nindent 6 }}
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 100%
  {{- if not (typeIs "<nil>" .Values.prePuller.revisionHistoryLimit) }}
  revisionHistoryLimit: {{ .Values.prePuller.revisionHistoryLimit }}
  {{- end }}
  template:
    metadata:
      labels:
        {{- include "jupyterhub.matchLabelsLegacyAndModern" . | nindent 8 }}
      {{- with .Values.prePuller.annotations }}
      annotations:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
    spec:
      {{- /*
        image-puller pods are made evictable to save on the k8s pods
        per node limit all k8s clusters have and have a higher priority
        than user-placeholder pods that could block an entire node.
      */}}
      {{- if include "jupyterhub.userNodeAffinityRequired" . }}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              {{- include "jupyterhub.userNodeAffinityRequired" . | nindent 14 }}
      {{- end }}
      terminationGracePeriodSeconds: 0
      {{- if .hook }}
      {{- with include "jupyterhub.hook-image-puller-serviceaccount.fullname" . }}
      serviceAccountName: {{ . }}
      {{- end }}
      {{- else }}
      {{- with include "jupyterhub.continuous-image-puller-serviceaccount.fullname" . }}
      serviceAccountName: {{ . }}
      {{- end }}
      {{- end }}
      automountServiceAccountToken: false
      initContainers:
        {{- /* --- Conditionally pull an image all user pods will use in an initContainer --- */}}
        {{- $blockWithIptables := hasKey .Values.singleuser.cloudMetadata "enabled" | ternary (not .Values.singleuser.cloudMetadata.enabled) .Values.singleuser.cloudMetadata.blockWithIptables }}
        {{- if $blockWithIptables }}
        - name: image-pull-metadata-block
          image: quay.io/jupyterhub/k8s-network-tools:4.1.1-0.dev.git.6949.h138f95a8
          command:
            - /bin/sh
            - -c
            - echo "Pulling complete"
          securityContext:
            runAsNonRoot: true
            runAsUser: 65534 
            runAsGroup: 65534 
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: "RuntimeDefault"
        {{- end }}

        {{- /* --- Pull default image --- */}}
        - name: image-pull-singleuser
          image: {{ .Values.singleuser.image.name }}:{{ .Values.singleuser.image.tag }}
          command:
            - /bin/sh
            - -c
            - echo "Pulling complete"
          securityContext:
            runAsNonRoot: true
            runAsUser: 65534 
            runAsGroup: 65534 
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: "RuntimeDefault"

      
        {{- /* --- Conditionally pull profileList images --- */}}
        {{- range $k, $container := .Values.singleuser.profileList }}
        {{- /* profile's kubespawner_override */}}
        {{- if $container.kubespawner_override }}
        {{- if $container.kubespawner_override.image }}
        - name: image-pull-singleuser-profilelist-{{ $k }}
          image: {{ $container.kubespawner_override.image }}
          command:
            - /bin/sh
            - -c
            - echo "Pulling complete"
          securityContext:
            runAsNonRoot: true
            runAsUser: 65534 
            runAsGroup: 65534 
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: "RuntimeDefault"
        {{- end }}
        {{- /* kubespawner_override in profile's profile_options */}}
        {{- if $container.profile_options }}
        {{- range $option, $option_spec := $container.profile_options }}
        {{- if $option_spec.choices }}
        {{- range $choice, $choice_spec := $option_spec.choices }}
        {{- if $choice_spec.kubespawner_override }}
        {{- if $choice_spec.kubespawner_override.image }}
        - name: image-pull-profile-{{ $k }}-option-{{ $option }}-{{ $choice }}
          image: {{ $choice_spec.kubespawner_override.image }}
          command:
            - /bin/sh
            - -c
            - echo "Pulling complete"
          securityContext:
            runAsNonRoot: true
            runAsUser: 65534 
            runAsGroup: 65534 
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: "RuntimeDefault"
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}

      containers:
        - name: pause
          image: registry.k8s.io/pause:3.10
          securityContext:
            runAsNonRoot: true
            runAsUser: 65534 # nobody user
            runAsGroup: 65534 # nobody group
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: "RuntimeDefault"
{{- end }}


{{- /*
    Returns a rendered k8s DaemonSet resource: continuous-image-puller
*/}}
{{- define "jupyterhub.imagePuller.daemonset.continuous" -}}
    {{- $_ := merge (dict "hook" false "componentPrefix" "continuous-") . }}
    {{- include "jupyterhub.imagePuller.daemonset" $_ }}
{{- end }}


{{- /*
    Returns a rendered k8s DaemonSet resource: hook-image-puller
*/}}
{{- define "jupyterhub.imagePuller.daemonset.hook" -}}
    {{- $_ := merge (dict "hook" true "componentPrefix" "hook-") . }}
    {{- include "jupyterhub.imagePuller.daemonset" $_ }}
{{- end }}


{{- /*
    Returns a checksum of the rendered k8s DaemonSet resource: hook-image-puller

    This checksum is used when prePuller.hook.pullOnlyOnChanges=true to decide if
    it is worth creating the hook-image-puller associated resources.
*/}}
{{- define "jupyterhub.imagePuller.daemonset.hook.checksum" -}}
    {{- /*
        We pin componentLabel and Chart.Version as doing so can pin labels
        of no importance if they would change. Chart.Name is also pinned as
        a harmless technical workaround when we compute the checksum.
    */}}
    {{- $_ := merge (dict "componentLabel" "pinned" "Chart" (dict "Name" "jupyterhub" "Version" "pinned")) . -}}
    {{- $yaml := include "jupyterhub.imagePuller.daemonset.hook" $_ }}
    {{- $yaml | sha256sum }}
{{- end }}


{{- define "jupyterhub.imagePuller.daemonset.hook.install" -}}
    {{- if .Values.prePuller.hook.enabled }}
        {{- if .Values.prePuller.hook.pullOnlyOnChanges }}
            {{- $new_checksum := include "jupyterhub.imagePuller.daemonset.hook.checksum" . }}
            {{- $k8s_state := lookup "v1" "ConfigMap" .Release.Namespace (include "jupyterhub.hub.fullname" .) | default (dict "data" (dict)) }}
            {{- $old_checksum := index $k8s_state.data "checksum_hook-image-puller" | default "" }}
            {{- if ne $new_checksum $old_checksum -}}
# prePuller.hook.enabled={{ .Values.prePuller.hook.enabled }}
# prePuller.hook.pullOnlyOnChanges={{ .Values.prePuller.hook.pullOnlyOnChanges }}
# post-upgrade checksum != pre-upgrade checksum (of the hook-image-puller DaemonSet)
# "{{ $new_checksum }}" != "{{ $old_checksum}}"
            {{- end }}
        {{- else -}}
# prePuller.hook.enabled={{ .Values.prePuller.hook.enabled }}
# prePuller.hook.pullOnlyOnChanges={{ .Values.prePuller.hook.pullOnlyOnChanges }}
        {{- end }}
    {{- end }}
{{- end }}
