# Orthanc Helm Chart

A [Helm](https://helm.sh/) Chart for deploying [Orthanc](https://orthanc.uclouvain.be/) on [Kubernetes](https://kubernetes.io/) or [OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift).

## Features

- Configure `orthanc.json` in YAML instead of JSON.
- Automatic configuration of settings which are related to the Kubernetes pod spec.
  - E.g. if unspecified, the value for `ConcurrentJobs` will be set depending on
    the value of `resources.requests.cpu` converted to number of cores.
- Integrated with the [CrunchyData Postgres Operator](https://github.com/CrunchyData/postgres-operator)
  and the [ObjectBucketClaim](https://rook.io/docs/rook/v1.10/Storage-Configuration/Object-Storage-RGW/ceph-object-bucket-claim/) CRD
  (available on OpenShift as _Red Hat OpenShift Container Storage_ via NooBaa) for a cloud-native, highly-scalable deployment.
  - These integrations are optional. Using a SQLite index and filesystem storage are both supported with filesystem-type PersistentVolumes.
- Automatic setup of client-side S3 object storage encryption.
- Optionally enable [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) as a subchart for single-sign-on (SSO).
- Unit-tested using [helm-unittest](https://github.com/helm-unittest/helm-unittest).
- Default UI is [Orthanc Explorer 2](https://orthanc.uclouvain.be/book/plugins/orthanc-explorer-2.html) with dark theme.

## Quickstart

```shell
helm repo add fnndsc https://fnndsc.github.io/charts
helm repo update fnndsc
helm show values fnndsc/orthanc > values.yaml
helm upgrade --install orthanc fnndsc/orthanc -f values.yaml
```

Alternatively, see our production Helmfile example here:
https://github.com/FNNDSC/NERC/blob/ebfe519f23bc83e49b5bdd75e1bb1b9890811cba/blt/helmfile.d/03-orthanc.yaml

## Alternatives

[Korthweb](https://github.com/digihunch/korthweb) is the first result which comes up when you google "Orthanc" + "Helm".
The [features](#features) section above lists advantages of `fnndsc/orthanc` which are not implemented with korthweb.

