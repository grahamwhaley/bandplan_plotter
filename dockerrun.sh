#!/bin/bash
#
# Copyright Graham Whaley (M7GRW)
#
# SPDX-License-Identifier: CC-BY-4.0
#
# Run the docker image and execute the build script to build
# the bandplan images

set -x

docker run --rm -it \
    -v $(pwd):/data \
    bandplan_plotter data/build.sh
