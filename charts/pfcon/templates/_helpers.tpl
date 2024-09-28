{{/*
Expand the name of the chart.
*/}}
{{- define "pfcon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pfcon.fullname" -}}
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
{{- define "pfcon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pfcon.labels" -}}
helm.sh/chart: {{ include "pfcon.chart" . }}
{{ include "pfcon.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: chris
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pfcon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pfcon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pfcon.serviceAccountName" -}}
{{- default (include "pfcon.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{- define "pfcon.storebase" -}}
{{ .Values.storage.existingClaim | default (printf "%s-storebase" .Release.Name) }}
{{- end }}

{{/*
Helper function to use a value. If the value is unset, try looking up the previous value
from a secret. If the secret does not exist, generate a random value with a specified length.
*/}}
{{- define "pfcon.valueOrLookupOrRandom" -}}
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
