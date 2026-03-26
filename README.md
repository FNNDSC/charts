# ![logo](./charts/chris/logo_chris.png) FNNDSC Helm Charts

[![Release](https://github.com/FNNDSC/charts/actions/workflows/release.yml/badge.svg)](https://github.com/FNNDSC/charts/actions/workflows/release.yml)
[![Test ChRIS and pfcon](https://github.com/FNNDSC/charts/actions/workflows/test-chris.yml/badge.svg)](https://github.com/FNNDSC/charts/actions/workflows/test-chris.yml)
[![Unit Tests](https://github.com/FNNDSC/charts/actions/workflows/test-unit.yml/badge.svg)](https://github.com/FNNDSC/charts/actions/workflows/test-unit.yml)

Helm charts for the [FNNDSC](https://fnndsc.org) and the [_ChRIS_ Project](https://chrisproject.org).

## List of Charts

| Chart Name     | License | Chart Version | App Version | Description |
|----------------|---------|---------------|-------------|-------------|
| `fnndsc/chris` | MIT |![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fchris%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fchris%2FChart.yaml&query=%24.appVersion&label=appVersion) | Open-source platform for medical compute. |
| `fnndsc/pfcon` | MIT | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fpfcon%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fpfcon%2FChart.yaml&query=%24.appVersion&label=appVersion) | Standalone remote compute resource service for _ChRIS_ backend. |
| `fnndsc/orthanc` | GPLv3+ | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Forthanc%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Forthanc%2FChart.yaml&query=%24.appVersion&label=appVersion) | Open-source PACS server. https://www.orthanc-server.com/ |
| `fnndsc/ohif` | MIT | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fohif%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fohif%2FChart.yaml&query=%24.appVersion&label=appVersion) | Web DICOM viewer. https://ohif.org/ |
| `fnndsc/linkerd-nodeport-workaround` | MIT | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Flinkerd-nodeport-workaround%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Flinkerd-nodeport-workaround%2FChart.yaml&query=%24.appVersion&label=appVersion) | Workaround for using [Linkerd](https://linkerd.io) with NodePort services. |

## Development

If you already have Docker installed, the easiest way to obtain k8s is [KinD](https://kind.sigs.k8s.io/).
KinD installation instructions are here: https://kind.sigs.k8s.io/docs/user/quick-start/

TODO: add instructions for testing in KinD.

### Editing Dependent Charts

The _pfcon_ and _chris_ charts are both defined here in the same repo, and
_pfcon_ is a chart dependency of _chris_. When you want to make local
modifications to _pfcon_ and want to try them out in conjunction with the
_chris_ chart, you need to do a workaround. Otherwise, `helm` will want to pull
_pfcon_ from "prod" instead of looking at your local development copy.

`justfile` implements a workaround by running an OCI registry on `localhost`.

1. In `./charts/chris/Chart.yaml` replace `https://fnndsc.github.io/charts`
   with `oci://localhost:5000/fnndsc/charts/pfcon`
2. Run `just refresh`
3. Do your local trying
4. When you're ready, run `just replace` before you `git commit`
5. Lastly, clean up by running `just down`

#### Publishing Changes to _pfcon_

1. Increase `version` in `charts/pfcon/Chart.yaml` and push to `dev` branch
2. Use a PR to merge `dev` into `master`
3. After the release for pfcon is created by GitHub Actions, increase the
   version and _pfcon_ dependency version in `charts/chris/Chart.yaml`
4. Run `helm dependency update charts/chris`
5. Commit and push to `dev`, then make a PR to merge `dev` into `master`

