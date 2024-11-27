{{- define "util.knativeServiceTpl" }}
apiVersion: serving.knative.dev/v1
kind: Service
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
  template:
    metadata:
      {{- with .Values.revisionAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.podLabels }}
      labels:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- if .Values.containerConcurrency }}
      containerConcurrency: {{ .Values.containerConcurrency }}
      {{- end }}
      containers:
        {{- include "util.container" . | nindent 8 }}
      {{- mustMerge (omit . "Values") (dict "Values" (omit .Values "startupProbe")) | include "util.podSpec" | nindent 6 }}
{{- end }}
