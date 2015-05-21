# trucksim_network
This repository contains scripts to create and manage networks and attributes
for a national freight microsimulation executed in MATSim.

The user can run all steps sequentially with the included shell script,

    bash build_network.sh

## Get network data from OpenStreetMap

The first step pulls roadway data from OpenStreetMap. We keep the following
highway types:

  - `motorway`
  - `motorway-link`
  - `trunk`

The `queries` folder contains several `.xml` query files that can pull data
from the OpenStreetMap servers using the Overpass API language. Users 
can select the query they wish to use in the `build_network.sh` script or
develop their own query from these templates.

## Convert to a MATSim Network
The next step runs a Java class to build a MATSim network from the
OpenStreetMap data. The user will need to point the program to her own
MATSim source files.

    matsim_path="/Users/user/matsim-0.6.0/*"



