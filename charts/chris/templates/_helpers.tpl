{{/*
Expand the name of the chart.
*/}}
{{- define "chris.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "whatever" }}
# .name={{.name}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chris.fullname" -}}
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
{{- define "chris.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chris.labels" -}}
helm.sh/chart: {{ include "chris.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: chris
{{- end }}

{{- define "cube.labels" -}}
{{ include "chris.labels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chris.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chris.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "chris.nats.address" -}}
{{- if .Values.nats.auth.enabled -}}
{{- fail "ChRIS does not work with NATS auth, please set .Values.nats.auth.enabled=false" -}}
{{- end -}}
nats://{{ include "common.names.fullname" .Subcharts.nats }}:{{ .Values.nats.service.ports.client | default 4222 }}
{{- end -}}

{{- define "chris.heart.name" -}}
{{ include "chris.fullname" . }}-heart
{{- end -}}

{{- define "chris.heart.port" -}}
8000
{{- end -}}

{{- define "chris.heart.appName" -}}
{{ include "chris.name" . }}-heart
{{- end -}}

{{- define "chris.heart.matcher" -}}
app.kubernetes.io/name: {{ include "chris.heart.appName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
pfdcm stuff
--------------------------------------------------------------------------------
*/}}

{{- define "pfdcm.version" -}}
{{ .Values.pfdcm.image.tag }}
{{- end }}
{{- define "pfdcm.listenerVersion" -}}
{{ .Values.pfdcm.listener.image.tag }}
{{- end }}
{{- define "pfdcm.labels" -}}
{{ include "chris.labels" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ include "pfdcm.version" . | quote }}
app.kubernetes.io/component: pfdcm
{{- end }}
{{- define "pfdcm.listenerLabels" -}}
{{ include "chris.labels" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ include "pfdcm.listenerVersion" . | quote }}
app.kubernetes.io/component: backend
{{- end }}

{{- define "pfdcm.listenerService" -}}
{{ .Release.Name }}-oxidicom
{{- end -}}

{{/*
Helper function to use a value. If the value is unset, try looking up the previous value
from a secret. If the secret does not exist, generate a random value with a specified length.
*/}}
{{- define "valueOrLookupOrRandom" -}}
{{- if .value -}}
  {{- .value | b64enc | quote -}}
{{- else -}}
  {{- $length := .length | default 32 -}}
  {{- $name := .name -}}
  {{- if (not $name) -}}
    {{- fail (printf "valueOrLookupOrRandom was not called with required parameter 'name'. Given parameters: %s" (keys .)) -}}
  {{- end -}}
  {{- with (lookup "v1" "Secret" .root.Release.Namespace .secret) -}}
    {{- if (hasKey .data $name) -}}
      {{- (index .data $name) | quote -}}
    {{- else -}}
      {{- randAlphaNum $length | b64enc | quote -}}
    {{- end -}}
  {{- else -}}
    {{- randAlphaNum $length | b64enc | quote -}}
  {{- end -}}
{{- end -}}
{{- end -}}
