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
app.kubernetes.io/instance: {{ .Release.Name }}
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

{{- define "orthanc.firstRegisteredUsername" -}}
{{- if .Values.config.registeredUsers -}}
{{- keys .Values.config.registeredUsers | first -}}
{{- end }}
{{- end }}
{{- define "orthanc.firstRegisteredPassword" -}}
{{- if (include "orthanc.firstRegisteredUsername" .) -}}
{{- get .Values.config.registeredUsers (include "orthanc.firstRegisteredUsername" .) -}}
{{- end }}
{{- end }}
