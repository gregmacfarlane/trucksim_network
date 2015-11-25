# Congestion Maker
# ======================================
# This script creates a network change attributes file that adjusts the freeflow
# speed on links in metropolitan areas during peak hours. This is based on the 
# Texas Transportation Institute's Travel Time Index.

library(dplyr)
library(readr)
library(maptools)
library(rgeos)
library(rgdal)
library(XML)

# Census uses WGS84, we use a LCC projection.
WGS84 <- CRS("+proj=longlat +datum=WGS84 +no_defs")
LCC <- CRS("+proj=lcc +lat_1=49 +lat_2=45 +lat_0=44.25 +lon_0=-109.5 +x_0=600000
           +y_0=0 +ellps=GRS80 +units=m +no_defs")


# Load population, urban area, and traffic congestion data.
# -------------------------------------------------
message("Calculating congestion from TTI data.\n")
# The folks at A&M didn't use the same names for the MSAs as Census does, so I've
# gone through and put the ID fields on a cleaned version of the TTI data. I 
# think College Station owes me something.
# Congestion from TTI
TTI <- read_csv("data_raw/TTIclean.csv") %>%
  transmute(GEOID = GEOID, tti = TTI)
# Urban area data from ACS 5 year 2007-2012
MSApop <- read_csv("data_raw/ACS_12_5YR_B01003.csv") %>%
  transmute(pop = as.numeric(HD01_VD01), GEOID = GEO.id)
# Urban area shapefile definitions
MSA <- readShapeSpatial(
  "data_raw/cb_2012_us_uac10_500k.shp", proj4string = WGS84
  ) %>%
  spTransform(., LCC)


# Congestion model
# -------------------------------------
# Not every urban area is in the TTI data; so I estimate a simple linear model
# on population to fill in the missing spaces. If a measurement exists I use it.
# If it doesn't I predict it; however, I require it to be greater than or equal
# to 1.

MSA@data <- MSA@data %>%
  transmute(GEOID = as.character(AFFGEOID10), msa = gsub(",", "", NAME10)) %>%
  left_join(., MSApop, by = "GEOID") %>%
  left_join(., TTI, by = "GEOID")

estimationData <- MSA@data %>% filter(!(is.na(tti)))
tti.lm <- lm(tti ~ log(pop), data = estimationData)

MSA@data <- MSA@data %>% 
  mutate(ttiEstimate = predict(tti.lm, newdata = MSA@data),
         tti = ifelse(is.na(tti), ifelse(ttiEstimate < 1, 1, ttiEstimate), tti))

MSA <- MSA[which(MSA$tti > 1),]




# Read in Network Link information
# ---------------------------------
message("Reading MATSim Network from shapefile\n")
# We are using an OpenStreetMap network that we built using MATSim's built-in
# converters, and exported a shapefile version that we can use to join spatial
# attributes on. First we locate the links within a metropolitan area, and then
# append the TTI information.
Network <- readShapeLines("usa.shp", proj4string = LCC)[1:100, ]

# Create nodes database
# start points
s_coords <- lapply(
  slot(Network, "lines"), function(x) 
    lapply(slot(x, "Lines"), function(y) slot(y, "coords")[1,]
  )
) %>% 
  unlist(.) %>%
  matrix(., nrow = nrow(Network), byrow=T) %>%
  data.frame(.) %>%
  tbl_df() %>%
  rename(lon = X1, lat = X2) %>%
  mutate(ID = as.character(Network$toID))

# endpoints
e_coords <- lapply(
  slot(Network, "lines"), function(x) 
    lapply(slot(x, "Lines"), function(y) slot(y, "coords")[2,]
  )
) %>% 
  unlist(.) %>%
  matrix(., nrow = nrow(Network), byrow=T) %>%
  data.frame(.) %>%
  tbl_df() %>%
  rename(lon = X1, lat = X2) %>%
  mutate(ID = as.character(Network$toID)) %>%
  filter(!(ID %in% s_coords$ID))

nodes <- rbind_list(s_coords, e_coords)
Nodes <- SpatialPointsDataFrame(
  cbind(nodes$lon, nodes$lat), data = as.data.frame(nodes),
  proj4string = LCC
)
 
Nodes$GEOID <- over(Nodes, MSA)$GEOID

message("Determining link location\n")

# At this point we don't need to keep spatial attributes anymore.
Network <- Network@data %>%
  left_join(., Nodes@data %>% transmute(fromID = ID, GEOIDa = GEOID)) %>%
  left_join(., Nodes@data %>% transmute(toID   = ID, GEOIDb = GEOID)) %>%
  left_join(., MSA@data %>% transmute(GEOIDa = GEOID, ttia = tti)) %>%
  left_join(., MSA@data %>% transmute(GEOIDb = GEOID, ttib = tti)) %>%
  # If the entire link is outside a metropolitan area, then drop it
  filter(is.na(GEOIDa) == FALSE | is.na(GEOIDb) == FALSE) %>%
  # TTI should be the average at either end.
  mutate(ttia = ifelse(is.na(ttia), 1, ttia),
         ttib = ifelse(is.na(ttib), 1, ttib),
         tti = (ttia + ttib)/2)  %>%
  transmute(ID = as.character(ID), fromID = as.character(fromID), 
            toID = as.character(toID),  tti = tti)



# Write to xml
# ---------------------------------------------------------------
# This XML structure is a little more complicated than the other ones, so we
# are going to use R's xml library. The parent node defines some schema
# Each peak period (7:00 to 10:00 and 4:00 to 7:00) in each MSA will have its
# own little chunk of attribute definitions.

# This simply creates the root-level XML header.
ChangeTree <- newXMLDoc()


# This function creates a block of link IDs in a given metro area
# that get adjusted by a TTI at the start or end of a peak period. This function
# also adds the block to our XML document.
linkChangeBlock <- function(metroLinkBlock, time, startPeak = TRUE){
  change <- newXMLNode("networkChangeEvent", 
                       attrs = c(startTime = paste(sprintf("%02d", time), 
                                                   ":00:00", sep = "")))
  
  
  # print a link with attribute ID for every link in a metro area.
  for(i in 1:nrow(metroLinkBlock)){
    newXMLNode("link", attrs = c(refId = metroLinkBlock$ID[i]), parent = change)
  }
  
  # If the peak is starting, need to divide by TTI; if ending, multiply
  if(startPeak) { 
    newXMLNode("freespeed",  parent = change, 
               attrs = c(type = "scaleFactor", value = 1/metroLinkBlock$tti[1]))
  } else {
    newXMLNode("freespeed",  parent = change, 
               attrs = c(type = "scaleFactor", value = metroLinkBlock$tti[1]))
  }
  return(change)
}

# First day 
message("Building XML tree")
# I'm not precisely sure why this doesn't work in parallel. As is, each element
# takes about two hours to run. Someone with more skills than I have will need 
# to figure this one out.
am1b <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 7, TRUE))
am1e <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 10, FALSE))
pm1b <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 16, TRUE))
pm1e <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 19, FALSE))

# Second day
am2b <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 7+24, TRUE))
am2e <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 10+24, FALSE))
pm2b <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 16+24, TRUE))
pm2e <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 19+24, FALSE))

# Third day
am3b <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 7+48, TRUE))
am3e <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 10+48, FALSE))
pm3b <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 16+48, TRUE))
pm3e <- lapply(split(Network, f = Network$tti),
               function(.) linkChangeBlock(., 19+48, FALSE))


# For some reason I can't append the change events to their parent, but I can 
# create the parent and give it children. Weird, but it seems to work.
ChangeEvents <- newXMLNode(
  "networkChangeEvents", 
  .children = list(
    am1b, am1e, pm1b, pm1e, am2b, am2e, pm2b, pm2e, am3b, am3e, pm3b, pm3e
  ), 
  doc = ChangeTree, 
  namespaceDefinitions = c(
    "http://www.matsim.org/files/dtd", 
    "xsi"="http://www.w3.org/2001/XMLSchema-instance", 
    "xsi:schemaLocation"="http://www.matsim.org/files/dtd http://www.matsim.org/files/dtd/networkChangeEvents.xsd"
  )
)

cat(saveXML(ChangeTree), file = "changeevents.xml")
