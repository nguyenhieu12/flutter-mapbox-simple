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
  late MapboxMapController mapController;
  int displayDataTime = 0;

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

  void displayData() async {
    int circleCount = 0;
    const batchSize = 25000;
    const delay = Duration(milliseconds: 1);
    final int targetCircleCount = (jsonData != null ? jsonData.length : 0);

    final Stopwatch executionTime = Stopwatch()..start();

    while (circleCount < targetCircleCount) {
      final remainingCount = targetCircleCount - circleCount;
      final batchCount = min(batchSize, remainingCount);

      final circles = List.generate(batchCount, (index) {
        return CircleOptions(
          geometry: LatLng(jsonData[index]['lat'], jsonData[index]['lng']),
          circleColor: listColors[Random().nextInt(3)],
          circleRadius: 8,
        );
      });

      circles.forEach((id) {
        mapController.onCircleTapped.add((argument) {

        });
      });

      await mapController.addCircles(circles);
      circleCount += batchCount;
      
      await Future.delayed(delay);
    }

    setState(() {
      displayDataTime = executionTime.elapsedMilliseconds;
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
                zoom: 7,
              ),
              // onStyleLoadedCallback: addAllCircles,
            ),
          ),
          Text(
            'Execution time (addAllCircles): $displayDataTime ms',
            style: const TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  displayData();
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
