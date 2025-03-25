{{/*
Expand the name of the chart.
*/}}
{{- define "orthanc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "orthanc.fullname" -}}
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
{{- define "orthanc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "orthanc.labels" -}}
helm.sh/chart: {{ include "orthanc.chart" . }}
{{ include "orthanc.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "orthanc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "orthanc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with .Values.commonLabels }}
  {{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "orthanc.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "orthanc.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "orthanc.bucket-name" -}}
{{- include "orthanc.fullname" . -}}-obc
{{- end }}


{{- define "orthanc.service-labels" }}
{{- include "orthanc.labels" . }}
{{- with .Values.service.labels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{- define "orthanc.encryption-secret" }}
{{- if (and
  .Values.config.AwsS3Storage.StorageEncryption.Enable
  (eq (toString .Values.config.AwsS3Storage.StorageEncryption.MasterKey) "auto")
) -}}
{{- include "orthanc.fullname" . -}}-encryption
{{- end }}
{{- end }}

{{- define "orthanc.request-cpu-cores" -}}
{{- $cpu := .Values.resources | default (dict) | dig "requests" "cpu" "undefined" }}
{{- if (has (typeOf $cpu) (list "int" "int64" "float64")) }}
{{- max $cpu 1 }}
{{- else if (hasSuffix "m" $cpu) }}
{{- div (trimSuffix "m" $cpu) 1000 | max 1 }}
{{- end }}
{{- end }}

{{- define "orthanc.crunchy-secret" -}}
{{- if .Values.crunchyPgo.enabled -}}
{{- include "orthanc.fullname" . -}}-pguser-{{- get (mustFirst .Values.crunchyPgo.spec.users) "name" -}}
{{- end -}}
{{- end -}}


{{- define "orthanc.prometheus-label-escape" }}
{{- range $k, $v := . }}
{{ mustRegexReplaceAllLiteral "[-/\\.]" $k "_" }}: {{ quote $v }}
{{- end }}
{{- end }}
