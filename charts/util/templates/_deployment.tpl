{{- define "util.deploymentTpl" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "util.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "util.topLabels" . | nindent 4 }}
  {{- with .Values.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "util.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "util.labels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      containers:
        {{- include "util.container" (mustMerge (dict "containerName" (default (include "util.name" .) .containerName) "portName" "http") .) | nindent 8 }}
      {{- include "util.podSpec" . | nindent 6 }}
{{- end }}
