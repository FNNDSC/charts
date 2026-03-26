#!/usr/bin/env bash

g="$(grep oci://localhost charts/*/Chart.{yaml,lock})"
if [ -n "$g" ]; then
  echo "Error: some charts depend on the local registry."
  echo "$g"
  exit 1
fi

