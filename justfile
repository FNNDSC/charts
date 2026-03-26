prefix := "oci://localhost:5000/fnndsc/charts/"
actual := "https://fnndsc.github.io/charts"

refresh: install-pre-commit
    @just list-local-charts | xargs -n 1 just push

list-local-charts:
    @yq '.dependencies[] | .repository | select(test("{{ prefix }}")) | sub("{{ prefix }}", "")' ./charts/chris/Chart.yaml

push name: registry
    helm package ./charts/{{ name }}
    helm push ./{{ name }}-*.tgz oci://localhost:5000/fnndsc/charts/{{ name }}
    rm ./{{ name }}-*.tgz

registry:
    @status="$(podman container inspect -f '{{{{ .State.Status }}' registry 2> /dev/null)"; \
    if [ "$?" != '0' ]; then   \
      just registry-run;       \
    elif [ "$status" != 'running' ]; then \
      just registry-start;     \
    fi

registry-start:
    podman start registry

registry-run:
    podman run --name registry -d -p 5000:5000 ghcr.io/distribution/distribution:3

down:
    podman rm -f registry

replace:
    for file in ./charts/*/Chart.{lock,yaml}; do \
      sed -i 's#{{ prefix }}.*#{{ actual }}#' "$file"; \
    done

[working-directory(".git/hooks")]
install-pre-commit:
    @rm -r pre-commit
    @ln -s ../../hooks/pre-commit.sh pre-commit
