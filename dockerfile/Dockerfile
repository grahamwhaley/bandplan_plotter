# Copyright (c) 2021 Graham Whaley
#
# SPDX-License-Identifier: Apache-2.0
#
# Dockerfile containing all the 'R' needed to process
# the bandplan_plotter script

# Docker 'verse' comes with the publishing tools...
FROM rocker/verse

LABEL DOCKERFILE_VERSION="1.1"

ENV DEBIAN_FRONTEND=noninteractive

# Install some extra R packages
#  Rccp to support ggrepel - requires newer version
RUN install2.r --error --deps TRUE \
	gridExtra \
	ggrepel \
	Rcpp \
	ggtext \
	ggpubr
