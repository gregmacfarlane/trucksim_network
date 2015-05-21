#!/bin/bash

matsim_path="/Users/Greg/Desktop/matsim-0.6.0/*"


# 1 ----------------
# Pull osm xml data file using the Overpass API.
echo "Downloading OSM Freight Network "
# highway network
wget -O data/nc_freeways.osm \
	--post-file=queries/query_northcarolina.xml \
	"http://overpass-api.de/api/interpreter"


# trim to usa polyline boundary (if USA)
osmosis --read-xml data/usa_freeways.osm\
 --bp file=./query/usa.poly\
 --write-xml data/usa_freeways.osm


# 2 ------------------
echo "Converting to MATSim network"
java -classpath\
 "./bin:$matsim_path"\
 trucksim_network.BuildNetwork\
 ./data/nc_freeways.osm "EPSG:2818" ./nc_network.xml.gz

