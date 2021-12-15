#!/bin/bash
#
# Copyright Graham Whaley (M7GRW)
#
# SPDX-License-Identifier: CC-BY-4.0
#
# Build the required docker image from the dockerfile that has all the
# R parts we need to build the bandplan images

set -x

docker build --label "bandplan_plotter" --tag "bandplan_plotter" dockerfile
