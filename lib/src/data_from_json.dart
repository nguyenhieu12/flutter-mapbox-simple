import 'package:flutter/material.dart';
import 'dart:convert';
// import 'dart:math';
import 'package:flutter/services.dart';
import 'package:map_tracking/src/circle_layer.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geojson/geojson.dart';

class DataFromJSON extends StatefulWidget {
  const DataFromJSON({Key? key}) : super(key: key);

  @override
  State<DataFromJSON> createState() => _DataFromJSONState();
}

class _DataFromJSONState extends State<DataFromJSON> {
  late List<dynamic> jsonData = [];
  late MapboxMapController mapController;
  int addCircleTime = 0;

  var listColors = ['red', 'orange', 'lightgreen'];
  
  final delay = const Duration(milliseconds: 1);

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  void loadJSONData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/zdt_point_80k.json');
      setState(() {
        jsonData = json.decode(jsonString);
      });
    } catch (e) {
      debugPrint('Error loading JSON data: $e');
    }
  }

  void addCircleLayer() async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      String jsonString = await rootBundle.loadString('assets/zdt_point_80k.json');
      List<dynamic> jsonData = json.decode(jsonString);

      List<Map<String, dynamic>> features = jsonData.map((item) {
        double lat = item['lat'];
        double lng = item['lng'];

        return {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'Point',
            'coordinates': [lng, lat],
          },
        };
      }).toList();

      Map<String, dynamic> geoJson = {
        'type': 'FeatureCollection',
        'features': features,
      };

      mapController.addGeoJsonSource('sourceId', geoJson);

      mapController.addCircleLayer('sourceId', 'layerId', const CircleLayerProperties(
        circleColor: 'lightgreen',
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
    //loadJSONData();
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
              // onStyleLoadedCallback: addAllCircles,
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