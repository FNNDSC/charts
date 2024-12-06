{{/*
CUBE file storage
--------------------------------------------------------------------------------
In the default configuration, pfcon is configured as "innetwork" and CUBE uses
the volume managed by the pfcon subchart for file storage.
If pfcon is not enabled or not configured as "innetwork" then CUBE needs to create
its own PVC.
*/}}

{{- define "cube.useOwnVolume" -}}
{{- if (and .Values.pfcon.enabled .Values.pfcon.pfcon.config.innetwork) -}}
{{- /* no (empty value) */ -}}
{{- else -}}
yes
{{- end }}
{{- end }}

{{- define "cube.wasUsingOwnVolume" -}}
{{- with (lookup "v1" "PersistentVolumeClaim" .Release.Namespace ( print .Release.Name "-cube-files")) -}}
yes
{{- end -}}
{{- end -}}

{{- define "cube.filesVolume" -}}
{{- /*
      Validators to check that you aren't self-destructive.

      You should never:
      - enable "innetwork pfcon" where previously it wasn't
      - disable "innetwork pfcon" where it previously was
*/ -}}
{{- if      (and .Release.IsUpgrade (eq "yes" (include "cube.wasUsingOwnVolume" .)) (ne "yes" (include "cube.useOwnVolume" .)))  -}}
{{- fail "Cannot set pfcon.enabled=true and/or pfcon.pfcon.config.innetwork=true now because CUBE is using its own PersistentVolumeClaim for storage." -}}
{{- else if (and .Release.IsUpgrade (ne "yes" (include "cube.wasUsingOwnVolume" .)) (eq "yes" (include "cube.useOwnVolume" .)))  -}}
{{- fail "Cannot set pfcon.enabled=false and/or pfcon.pfcon.config.innetwork=false now because CUBE currently depends on pfcon configured in \"innetwork\" mode for storage." -}}
{{- else if (include "cube.useOwnVolume" .) -}}
{{- /* will be created by ./storage.yml */ -}}
{{ .Release.Name }}-cube-files
{{- else -}}
{{- /* defined in ../../pfcon/templates/storage.yml */ -}}
{{ .Release.Name }}-storebase
{{- end }}
{{- end }}

{{- define "cube.db.secret" -}}
{{- if .Values.postgresSecret.name -}}
{{- .Values.postgresSecret.name -}}
{{- else if .Values.postgresql.enabled -}}
{{ .Release.Name }}-postgresql-svcbind-custom-user
{{- else -}}
{{- fail "postgresSecret.name cannot be unset because postgresql.enabled=false" -}}
{{- end -}}
{{- end -}}

{{- define "cube.image" -}}
{{ .Values.cube.image.repository }}:{{ .Values.cube.image.tag | default .Chart.AppVersion }}
{{- end -}}
{{- define "cube.container" -}}
image: {{ include "cube.image" . }}
imagePullPolicy: {{ .Values.cube.image.pullPolicy }}
volumeMounts:
  - mountPath: /data
    name: file-storage
envFrom:
  - configMapRef:
      name: {{ .Release.Name }}-cube-config
  - secretRef:
      name: {{ .Release.Name }}-chris-backend
env:
  {{- $dbenvs := (dict
    "POSTGRES_DB"       (include "chris.db.secretItemKey" (dict "Values" .Values "name" "database" "crunchyName" "dbname"))
    "POSTGRES_USER"     (include "chris.db.secretItemKey" (dict "Values" .Values "name" "username" "crunchyName" "user"))
    "POSTGRES_PASSWORD" (include "chris.db.secretItemKey" (dict "Values" .Values "name" "password" "crunchyName" "password"))
    "DATABASE_HOST"     (include "chris.db.secretItemKey" (dict "Values" .Values "name" "host"     "crunchyName" "host"))
    "DATABASE_PORT"     (include "chris.db.secretItemKey" (dict "Values" .Values "name" "port"     "crunchyName" "port"))
  ) }}
  {{- $secretName := include "cube.db.secret" . }}
  {{- range $name, $key := $dbenvs }}
  - name: {{ $name }}
    valueFrom:
      secretKeyRef:
        name: {{ $secretName }}
        key: {{ $key }}
  {{- end }}
  - name: CELERY_BROKER_URL
    valueFrom:
      secretKeyRef:
        name: {{ .Release.Name }}-rabbitmq-svcbind
        key: uri
  {{- range $name, $val := .moreEnv }}
  - name: {{ $name }}
    valueFrom:
      {{ get $val "valueFrom" }}:
        name: {{ get $val "name" }}
        key: {{ get $val "key" }}
  {{- end }}
{{- end }}

{{- /* Helper function to get the name of an item of a key. If unspecified in Values, use a default name
       where the default may be different for Crunchy PGO. */}}
{{- define "chris.db.secretItemKey" }}
{{- get .Values.postgresSecret.keys .name | default (ternary .crunchyName .name .Values.postgresSecret.isCrunchy) -}}
{{- end }}

{{- define "cube.pod" -}}
volumes:
  - name: file-storage
    persistentVolumeClaim:
      claimName: {{ include "cube.filesVolume" . }}
{{- if .Values.global.podSecurityContext }}
securityContext:
  {{- toYaml .Values.global.podSecurityContext | nindent 2 }}
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

{{- /*
Since the server deployment is the one which defines the database migrations, everything else
should start after the server. It's ok for ancillary services to be started late.
*/ -}}
{{- define "cube.waitServerReady" -}}
- name: wait-for-server
  image: quay.io/prometheus/busybox:latest
  command: ["/bin/sh", "-c"]
  args: ["until wget --spider 'http://{{ include "chris.heart.name" . }}:{{ include "chris.heart.port" . }}/api/v1/users/'; do sleep 5; done"]
{{- end }}

