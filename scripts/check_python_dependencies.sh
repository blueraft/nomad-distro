#!/bin/sh

set -e

working_dir=$(pwd)
project_dir=$(dirname $(dirname $(realpath $0)))

cd $project_dir

# backup
cp requirements.txt requirements.txt.tmp

uv pip compile -q -p 3.11 --python-platform linux --annotation-style=line \
    --extra=plugins \
    --output-file=requirements.txt \
    pyproject.toml

diff requirements.txt.tmp requirements.txt
 
# cleanup
mv requirements.txt.tmp requirements.txt
