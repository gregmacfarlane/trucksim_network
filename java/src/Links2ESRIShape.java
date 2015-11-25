
import java.util.ArrayList;
import java.util.Collection;

import org.apache.log4j.Logger;
import org.matsim.api.core.v01.Scenario;
import org.matsim.api.core.v01.network.Link;
import org.matsim.api.core.v01.network.Network;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.network.MatsimNetworkReader;
import org.matsim.core.network.NetworkUtils;
import org.matsim.core.scenario.ScenarioUtils;
import org.matsim.core.utils.gis.ShapeFileWriter;
import org.matsim.utils.gis.matsim2esri.network.FeatureGenerator;
import org.matsim.utils.gis.matsim2esri.network.FeatureGeneratorBuilderImpl;
import org.matsim.utils.gis.matsim2esri.network.LanesBasedWidthCalculator;
import org.matsim.utils.gis.matsim2esri.network.LineStringBasedFeatureGenerator;
import org.opengis.feature.simple.SimpleFeature;

public class Links2ESRIShape {

	private static Logger log = Logger.getLogger(Links2ESRIShape.class);

	private final FeatureGenerator featureGenerator;
	private final Network network;
	private final String filename;


	public Links2ESRIShape(final Network network, final String filename, final String coordinateSystem) {
		this(network, filename, new FeatureGeneratorBuilderImpl(network, coordinateSystem));
	}

	public Links2ESRIShape(final Network network, final String filename, final FeatureGeneratorBuilderImpl featureGeneratorBuilderImpl) {
		this.network = network;
		this.filename = filename;
		this.featureGenerator = featureGeneratorBuilderImpl.createFeatureGenerator();

	}

	public void write() {
		log.info("creating features...");
		Collection<SimpleFeature> features = new ArrayList<SimpleFeature>();
		for (Link link : NetworkUtils.getSortedLinks(this.network)) {
			features.add(this.featureGenerator.getFeature(link));
		}
		log.info("writing features to shape file... " + this.filename);
		ShapeFileWriter.writeGeometries(features, this.filename);
		log.info("done writing shape file.");
	}

	public static void main(final String [] args) {
		String netfile = null ;
		String outputFileLs = null ;
		String defaultCRS = "DHDN_GK4";
		if ( args.length == 0 ) {
			netfile = "./examples/equil/network.xml";
//		String netfile = "./test/scenarios/berlin/network.xml.gz";

			outputFileLs = "./plans/networkLs.shp";
		} else if ( args.length == 3 ) {
			netfile = args[0] ;
			defaultCRS = args[1] ;
			outputFileLs = args[2] ;
		} else {
			log.error("Arguments cannot be interpreted.  Aborting ...") ;
			System.exit(-1) ;
		}

		Scenario scenario = ScenarioUtils.createScenario(ConfigUtils.createConfig());
		scenario.getConfig().global().setCoordinateSystem(defaultCRS);

		log.info("loading network from " + netfile);
		final Network network = scenario.getNetwork();
		new MatsimNetworkReader(scenario).readFile(netfile);
		log.info("done.");

		FeatureGeneratorBuilderImpl builder = new FeatureGeneratorBuilderImpl(network, defaultCRS);
		builder.setFeatureGeneratorPrototype(LineStringBasedFeatureGenerator.class);
		builder.setWidthCoefficient(0.5);
		builder.setWidthCalculatorPrototype(LanesBasedWidthCalculator.class);
		new Links2ESRIShape(network,outputFileLs, builder).write();

	}

}
