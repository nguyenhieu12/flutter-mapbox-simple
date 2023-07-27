import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class ZoomPage extends StatefulWidget {
  const ZoomPage({super.key});

  @override
  State<ZoomPage> createState() => _ZoomPageState();
}

class _ZoomPageState extends State<ZoomPage> {
  late MapboxMapController mapController;

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white
        ),
        centerTitle: true,
        title: const Text(
          'Zoom',
          style: TextStyle(color: Colors.white, fontSize: 26),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(25),
            width: screenWidth * 0.95,
            height: 580,
            child: MapboxMap(
              accessToken:
                  'sk.eyJ1IjoiaGlldW5tMTIxMiIsImEiOiJjbGptanBtMmExNmhjM3FrMjE1bHZpdzVmIn0.TwqdH0eYn4xy34qcyFWgkQ',
              onMapCreated: _onMapCreated,
              styleString: MapboxStyles.MAPBOX_STREETS,
              initialCameraPosition: const CameraPosition(
                  target: LatLng(21.028511, 105.804817), 
                  zoom: 12
                ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  mapController.animateCamera(CameraUpdate.zoomIn());
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.zoom_in,
                  size: 35,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  mapController.animateCamera(CameraUpdate.zoomOut());
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.zoom_out,
                  size: 35,
                  color: Colors.white,
                ),
              )
            ],
          )
        ]
      ),
    );
  }
}