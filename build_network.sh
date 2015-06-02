#!/bin/bash

matsim_path="/home/greg/Desktop/matsim-0.6.0/*"

# 1 ----------------
# Pull osm xml data file using the Overpass API. 
# Need to get the data in pieces or API will reject
echo "Downloading OSM Freight Network "
for i in northeast south midwest west; do
  echo 
  ## get the osm data
  wget -O data/usa_${i}_freeways.osm --timeout=0 \
   --post-file=queries/usa_${i}.xml "http://overpass-api.de/api/interpreter"

done


# Post-processing of downloaded data 
osmosis \
 --read-xml data/usa_northeast_freeways.osm \
 --read-xml data/usa_south_freeways.osm \
 --read-xml data/usa_midwest_freeways_conv.osm \
 --read-xml data/usa_west_freeways_conv.osm \
 --merge \
 --bp file=./query/usa.poly \
 --write-xml data/usa_freeways.osm


# 2 ------------------
echo "Converting to MATSim network"
java \
 -classpath "./bin:$matsim_path"\
 trucksim_network.BuildNetwork\
 ./data/nc_freeways.osm "EPSG:2818" ./usa_network.xml.gz

