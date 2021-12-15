#!/bin/bash
#
# Copyright Graham Whaley (M7GRW)
#
# SPDX-License-Identifier: CC-BY-4.0
#
# Run the docker image up to a shell prompt. This is primarily used
# as a debug/development tool. Once inside the image, execute:
#
#  # R
#  > source('/data/plot.R')
#  > ^D
#  # exit
#

set -x

docker run --rm -it \
    -v $(pwd):/data \
    bandplan_plotter bash
