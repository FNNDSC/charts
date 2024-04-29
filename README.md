# ![logo](./charts/chris/logo_chris.png) FNNDSC Helm Charts

[![MIT License](https://img.shields.io/github/license/fnndsc/charts)](https://github.com/FNNDSC/charts/blob/main/LICENSE)
[![Release](https://github.com/FNNDSC/charts/actions/workflows/release.yml/badge.svg)](https://github.com/FNNDSC/charts/actions/workflows/release.yml)
[![Test ChRIS and pfcon](https://github.com/FNNDSC/charts/actions/workflows/test-chris.yml/badge.svg)](https://github.com/FNNDSC/charts/actions/workflows/test-chris.yml)
[![Test Orthanc](https://github.com/FNNDSC/charts/actions/workflows/test-orthanc.yml/badge.svg)](https://github.com/FNNDSC/charts/actions/workflows/test-orthanc.yml)

Helm charts for the [FNNDSC](https://fnndsc.org) and the [_ChRIS_ Project](https://chrisproject.org).

## List of Charts

| Chart Name     | License | Chart Version | App Version | Description |
|----------------|---------|---------------|-------------|-------------|
| `fnndsc/chris` | MIT |![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fchris%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fchris%2FChart.yaml&query=%24.appVersion&label=appVersion) | Open-source platform for medical compute. |
| `fnndsc/pfcon` | MIT | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fpfcon%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fpfcon%2FChart.yaml&query=%24.appVersion&label=appVersion) | Standalone remote compute resource service for _ChRIS_ backend. |
| `fnndsc/orthanc` | GPLv3+ | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Forthanc%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Forthanc%2FChart.yaml&query=%24.appVersion&label=appVersion) | Open-source PACS server. https://www.orthanc-server.com/ |
| `fnndsc/ohif` | MIT | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fohif%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fohif%2FChart.yaml&query=%24.appVersion&label=appVersion) | Web DICOM viewer. https://ohif.org/ |
| `fnndsc/linkerd-nodeport-workaround` | MIT | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Flinkerd-nodeport-workaround%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Flinkerd-nodeport-workaround%2FChart.yaml&query=%24.appVersion&label=appVersion) | Workaround for using [Linkerd](https://linkerd.io) with NodePort services. |
| `fnndsc/chris-ui` | MIT | ![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fchris-ui%2FChart.yaml&query=%24.version&label=version) | ![Version](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FFNNDSC%2Fcharts%2Fmaster%2Fcharts%2Fchris-ui%2FChart.yaml&query=%24.appVersion&label=appVersion) | Web Frontend UI for _ChRIS_. |

## Development

If you already have Docker installed, the easiest way to obtain k8s is [KinD](https://kind.sigs.k8s.io/).
KinD installation instructions are here: https://kind.sigs.k8s.io/docs/user/quick-start/

Development scripts are defined in `testing/justfile`, which uses the [just](https://github.com/casey/just) syntax.
You should install `just`: https://github.com/casey/just#installation

Then you can run things like:

```shell
git switch dev
helm dependency update ./charts/chris

cd testing

just kind
just up
just wait
just test
```

Optionally, to use [_chrisomatic_](https://github.com/FNNDSC/chrisomatic):

```shell
just chrisomatic
```

Then, graceful tear down:

```shell
just down
just unkind
```

### Making Modifications

Editing _pfcon_'s templates can be tricky because it's a dependency from the same repo as _chris_.
Here's a workaround:

```shell
cd charts/chris/charts
rm ./pfcon-*.tgz
ln -sv ../../pfcon
```

To publish your changes, increase `version` in `charts/pfcon/Chart.yaml` then merge the `dev`
branch into `master`. Once the release is created by GitHub Actions, increase the `version` and
_pfcon_ dependency version in `charts/chris/Chart.yaml` then update `charts/chris/Chart.lock` by running

```shell
cd charts/chris
rm charts/pfcon
helm dependency update .
```

Finally, push to master once more.

### Observability

Optionally, a Kubernetes observability stack can be deployed into the Kind cluster.
You can choose between OpenObserve or a Grafana-based stack.

#### OpenObserve

OpenObserve is much more efficient than Grafana. I also have log collection set up for OpenObserve.
However, OpenObserve's visualization and data querying is not as good as Grafana. It is recommended
to use OpenObserve if you (a) need to aggregate and search through logs, and/or (b) your workstation
has less than or equal to 8 CPUs, 16GB RAM.

Logs are collected using [Vector](https://vector.dev/) and visualized using [OpenObserve](https://openobserve.ai/).
To run the observability stack and open the dashboard, run

```shell
just openobserve
```

Log in with the email `dev@babymri.org` password `chris1234`.

Alternatively, you can get logs from the command-line using the `just olog [POD_NAME_LABEL]` command.
Examples:

```shell
just olog pfcon

just olog chris-heart
```

##### How It Works

Two releases of Vector are made:

- "Agent" mode which runs on every node to collect logs and host metrics
- "Stateless-Aggregator" which scrapes Kubelet `/metrics/cadvisor`

These logs and metrics are shipped to OpenObserve.

#### Prometheus Stack

TODO
