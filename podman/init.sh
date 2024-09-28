#!/usr/bin/env sh
# note: `podman kube play` is not a real Kubernetes API, so some of Helm's features won't work.
# Here we are configuring secrets such as cube.secretKey, pfcon.secretKey, and pman.secretKey
# in a Helm values.yaml file. This is not strictly necessary, but Helm can't perform `lookup`
# so leaving the secrets unset would result in their values being changed each time you run
# `podman kube play --replace ...`

if [ "$(podman info --format '{{ .Host.RemoteSocket.Exists }}')" != 'true' ]; then
  echo "$(tput setaf 1)error$(tput sgr0): podman socket must be active for pman."
  if systemctl is-system-running > /dev/null 2>&1; then
    echo "try running:"
    echo
    echo "    systemctl --user start podman.service"
    echo
  fi
  exit 1
fi

function random_secret () {
  head /dev/urandom | tr -dc A-Za-z0-9 | head -c "${1:-60}"
}

function random_password () {
  if type apg > /dev/null 2>&1; then
    apg -m 12 -a 0 -n 1 -E "'\\" -M CNL
  else
    random_secret 16
  fi
}

exec cat << EOF
# Helm Chart configuration of fnndsc/chris for use with Podman.
# This file contains secrets!
#
# Hints:
# - uncomment \`hostPort\` to expose a port
# - adjust the values for \`cpu\` and \`memory\` as necessary

chris_admin:
  username: admin
  email: noreply@example.org

cube:
  secrets:
    CHRIS_SUPERUSER_PASSWORD: '$(random_secret 24)'  # randomly generated, change if you want to
    SECRET_KEY: '$(random_secret 32)'  # randomly generated, no need to change
  workerMains:
    resources:
      requests: &WORKER_MAINS_REQUESTS
        memory: 1Gi
        cpu: 1
      limits: *WORKER_MAINS_REQUESTS
  workerPeriodic:
    requests: &WORKER_PERIODIC_REQUESTS
      memory: 1Gi
      cpu: 1
    limits: *WORKER_PERIODIC_REQUESTS
  server:
    hostPort: 8000
    requests: &SERVER_REQUESTS
      memory: 1Gi
      cpu: 1
    limits: *SERVER_REQUESTS

# Bitnami Subcharts
# resourcesPreset options: nano, micro, small, medium, large, xlarge, 2xlarge
# see https://github.com/bitnami/charts/blob/973a2792e0bc5967e3180c6d44eebf223b9f1d83/bitnami/common/templates/_resources.tpl#L15-L43

postgresql:
  primary:
    resourcesPreset: large
    persistence:
      enabled: true
      size: 4Gi
  volumePermissions:
    enabled: true

rabbitmq:
  auth:
    username: 'chris'
    password: '$(random_secret 32)'  # randomly generated, no need to change
  persistence:
    enabled: true
    size: 1Gi
  volumePermissions:
    enabled: true
  resourcesPreset: small

pfcon:
  enabled: true
  name: podman_host
  description: "podman host compute resource"
  password: '$(random_secret 32)'  # randomly generated, no need to change
  # hostPort: 5005
  storage:
    size: 100Gi
  pfcon:
    secretKey: '$(random_secret 32)'  # randomly generated, no need to change
    resources:
      requests: &PFCON_REQUESTS
        cpu: 500m
        memory: 1Gi
      limits: *PFCON_REQUESTS
  pman:
    secretKey: '$(random_secret 32)'  # randomly generated, no need to change
    podman:
      enabled: true
      socket: $(podman info --format '{{ .Host.RemoteSocket.Path }}')
    # hostPort: 5010
    securityContext:
      # Let SELinux allow us to access the Podman socket
      # https://unix.stackexchange.com/a/595152
      seLinuxOptions:
        type: spc_t
    resources:
      requests: &PMAN_REQUESTS
        cpu: 500m
        memory: 1Gi
      limits: *PMAN_REQUESTS

pfdcm:
  enabled: true
  aet: 'ChRIS'
  maxWorkers: 4
  resources:
    requests: &PFDCM_REQUESTS
      cpu: 1
      memory: 2Gi
    limits: *PFDCM_REQUESTS
  listener:
    # hostPort: 11111
    config:
      listenerThreads: 8
      tokioThreads: 4
      logging: oxidicom=info
      promiscuous: true
    resources:
      # It's written in Rust!
      requests: &OXIDICOM_REQUESTS
        cpu: 250m
        memory: 256Mi
      limits: *OXIDICOM_REQUESTS

orthanc:
  enabled: true
  hostPort: 8042
  dicomHostPort: 4242
  resources:
    requests: &ORTHANC_REQUESTS
      cpu: 1
      memory: 1Gi
    limits: *ORTHANC_REQUESTS
  config:
    name: Orthanc in Podman
    dicomAet: "ORTHANCPODMAN"  
    authenticationEnabled: true
    registeredUsers:
      chris: '$(random_password)'  # randomly generated, change if you want
    dicomModalities:
      'ChRIS': [ 'ChRIS', 'chris-oxidicom', 11111 ]
  ohif:
    enabled: true
  persistence:
    storage:
      size: 64Gi
    index:
      size: 4Gi
EOF
