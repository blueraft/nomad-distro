#!/bin/sh

set -e

working_dir=$(pwd)
project_dir=$(dirname $(dirname $(realpath $0)))

cd $project_dir


uv pip compile --universal --annotation-style=line \
    --upgrade-package nomad-lab \
    --extra=plugins \
    --output-file=requirements.txt \
    pyproject.toml

