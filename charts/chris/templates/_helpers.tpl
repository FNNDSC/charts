{{/*
Expand the name of the chart.
*/}}
{{- define "chris.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
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
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: chris
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "chris.chart" . }}
{{- end }}

{{- define "cube.labels" -}}
{{ include "chris.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{- define "chris.migrate-job" -}}
{{- include "chris.fullname" . -}}-migrate-{{ .Release.Revision }}
{{- end -}}

{{- define "chris.migrate-observer" -}}
{{- include "chris.fullname" . -}}-migrate-observer
{{- end -}}

{{- define "chris.nats.address" -}}
{{- /* TODO NATS was removed. */}}
{{- /* NATS_ADDRESS must be set, even if NATS is disabled/not used. */}}
nats://this.is.a.placeholder
{{- end -}}

{{- define "cube.useOwnVolume" -}}
  {{- if (and .Values.pfcon.enabled .Values.pfcon.config.innetwork) -}}
    {{- /* no (empty value) */ -}}
  {{- else -}}
    yes
  {{- end }}
{{- end }}

{{- define "cube.filesVolume" -}}
  {{- if (include "cube.useOwnVolume" .) -}}
    {{- /* will be created by ./storage.yml */ -}}
    {{- include "chris.fullname" . -}}
  {{- else -}}
  {{- /* defined in ../../pfcon/templates/storage.yml */ -}}
    {{ .Release.Name }}-storebase
  {{- end }}
{{- end }}

{{- define "cube.podAffinityWorkaround" -}}
{{ if .Values.cube.enablePodAffinityWorkaround }}
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/instance
            operator: In
            values:
            - {{ .Release.Name }}
          {{- /* if CUBE is using its own volume, pods should be attracted to heart. Otherwise, pods should be attracted to pfcon. */}}
          - key: app.kubernetes.io/name
            operator: In
            values:
            - {{ if (include "cube.useOwnVolume" .) }}{{ include "chris.heart.appName" . }}{{ else }}pfcon{{ end }}
        topologyKey: kubernetes.io/hostname
{{- end }}
{{- end }}

{{/*
pfdcm stuff
--------------------------------------------------------------------------------
*/}}

{{- define "chris.pfdcmInternalAddress" -}}
  {{- if (not (and .Values.pfdcm.enabled)) -}}
    http://this.is.a.placeholder
  {{- else if (eq .Values.pfdcm.kind "Deployment") -}}
    http://{{ include "pfdcm.fullname" . }}:{{ .Values.pfdcm.service.port }}
  {{- else -}}
    http://{{ include "pfdcm.fullname" . }}.{{ .Release.Namespace }}.svc
  {{- end -}}
{{- end -}}

