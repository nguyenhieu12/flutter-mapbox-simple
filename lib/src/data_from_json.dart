import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class DataFromJSON extends StatefulWidget {
  const DataFromJSON({Key? key}) : super(key: key);

  @override
  State<DataFromJSON> createState() => _DataFromJSONState();
}

class _DataFromJSONState extends State<DataFromJSON> {
  late List<dynamic> jsonData = [];
  late List<Map<String, dynamic>> features;
  late Map<String, dynamic> geoJson; 
  late Map<String, dynamic> featuresMap;
  late MapboxMapController mapController;
  int addCircleTime = 0;

  var listColors = ['red', 'orange', 'lightgreen'];
  
  final delay = const Duration(milliseconds: 1);

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    mapController.onFeatureTapped.add(onFeatureTap);
  }

  void onFeatureTap(dynamic featureId, Point<double> point, LatLng latLng) {

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Point info'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Latitude: ${featuresMap[featureId]['lat']}'),
                Text('Longitude: ${featuresMap[featureId]['lng']}'),
                Text('District: ${featuresMap[featureId]['district']}'),
                Text('KQI: ${featuresMap[featureId]['kqi']}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
  }

  void loadJSONData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/zdt_point_80k.json');
      jsonData = json.decode(jsonString);
      featuresMap = { for (var item in jsonData) item['pCellId'] : item };
      
      features = jsonData.map((item) {
        double lat = item['lat'];
        double lng = item['lng'];
        String id = item['pCellId'];

        return {
          'type': 'Feature',
          'id': id,
          'properties': {},
          'geometry': {
            'type': 'Point',
            'coordinates': [lng, lat],
          },
        };
      }).toList();

      geoJson = {
        'type': 'FeatureCollection',
        'features': features,
      };

    } catch (e) {
      debugPrint('Error loading JSON data: $e');
    }
  }

  void addCircleLayer() async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {

      mapController.addGeoJsonSource('sourceId', geoJson);

      mapController.addCircleLayer('sourceId', 'layerId', const CircleLayerProperties(
        circleColor: 'lightgreen', // < -105 red, -105 -> -101 orange, > -101 lightgreen
        circleRadius: 8
      ));

    } catch (e) {
      debugPrint('Error adding circle layer: $e');
    }

    setState(() {
      addCircleTime = stopwatch.elapsedMilliseconds;
    });
  }

  @override
  void initState() {
    super.initState();
    loadJSONData();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Circle Layer',
          style: TextStyle(color: Colors.white, fontSize: 26),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(25),
            width: screenWidth * 0.95,
            height: 560,
            child: MapboxMap(
              accessToken:
                  'sk.eyJ1IjoiaGlldW5tMTIxMiIsImEiOiJjbGptanBtMmExNmhjM3FrMjE1bHZpdzVmIn0.TwqdH0eYn4xy34qcyFWgkQ',
              onMapCreated: _onMapCreated,
              styleString: MapboxStyles.MAPBOX_STREETS,
              initialCameraPosition: const CameraPosition(
                target: LatLng(21.028511, 105.804817),
                zoom: 10,
              ),
            ),
          ),
          Text(
            'Execution time (addAllCircles): $addCircleTime ms',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  addCircleLayer();
                },
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              )
        ],
      ),
    );
  }
}