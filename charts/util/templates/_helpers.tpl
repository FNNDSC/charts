{{/*
Expand the name of the chart.
*/}}
{{- define "util.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "util.fullname" -}}
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
{{- define "util.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "util.labels" -}}
helm.sh/chart: {{ include "util.chart" . }}
{{ include "util.selectorLabels" . }}
{{- with (default .Chart.AppVersion .appVersion) }}
app.kubernetes.io/version: {{ quote . }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "util.selectorLabels" -}}
app.kubernetes.io/name: {{ include "util.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "util.topLabels" -}}
{{- mustMergeOverwrite (include "util.labels" . | fromYaml) .Values.labels | toYaml }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "util.serviceAccountName" -}}
{{- if ((.Values).serviceAccount).create }}
{{- default (include "util.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "util.image" -}}
{{ if .Values.image.registry }}{{ .Values.image.registry }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag | default .appVersion | default .Chart.AppVersion }}
{{- end -}}

{{- define "util.podSpec" -}}
{{- with (concat (.Values.imagePullSecrets | default (list)) ((.Values.global).imagePullSecrets | default (list)) | mustUniq) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if (or ((.Values).serviceAccount).name ((.Values).serviceAccount).create) }}
serviceAccountName: {{ include "util.util.serviceAccountName" . }}
{{- end }}
{{- with (.Values.podSecurityContext | deepCopy | mustMergeOverwrite (deepCopy ((.Values.global).podSecurityContext | default (dict)))) }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.volumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "util.container" -}}
- image: {{ include "util.image" . }}
  {{- if .containerName }}
  name: {{ .containerName }}
  {{- end }}
  {{- if .Values.image.pullPolicy }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- end }}
  ports:
    - containerPort: {{ .Values.containerPort | default .Values.service.port }}
      {{- if .Values.hostPort }}
      hostPort: {{ .Values.hostPort }}
      {{- end }}
      protocol: TCP
      {{- if .portName }}
      name: {{ .portName }}
      {{- end }}
  {{- if .Values.extraEnv }}
  env:
    {{- range $k, $v := .Values.extraEnv }}
    - name: {{ $k }}
      value: {{ $v | quote }}
    {{- end }}
  {{- end }}
  {{- with .Values.volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
