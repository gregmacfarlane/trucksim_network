#!/bin/bash

# 1 ----------------
# Pull osm xml data file using the Overpass API.
echo "Downloading OSM Freight Network "
# highway network
wget -O nc_freeways.osm \
	--post-file=queries/query_northcarolina.xml \
	"http://overpass-api.de/api/interpreter"


# trim to usa polyline boundary (if USA)
osmosis --read-xml usa_freeways.osm\
 --bp file=./query/usa.poly\
 --write-xml .usa_freeways.osm


# 2 ------------------
echo "Converting to MATSim network"
