#!/bin/bash

cd "$(dirname "$0")/.."

[[ ! -d libs ]] && mkdir -p libs
[[ ! -L libs/LibContainer ]] && ln -s ../LibContainer libs/LibContainer
