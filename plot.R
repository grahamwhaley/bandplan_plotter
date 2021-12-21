#!/usr/bin/env Rscript
#
# Copyright Graham Whaley (M7GRW)
#
# SPDX-License-Identifier: CC-BY-4.0
#
# An R script that reads in a set of csv/markdown data files that describe the
# frequencies, subdivisions and annotations of radio amateur frequency bands,
# and turns them into a visual bandplan diagram.

version="v1.2"

library(ggplot2)					# ability to plot nicely.
library(tidyverse)
suppressMessages(suppressWarnings(library(tidyr)))	# for gather().
							# So we can plot multiple graphs
library(gridExtra)					# to arrange plots
library(grid)						# to arrange plots
library(ggrepel)					# repelling text labels
library(ggtext)						# rich text boxes
library(ggpubr)						# text grobs

options(scipen=10000) # Turn off scientific notation - do we need to?

# We take one optional argument - the name of the data subdir to process
args=commandArgs(trailingOnly=TRUE)

if( !exists("inputdir") ) {
	if( length(args) > 0 ) inputdir=args[1]
}

# If we don't have a preset inputdir then default to the rsgb hf band data
inputdir = ifelse( exists("inputdir"), inputdir, "rsgb_hf")

# Construct the filenames
band_file = paste("/data/", inputdir, "/bands.csv", sep="")
zone_file = paste("/data/", inputdir, "/zones.csv", sep="")
tags_file = paste("/data/", inputdir, "/tags.csv", sep="")
colour_file = paste("/data/", inputdir, "/colours.csv", sep="")
title_file = paste("/data/", inputdir, "/title.md", sep="")

# Build a title bar describing the dataset name/description, the version and date etc.
titledf <- data.frame(
	label = c(
		"<sub>M7GRW</sub>\n\n<sup>Check RSGB bandplans for precise details</sup>",
		read_file(title_file),
		paste(format(Sys.time(), "%b %d %Y"), version, sep=" ")
	),
	x = c(0, 0.5, 1),
	y = c(0, 0, 0),
	hjust = c("left", "middle", "right")
)

# Try to get the three elements left/centre/right.
# The numbers look a bit screwy, but the visual looks OK
# I had difficulty trying to vary text sizes and alignments using markdown adjustments,
# so right now I'm leaving this as is.
titlex = c(0, 0.5, 0.75)
titley = c(0.25, 0.75, 0.5)

# Load up the data
band_data <- read_csv(band_file, comment="#")
zone_data <- read_csv(zone_file, comment="#")
tags_data <- read_csv(tags_file, comment="#")
colour_data <- read_csv(colour_file, comment="#")

# Flatten the tibble colour data into a named vector as required
# by the scale_xx_colour functions
flatcolour = unlist(colour_data[1,])
names(flatcolour) = names(colour_data)

# Initialise the 'all the plots' list to be empty
allplots = list()

# Generate our title graph
title_gg <- ggplot(titledf) +
	aes(x, y, label=label, hjust=hjust) +
	geom_richtext(fill=NA, label.colour=NA)

# Drop all border elements as we don't want them. This was hard to find. Code from:
# https://stackoverflow.com/questions/31254533/when-using-ggplot-in-r-how-do-i-remove-margins-surrounding-the-plot-area/31255346#31255346
title_gg = title_gg + theme(
	panel.background = element_rect(fill = "transparent", colour = NA),
	plot.background = element_rect(fill = "transparent", colour = NA),
	panel.grid = element_blank(),
	panel.border = element_blank(),
	plot.margin = unit(c(0, 0, 0, 0), "null"),
	panel.margin = unit(c(0, 0, 0, 0), "null"),
	axis.ticks = element_blank(),
	axis.text = element_blank(),
	axis.title = element_blank(),
	axis.line = element_blank(),
	legend.position = "none",
	axis.ticks.length = unit(0, "null"),
	axis.ticks.margin = unit(0, "null"),
	legend.margin = unit(0, "null")
  	)

allplots[[length(allplots)+1]] <- title_gg

# If you want to add a separate Legend (colour index) to the chart, between the titles and
# the first graph, then 'uncomment' this code. I tried to find a way to merge a nice small
# legend into the title text, but failed.
# It's a bit larger than I'd like and squashes the graphs even more, so for now it is off by
# default.
if(FALSE) {
	temp_legend_gg = ggplot(zone_data) +
		geom_segment(size=1, aes(x=start_freq, xend=end_freq, y=1, yend=1, colour=type)) +
		scale_fill_manual(values=flatcolour) +
		theme(legend.position="bottom")
	legend_gg = get_legend(temp_legend_gg)
	allplots[[length(allplots)+1]] <- legend_gg
}

# Process the bands one at a time...
for( row in 1:nrow(band_data)) {
	alldata = c()

	# Work out the 'range' of this band
	thisband <- band_data[row,]
	lowfreq <- thisband$start_freq
	highfreq <- thisband$end_freq
	notes <- thisband$notes

	# Not every field has a notes entry - NULL them out so we don't write 'emtpy'
	# into the graph
	if (is.na(notes)) notes=NULL

	# Find all the zones that fit in this band
	zones <- filter(zone_data, start_freq >= lowfreq & end_freq <= highfreq)

	# For all the zones, annotate them with the band and add them to the global
	# data table
	for( z in 1:nrow(zones)) {
		r <- tibble(band=thisband$name, zones[z,])
		alldata <- bind_rows(alldata, r)
	}

	alldata$mid_freq = (alldata$start_freq + alldata$end_freq)/2

	# Find all the tags that fit in that band
	tags <- filter(tags_data, start_freq >= lowfreq & end_freq <= highfreq)
	if (nrow(tags) > 0 ) {
		tags <- cbind(tags, annotation=paste(tags$name, sep="\n", tags$start_freq))
	}

	# Work out how many 'bars' we have in this plot, so we can work out where to draw
	# our tickmarks etc.
	nbars = length(unique(alldata$type))

	# And finally generate the plot for this band...
	bandplot <- ggplot() +
		# Plot the actual 'zones'. We alpha them so the zone labels show through later
		geom_segment(data=alldata, alpha=0.5, aes(color=type, x=start_freq, xend=end_freq, y=type, yend=type), lwd=3) +
		# Expand the graph area so we can inject the POI and tickmarks
		expand_limits(y=c(-1, nbars+4)) +	# set the height of the graph area
		# Generate the Y axis label, including the notes
                labs(y=paste(thisband$name, notes, sep="\n"), x=NULL, label=NULL) +
		# Disable the default x/y ticks, as they can only be on the graph edges
		theme(axis.ticks.y=element_blank(), axis.text.y=element_blank()) +
		theme(axis.ticks.x=element_blank(), axis.text.x=element_blank()) +
		# Use our colours
		scale_colour_manual(values=flatcolour) +
		scale_fill_manual(values=flatcolour) +
		# Draw the zone names (CW, SSB etc.) into the relevant zones
		geom_text_repel(data=alldata, min.segment.length=0.1, size=2.5, aes(x=mid_freq, y=type, label=type))

	# Draw our homebrew xaxis tickmarks
	xticks = tibble()
	# Try to work out a 'nice' human friendly 'step' for major ticks...
	trysteps=c(1, 5, 10, 25, 50, 100, 250, 500, 1000)
	freqrange = highfreq - lowfreq

	for( trystep in trysteps)  {
		teststep = freqrange / trystep

		# Use the smallest step value we can that gives us 10 or less
		# major subdivisions
		if ( teststep <= 10 ) {
			xstep = trystep
			break
		}
	}

	# We 'round' in order to find the 'nice' boundaries for the x axis tickmarks
	# in case the band boundaries do not align nicely with the calculated tick
	# steps
	roundlowfreq = ( as.integer((lowfreq+(xstep-1))/xstep) ) * xstep
	roundhighfreq = as.integer(highfreq/xstep) * xstep

	# Draw larger ticks on the larger 'step' boundaries
	xticks = tibble(x=as.integer(seq(roundlowfreq, roundhighfreq, xstep)))
	# And draw subticks as '5ths' of them
	subxticks = tibble(x=as.integer(seq(roundlowfreq, roundhighfreq, xstep/5)))
	# Ensure we also draw the high and low frequencies if they do not align perfectly
	# on the calculated 'nice' steps
	xticks = add_row(xticks, x=lowfreq)
	xticks = add_row(xticks, x=highfreq)

	# dedup, in case the low or highfreq fall exactly on a seq calculated tick, which
	# is quite common.
	xticks = xticks[!duplicated(xticks$x),]

	# And add the X axis to the graph
	bandplot = bandplot +
		# Draw tickmark base line. 
		geom_segment(size=1, aes(x=lowfreq, xend=highfreq, y=nbars+1, yend=nbars+1)) +
		# Add text labels for the major tickmarks, which also includes the start/end of
		# the bands. I tried quite hard to get these nicely centred on the ticks whilst
		# also repelling so the few close end-of-band conditions did not overlap, but
		# the best I could get was with the text to the left of the ticks.
		geom_text_repel(data=xticks, size=3, direction="x", force_pull=10, hjust=0, aes(x=x, y=-0.25, label=x)) +
		geom_segment(data=subxticks, size=1, aes(x=x, xend=x, y=nbars+1, yend=nbars+2)) +
		geom_segment(data=xticks, size=1, aes(x=x, xend=x, y=0, yend=nbars+2))
	

	# If we have tags then draw them. Try to stop them overlapping, and draw little lines to show
	# where the freq. they represent is.
	if (nrow(tags) > 0 ) {
		bandplot = bandplot + geom_label_repel(data=tags, size=2, nudge_y=2, min.segment.length=0, aes(x=start_freq, y=nbars+1, label=annotation))
	}

	# Drop all border elements, apart from lhs Y name. This was hard to find. Code from:
	#https://stackoverflow.com/questions/31254533/when-using-ggplot-in-r-how-do-i-remove-margins-surrounding-the-plot-area/31255346#31255346
	# Some of this might be a bit old and out of date, but it works...
	bandplot = bandplot + theme(
		panel.background = element_rect(fill = "transparent", colour = NA),
		plot.background = element_rect(fill = "transparent", colour = NA),
		panel.grid = element_blank(),
		panel.border = element_blank(),
		plot.margin = unit(c(0, 0, 0, 0), "null"),
		panel.margin = unit(c(0, 0, 0, 0), "null"),
		axis.ticks = element_blank(),
		axis.text = element_blank(),
		axis.title.x = element_blank(),
		axis.line = element_blank(),
		legend.position = "none",
		axis.ticks.length = unit(0, "null"),
		axis.ticks.margin = unit(0, "null"),
		legend.margin = unit(0, "null")
  		)

	# Uncomment for individual plot 'debugging'
	#plotname = paste("/data/band_", thisband$name, "_2.jpg", sep="")
	#ggsave(plotname, plot=bandplot)

	# Store the plots up so we can grid them all as one final image
	allplots[[length(allplots)+1]] <- ggplotGrob(bandplot)
}

# Generate the single final large picture
bigplot = grid.arrange(grobs=allplots, ncol=1)
#Try to plot as landscape A4. Base the filename on the datadir name
fullplot_file = paste("/data/", inputdir, ".jpg", sep="")
ggsave(fullplot_file, plot=bigplot, units="cm", width=29.7, height=21.0)
