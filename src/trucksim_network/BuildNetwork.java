package trucksim_network;

import org.matsim.api.core.v01.Scenario;
import org.matsim.api.core.v01.network.Network;
import org.matsim.core.config.Config;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.network.NetworkWriter;
import org.matsim.core.network.algorithms.NetworkCleaner;
import org.matsim.core.scenario.ScenarioUtils;
import org.matsim.core.utils.geometry.CoordinateTransformation;
import org.matsim.core.utils.geometry.transformations.TransformationFactory;
import org.matsim.core.utils.io.OsmNetworkReader;

public class BuildNetwork {

	/**
	 * 
	 * @param args a set of arguments consisting of:
	 * @param osm an OpenStreetMap `.osm` xml file.
	 * @param crs an EPSG projection code.
	 * @param output the name of the output network.
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		String osm = args[0];
		String crs = args[1];
	    String output = args[2];
		
		Config config = ConfigUtils.createConfig();
		Scenario sc = ScenarioUtils.createScenario(config);
		Network net = sc.getNetwork();
		
		CoordinateTransformation ct = 
				TransformationFactory.getCoordinateTransformation(
						TransformationFactory.WGS84, crs);
		
		OsmNetworkReader onr = new OsmNetworkReader(net,ct);
		onr.parse(osm);
		new NetworkCleaner().run(net);
		new NetworkWriter(net).write(output);

	}

}
