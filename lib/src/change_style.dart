import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class ChangeStyle extends StatefulWidget {
  const ChangeStyle({super.key});

  @override
  State<ChangeStyle> createState() => _ChangeStyleState();
}

class _ChangeStyleState extends State<ChangeStyle> {
  
  late MapboxMapController mapController;
  String selectedStyle = 'mapbox://styles/mapbox/streets-v12';
  String streetStyle = 'mapbox://styles/mapbox/streets-v12';
  String outdoorStyle = 'mapbox://styles/mapbox/satellite-v9';
  
  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  void changeStyle() {
    if (selectedStyle != outdoorStyle) {
      
      setState(() {
        selectedStyle = outdoorStyle;
      });
    } else {
      
      setState(() {
        selectedStyle = streetStyle;
      });
    }
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
          'Change Style',
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
                  styleString: selectedStyle,
                  initialCameraPosition: const CameraPosition(
                      target: LatLng(21.028511, 105.804817), 
                      zoom: 12
                  ),
                ),
              ),
          FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  changeStyle();
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.add_to_home_screen,
                  size: 35,
                  color: Colors.white,
                ),
              )
        ],
      ),
    );
  }
}