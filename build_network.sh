#!/bin/bash

# 1 ----------------
# Pull osm xml data file using the Overpass API.
echo "Downloading OSM Freight Network "
# highway network
wget -O nc_freeways.osm \
	--post-file=queries/query_northcarolina.xml \
	"http://overpass-api.de/api/interpreter"
# rail network
wget -O nc_rail.osm \
	--post-file=queries/query_northcarolina_rail.xml \
  "http://overpass-api.de/api/interpreter"

# 2 ------------------
echo "Converting to MATSim network"
