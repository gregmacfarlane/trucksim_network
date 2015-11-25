# Makefile to build the network
NETWORK = usa_network.xml.gz

CP = -cp .:java/bin/:/Users/Greg/Documents/matsim-0.6.1/matsim-0.6.1.jar
JC = javac

JFILES := $(SCRIPTS:$(SCRIPTDIR)/%.R=$(SIMULFDIR)/%.csv)

# USA freight network construction
usa: usa_network.xml.gz
	@echo "USA network ready"

usa_network.xml.gz: data/usa_freeways.osm java/bin/BuildNetwork.class
	java $(CP) BuildNetwork ./data/usa_freeways.osm"EPSG:2818" $@

data/usa_freeways.osm: data/usa_*_freeways.osm
	osmosis\
	--rx data/usa_northeast_freeways.osm \
	--rx data/usa_midwest_freeways.osm \
	--rx data/usa_south_freeways.osm \
	--rx data/usa_west_freeways.osm \
	--merge --merge --merge\

data/usa_*_freeways.osm: queries/usa_*.xml
	wget -O $@ --timeout=0 --post-file=$< "http://overpass-api.de/api/interpreter"

# NC network construction
nc: nc_network.xml.gz
	
nc_network.xml.gz: data/nc_freeways.osm java/bin/BuildNetwork.class
	java $(CP) BuildNetwork ./data/nc_freeways.osm "EPSG:3358" $@

data/nc_freeways.osm: queries/query_nc.xml
	wget -O $@ --timeout=0 --post-file=$< "http://overpass-api.de/api/interpreter"
	

# write out to shapefile
usa.shp: usa_network.xml.gz java/bin/Links2ESRIShape.class
	java $(CP) Links2ESRIShape usa_network.xml.gz "EPSG:2818" $@
	
nc.shp: nc_network.xml.gz java/bin/Links2ESRIShape.class
	java $(CP) Links2ESRIShape nc_network.xml.gz "EPSG:2818" $@
	
j: java/bin/BuildNetwork.class
 
# compile java programs
java/bin/BuildNetwork.class: java/src/BuildNetwork.java
	@echo compiling Java class
	@mkdir -p $(@D)
	$(JC) -d $(@D) $(CP) $<
 
java/bin/Links2ESRIShape.class: java/src/Links2ESRIShape.java
	@echo compiling Java class
	@mkdir -p $(@D)
	$(JC) -d $(@D) $(CP) $<
 
# make changevents
change: R/congestion_maker.R
  @echo building change events file
  Rscript $<
