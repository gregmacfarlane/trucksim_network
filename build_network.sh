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


# 2 ----------------
# Merge the different osm files together, and trim to USA border
osmosis \
 --rx data/usa_northeast_freeways.osm \
 --rx data/usa_midwest_freeways.osm \
 --rx data/usa_south_freeways.osm \
 --rx data/usa_west_freeways.osm \
 --merge --merge --merge\
 --bounding-polygon file="./queries/usa.poly"\
 --wx data/usa_freeways.osm


# 3 ------------------
echo "Converting to MATSim network"
java \
 -classpath "./bin:$matsim_path"\
 trucksim_network.BuildNetwork\
 ./data/usa_freeways.osm "EPSG:2818" ./usa_network.xml.gz

