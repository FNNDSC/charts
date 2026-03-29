{{- define "chris.crunchyPgo.secret" -}}
{{- $user := get ($.Values.crunchyPgo.spec.users | mustFirst) "name" -}}
{{ include "chris.fullname" $ }}-pguser-{{ $user }}
{{- end -}}

{{- define "chris.initContainers.wait-db" -}}
{{- if $.Values.crunchyPgo.enabled }}
{{- with (get $.Values.predefinedInitContainers "wait-db") }}
- name: wait-db
  image: {{ .image }}
  command:
    {{- .command | toYaml | nindent 12 }}
  env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: {{ include "chris.crunchyPgo.secret" $ }}
          key: user
    - name: HOST
      valueFrom:
        secretKeyRef:
          name: {{ include "chris.crunchyPgo.secret" $ }}
          key: host
    - name: PORT
      valueFrom:
        secretKeyRef:
          name: {{ include "chris.crunchyPgo.secret" $ }}
          key: port
    - name: DBNAME
      valueFrom:
        secretKeyRef:
          name: {{ include "chris.crunchyPgo.secret" $ }}
          key: dbname

  {{- with .resources }}
  resources:
    {{- . | toYaml | nindent 12 }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "chris.imageEnvAndMounts" -}}
image: {{ $.Values.cube.image.repository }}:{{ $.Values.cube.image.tag | default $.Chart.AppVersion }}
imagePullPolicy: {{ $.Values.cube.image.pullPolicy }}
envFrom:
  - configMapRef:
      name: "{{ include "chris.fullname" $ }}"
  - secretRef:
      name: "{{ include "chris.fullname" $ }}"
  {{- with $.Values.cube.envFrom }}
  {{- toYaml . | nindent 12 }}
  {{- end }}
env:
  {{- if $.Values.crunchyPgo.enabled }}
  - name: DATABASE_HOST
    valueFrom:
      secretKeyRef:
        name: {{ include "chris.crunchyPgo.secret" . }}
        key: host
  - name: DATABASE_PORT
    valueFrom:
      secretKeyRef:
        name: {{ include "chris.crunchyPgo.secret" . }}
        key: port
  - name: POSTGRES_USER
    valueFrom:
      secretKeyRef:
        name: {{ include "chris.crunchyPgo.secret" . }}
        key: user
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "chris.crunchyPgo.secret" . }}
        key: password
  - name: POSTGRES_DB
    valueFrom:
      secretKeyRef:
        name: {{ include "chris.crunchyPgo.secret" . }}
        key: dbname
  {{- end }}
  {{- range $name, $val := (.moreEnv | default (dict)) }}
  - name: {{ $name }}
    value: {{ $val | quote }}
  {{- end }}
  {{- with $.Values.cube.env }}
  {{- toYaml . | nindent 12 }}
  {{- end }}
volumeMounts:
  - mountPath: /data
    name: file-storage
{{- end -}}

{{- define "cube.podSpec" -}}
volumes:
  - name: {{ .volumeName | default "file-storage" }}
    persistentVolumeClaim:
      claimName: {{ include "cube.filesVolume" . }}
serviceAccountName: {{ include "chris.fullname" $ }}
{{- with (mustMergeOverwrite ($.Values.global.podSecurityContext  | default (dict))
                             ($.Values.podSecurityContext         | default (dict))
                             ($.Values.cube.podSecurityContext    | default (dict))
                             (.securityContext                   | default (dict))
          ) }}
securityContext:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- include "cube.podAffinityWorkaround" $ | nindent 6 }}
{{- end -}}

{{- define "cube.deployment" -}}
{{- $appName := (printf "%s-%s" (include "chris.name" $) (.name | required "name is a required parameter of cube.deployment helper function.")) -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chris.fullname" $ }}-{{ .name }}
  namespace: {{ $.Release.Namespace }}
  labels: &LABELS_{{ .name }}
    app.kubernetes.io/name: {{ $appName }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    {{- include "cube.labels" $ | nindent 4 }}
  {{- with .description }}
  annotations:
    kubernetes.io/description: {{ quote . }}
  {{- end }}
spec:
  replicas: {{ .replicas | default 1 }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $appName }}
      app.kubernetes.io/instance: {{ $.Release.Name }}
  template:
    metadata:
      {{- $annotations := (dict
        "kubectl.kubernetes.io/default-container" .name
        "checksum/config" ($.Values.cube.config | mustToJson | sha256sum)
        "checksum/secret" ($.Values.cube.secrets | mustToJson | sha256sum)
      ) }}
      {{- with (.podAnnotations | default (dict) | mustMerge $annotations) }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels: *LABELS_{{ .name }}
    spec:
      {{- with $.Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      initContainers:
        {{- include "chris.initContainers.wait-db" . | nindent 8 }}
        {{- if $.Values.dragonfly.enabled }}
        {{- /* TODO we're just hoping that Redis will be ready.
             * We should properly wait for it to be ready.
             * Example: https://github.com/oauth2-proxy/manifests/blob/336ab5076eb7f9627089ef60462a815837eb060e/helm/oauth2-proxy/templates/deployment.yaml#L75-L78
             */}}
        {{- end }}
        {{- if $.Values.migrate.enabled }}
        {{- with get $.Values.predefinedInitContainers "wait-migrate" }}
        - name: wait-migrate
          image: {{ .image }}
          command:
            - sh
            - -c
            - |
              output="$(kubectl -n {{ $.Release.Namespace }} wait --for=condition=complete jobs/{{ include "chris.migrate-job" $ }})"
              code=$?
              echo "$output"
              if [[ "$output" = *NotFound* ]]; then
                exit 0
              fi
              exit $code
          {{- with .resources }}
          resources:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          {{- end }}
        {{- end }}
      containers:
        - name: {{ .name }}
          command:
            {{- .command | required "command is a required parameter of the cube.deployment helper function." | toYaml | nindent 12 }}
          {{- include "chris.imageEnvAndMounts" $ | nindent 10 }}
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
      {{- include "cube.podSpec" . | nindent 6 }}
{{- end -}}
