#!/bin/bash

matsim_path="/home/greg/Desktop/matsim-0.6.0/*"

# 1 ----------------
# Download national highway system GeoJSON file and unzip
wget -o data/nhs.zip \
 "http://www.fhwa.dot.gov/planning/processes/tools/nhpn/2015/nhpnv14-05geojson.zip"

unzip data/nhs.zip -d data/



# 2 ----------------
# Convert GeoJSON to osm.xml

# 2 ------------------
echo "Converting to MATSim network"
java \
 -classpath "./bin:$matsim_path"\
 trucksim_network.BuildNetwork\
 ./data/nc_freeways.osm "EPSG:2818" ./usa_network.xml.gz

