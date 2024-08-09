#!/bin/sh

set -e

working_dir=$(pwd)
project_dir=$(dirname $(dirname $(realpath $0)))

cd $project_dir


uv pip compile -p 3.11 --python-platform linux --annotation-style=line \
    --extra=plugins \
    --output-file=requirements.txt \
    pyproject.toml

