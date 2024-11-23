{{- /* A template for CUBE deployments. */ -}}
{{- define "cube.deployment" -}}
{{- $appName := (printf "%s-%s" (include "chris.name" .) (.name | required "name is a required parameter of cube.deployment helper function.")) -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chris.fullname" . }}-{{ .name }}
  namespace: {{ .Release.Namespace }}
  labels: &LABELS_{{ .name }}
    app.kubernetes.io/name: {{ $appName }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    {{- include "cube.labels" . | nindent 4 }}
  {{- with .description }}
  annotations:
    kubernetes.io/description: {{ quote . }}
  {{- end }}
spec:
  replicas: {{ .replicas | default 1 }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $appName }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      {{- with .podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels: *LABELS_{{ .name }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      initContainers:
        {{- include "cube.waitServerReady" . | nindent 8 }}
      containers:
        - name: {{ .name }}
          command:
            {{- .command | required "command is a required parameter of the cube.deployment helper function." | toYaml | nindent 12 }}
          resources:
            {{- .resources | required "resources is a required parameter of the cube.deployment helper function." | toYaml | nindent 12 }}
          {{- if .httpPort }}
          ports:
            - name: http
              containerPort: {{ .httpPort }}
              {{- if .hostPort }}
              hostPort: {{ .hostPort }}
              {{- end }}
          {{- end }}
          {{- with .livenessProbe }}
          livenessProbe:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          {{- include "cube.container" . | nindent 10 }}
      {{- include "cube.pod" . | nindent 6 }}
      {{- include "cube.podAffinityWorkaround" . | nindent 6 }}
{{- end -}}
