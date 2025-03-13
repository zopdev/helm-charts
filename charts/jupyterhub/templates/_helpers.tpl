{{- define "jupyterhub.appLabel" -}}
{{ .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}


{{- define "jupyterhub.componentLabel" -}}
{{- $file := .Template.Name | base | trimSuffix ".yaml" -}}
{{- $parent := .Template.Name | dir | base | trimPrefix "templates" -}}
{{- $component := .componentLabel | default $parent | default $file -}}
{{- $component := print (.componentPrefix | default "") $component (.componentSuffix | default "") -}}
{{ $component }}
{{- end }}


{{- define "jupyterhub.commonLabels" -}}
{{- if .legacyLabels -}}
app: {{ .appLabel | default (include "jupyterhub.appLabel" .) | quote }}
release: {{ .Release.Name | quote }}
{{- if not .matchLabels }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
heritage: {{ .Release.Service }}
{{- end }}
{{- end }}
{{- if and .legacyLabels .modernLabels -}}
{{ printf "\n" }}
{{- end }}
{{- if .modernLabels -}}
app.kubernetes.io/name: {{ .appLabel | default (include "jupyterhub.appLabel" .) | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- if not .matchLabels }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{- end }}
{{- end }}


{{- /*
  jupyterhub.labels:
    Provides labels conditionally on .legacyLabels, .modernLabels, and .matchLabels,
    that are supposed to in the scoped passed this helper function.

    The legacy labels are:
      component
      app
      release
      chart (omitted for matchLabels)
      heritage (omitted for matchLabels)

    The equivalent modern labels are:
      app.kubernetes.io/component
      app.kubernetes.io/name
      app.kubernetes.io/instance release
      helm.sh/chart (omitted for matchLabels)
      app.kubernetes.io/managed-by (omitted for matchLabels)
*/}}
{{- define "jupyterhub.labels" -}}
{{- /*
  .legacyLabels defaults to true
  .modernLabels defaults to false
*/ -}}
{{- $_ := . -}}
{{- if typeIs "<nil>" .legacyLabels -}}
{{- $_ = merge (dict "legacyLabels" true) $_ -}}
{{- end -}}
{{- if typeIs "<nil>" .modernLabels -}}
{{- $_ = merge (dict "modernLabels" true) $_ -}}
{{- end -}}

{{- if $_.legacyLabels -}}
component: {{ include "jupyterhub.componentLabel" . }}
{{- end }}

{{- if and $_.legacyLabels $_.modernLabels -}}
{{ printf "\n" }}
{{- end }}

{{- if $_.modernLabels -}}
app.kubernetes.io/component: {{ include "jupyterhub.componentLabel" . }}
{{- end }}
{{ include "jupyterhub.commonLabels" $_ }}
{{- end }}


{{- /*
  jupyterhub.matchLabels:
    Provides legacy labels:
      component
      app
      release
*/}}
{{- define "jupyterhub.matchLabels" -}}
{{- $_ := merge (dict "matchLabels" true "legacyLabels" true "modernLabels" false) . -}}
{{ include "jupyterhub.labels" $_ }}
{{- end }}


{{- /*
  jupyterhub.matchLabelsModern:
    Provides modern labels:
      app.kubernetes.io/component
      app.kubernetes.io/name
      app.kubernetes.io/instance
*/}}
{{- define "jupyterhub.matchLabelsModern" -}}
{{- $_ := merge (dict "matchLabels" true "legacyLabels" false "modernLabels" true) . -}}
{{ include "jupyterhub.labels" $_ }}
{{- end }}


{{- /*
  jupyterhub.matchLabelsLegacyAndModern:
    Provides legacy and modern labels:
      component
      app
      release
      app.kubernetes.io/component
      app.kubernetes.io/name
      app.kubernetes.io/instance
*/}}
{{- define "jupyterhub.matchLabelsLegacyAndModern" -}}
{{- $_ := merge (dict "matchLabels" true "legacyLabels" true "modernLabels" true) . -}}
{{ include "jupyterhub.labels" $_ }}
{{- end }}


{{- /*
  jupyterhub.dockerconfigjson:
    Creates a base64 encoded docker registry json blob for use in a image pull
    secret, just like the `kubectl create secret docker-registry` command does
    for the generated secrets data.dockerconfigjson field. The output is
    verified to be exactly the same even if you have a password spanning
    multiple lines as you may need to use a private GCR registry.

    - https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod
*/}}
{{- define "jupyterhub.dockerconfigjson" -}}
{{ include "jupyterhub.dockerconfigjson.yaml" . | b64enc }}
{{- end }}

{{- /*
  jupyterhub.imagePullSecrets
    Augments passed .pullSecrets with $.Values.imagePullSecrets
*/}}

{{- define "jupyterhub.imagePullSecrets" -}}
    {{- $jupyterhub_values := .root.Values }}
    
    {{- if ne .root.Chart.Name "jupyterhub" }}
        {{- if .root.Values.jupyterhub }}
            {{- $jupyterhub_values = .root.Values.jupyterhub }}
        {{- end }}
    {{- end }}

    {{- /* Initialize $_ as an empty dictionary to store values */}}
    {{- $_ := dict }}
    {{- $_ = set $_ "list" $jupyterhub_values.hub.imagePullSecrets | default list }}

    {{- /* Decide if something should be written */}}
    {{- if not (eq ($_.list | toJson) "[]") }}

        {{- /* Process the $_.list where strings become dicts with a name key */}}
        {{- $_ = set $_ "res" list }}
        {{- range $_.list }}
            {{- if eq (typeOf .) "string" }}
                {{- $_ = set $_ "res" (append $_.res (dict "name" .)) }}
            {{- else }}
                {{- $_ = set $_ "res" (append $_.res .) }}
            {{- end }}
        {{- end }}

        {{- /* Write the results */}}
        {{- $_.res | toJson }}

    {{- end }}
{{- end }}

{{- /*
  jupyterhub.singleuser.resources:
    The resource request of a singleuser.
*/}}
{{- define "jupyterhub.singleuser.resources" -}}
{{- $r1 :=  "" -}}
{{- $r2 := "1G" -}}
{{- $r3 := "" -}}
{{- $r := or $r1 $r2 $r3 -}}
{{- $l1 := "" -}}
{{- $l2 := "" -}}
{{- $l3 := "" -}}
{{- $l := or $l1 $l2 $l3 -}}
{{- if $r -}}
requests:
  {{- if $r1 }}
  cpu: {{ "" }}
  {{- end }}
  {{- if $r2 }}
  memory: {{ "1G" }}
  {{- end }}
{{- end }}

{{- if $l }}
limits:
  {{- if $l1 }}
  cpu: {{ "" }}
  {{- end }}
  {{- if $l2 }}
  memory: {{ "" }}
  {{- end }}
{{- end }}
{{- end }}

{{- /*
  jupyterhub.extraEnv:
    Output YAML formatted EnvVar entries for use in a containers env field.
*/}}
{{- define "jupyterhub.extraEnv" -}}
{{- include "jupyterhub.extraEnv.withTrailingNewLine" . | trimSuffix "\n" }}
{{- end }}

{{- define "jupyterhub.extraEnv.withTrailingNewLine" -}}
{{- if . }}
{{- /* If extraEnv is a list, we inject it as it is. */}}
{{- if eq (typeOf .) "[]interface {}" }}
{{- . | toYaml }}

{{- /* If extraEnv is a map, we differentiate two cases: */}}
{{- else if eq (typeOf .) "map[string]interface {}" }}
{{- range $key, $value := . }}
{{- /*
    - If extraEnv.someKey has a map value, then we add the value as a YAML
      parsed list element and use the key as the name value unless its
      explicitly set.
*/}}
{{- if eq (typeOf $value) "map[string]interface {}" }}
{{- merge (dict) $value (dict "name" $key) | list | toYaml | println }}
{{- /*
    - If extraEnv.someKey has a string value, then we use the key as the
      environment variable name for the value.
*/}}
{{- else if eq (typeOf $value) "string" -}}
- name: {{ $key | quote }}
  value: {{ $value | quote | println }}
{{- else }}
{{- printf "?.extraEnv.%s had an unexpected type (%s)" $key (typeOf $value) | fail }}
{{- end }}
{{- end }} {{- /* end of range */}}
{{- end }}
{{- end }} {{- /* end of: if . */}}
{{- end }} {{- /* end of definition */}}

{{- /*
  jupyterhub.chart-version-to-git-ref:
    Renders a valid git reference from a chartpress generated version string.
    In practice, either a git tag or a git commit hash will be returned.

    - The version string will follow a chartpress pattern, see
      https://github.com/jupyterhub/chartpress#examples-chart-versions-and-image-tags.

    - The regexReplaceAll function is a sprig library function, see
      https://masterminds.github.io/sprig/strings.html.

    - The regular expression is in golang syntax, but \d had to become \\d for
      example.
*/}}
{{- define "jupyterhub.chart-version-to-git-ref" -}}
{{- regexReplaceAll ".*[.-]n\\d+[.]h(.*)" . "${1}" }}
{{- end }}
