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

# backup
cp requirements.txt requirements.txt.tmp

uv pip compile -q --universal --annotation-style=line \
    --extra=plugins \
    --output-file=requirements.txt \
    pyproject.toml

diff requirements.txt.tmp requirements.txt
 
# cleanup
mv requirements.txt.tmp requirements.txt
