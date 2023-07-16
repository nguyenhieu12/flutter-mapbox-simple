import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:async';
import 'dart:math';

class CircleLayer extends StatefulWidget {
  const CircleLayer({Key? key}) : super(key: key);
  
  @override
  State<CircleLayer> createState() => _CircleLayerState();
}

class _CircleLayerState extends State<CircleLayer> {
  late MapboxMapController mapController;
  final double latitude = 21.028511;
  final double longitude = 105.804817;
  int circleCount = 0;
  final int targetCircleCount = 100000;
  final batchSize = 25000;
  final delay = const Duration(milliseconds: 1);
  int addRandomCircleTime = 0;
  int addAllCirclesTime = 0;

  var listColors = ['red', 'orange', 'lightgreen'];

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    // mapController.onCircleTapped.add((argument) {
    //       displayInfo(argument.id);
    // });
    // mapController.onFeatureTapped
  }

  void addRandomCircle() {
    final Stopwatch executionTime = Stopwatch()..start();
    final randomLat = latitude + Random().nextDouble();
    final randomLng = longitude + Random().nextDouble();
    mapController.addCircle(
      CircleOptions(
        geometry: LatLng(randomLat, randomLng),
        circleColor: listColors[Random().nextInt(3)],
        circleRadius: 8,
      ),
    );

    setState(() {
      addRandomCircleTime = executionTime.elapsedMilliseconds;
    });
  }

  Future<void> addAllCircles() async {
    final Stopwatch executionTime = Stopwatch()..start();
    int id = 0;

    while (circleCount < targetCircleCount) {
      final remainingCount = targetCircleCount - circleCount;
      final batchCount = min(batchSize, remainingCount);

      final circles = List.generate(batchCount, (index) {
        final randomLat = latitude + Random().nextDouble();
        final randomLng = longitude + Random().nextDouble();
        id = index;

        return CircleOptions(
          geometry: LatLng(randomLat, randomLng),
          circleColor: listColors[Random().nextInt(3)],
          circleRadius: 8,
        );
      });

      

      mapController.addCircles(circles);
      circleCount += batchCount;

      await Future.delayed(delay);
    }

    setState(() {
      addAllCirclesTime = executionTime.elapsedMilliseconds;
    });

  }

  void displayInfo(circleId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Point info'),
        content: Text('This is point with ID: ${circleId.toString()}'),
        actions: [
          FloatingActionButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
            height: 520,
            child: MapboxMap(
              accessToken:
              'sk.eyJ1IjoiaGlldW5tMTIxMiIsImEiOiJjbGptanBtMmExNmhjM3FrMjE1bHZpdzVmIn0.TwqdH0eYn4xy34qcyFWgkQ',
              onMapCreated: _onMapCreated,
              styleString: MapboxStyles.MAPBOX_STREETS,
              initialCameraPosition: const CameraPosition(
                target: LatLng(21.028511, 105.804817),
                zoom: 12,
              ),
            ),
          ),
          Text(
            'Execution time (addRandomCircle): $addRandomCircleTime ms',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Execution time (addAllCircles): $addAllCirclesTime ms',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  addRandomCircle();
                },
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  size: 35,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  addAllCircles();
                },
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.all_inclusive,
                  size: 35,
                  color: Colors.white,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}