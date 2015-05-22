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

  ## convert to the most recent version of osm; why the api can't do this is 
  ## entirely beyond me.
  osmconvert data/usa_${i}_freeways.osm \
   --fake-author --fake-version -o=data/usa_${i}_freeways_conv.osm
done


# Post-processing of downloaded data 

osmosis \
 --read-xml-0.5 data/usa_northeast_freeways.osm \
 --read-xml-0.5 data/usa_south_freeways.osm \
 --merge \
 --write-xml data/usa_east_freeways.osm

 --read-xml data/usa_midwest_freeways.osm \
 --read-xml data/usa_west_freeways.osm \
 --bp file=./query/usa.poly \



# 2 ------------------
echo "Converting to MATSim network"
java \
 -classpath "./bin:$matsim_path"\
 trucksim_network.BuildNetwork\
 ./data/nc_freeways.osm "EPSG:2818" ./usa_network.xml.gz

