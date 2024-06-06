#!/bin/sh

# For now we exclude the following dependencies, because they import an older version
# of nomad-lab causing inevitable conflicts.
#    dependencies/parsers/atomistic/pyproject.toml \
#    dependencies/parsers/database/pyproject.toml \
#    dependencies/parsers/electronic/pyproject.toml \
#    dependencies/parsers/workflow/pyproject.toml \

set -e

working_dir=$(pwd)
project_dir=$(dirname $(dirname $(realpath $0)))

cd $project_dir


uv pip compile -p 3.9 --annotation-style=line \
    --extra=plugins \
    --output-file=requirements.txt \
    pyproject.toml

uv pip compile -p 3.9 --annotation-style=line \
    --extra=dev --extra=plugins \
    --output-file=requirements-dev.txt \
    requirements.txt \
    pyproject.toml

