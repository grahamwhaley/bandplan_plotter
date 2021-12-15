#!/bin/sh
#
# Copyright Graham Whaley (M7GRW)
#
# SPDX-License-Identifier: CC-BY-4.0
#
# Script that runs inside the docker container to build the
# default set of bandplans

set -x
set -ev

# Build the default - which is the RSGB HF set
Rscript /data/plot.R
Rscript /data/plot.R rsgb_uvhf
