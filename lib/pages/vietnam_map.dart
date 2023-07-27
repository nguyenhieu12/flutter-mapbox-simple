import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/services.dart';

class VietnamMap extends StatefulWidget {
  const VietnamMap({super.key});
  
  @override
  State<VietnamMap> createState() => _VietnamMapState();
}

class _VietnamMapState extends State<VietnamMap> {
  late MapboxMapController mapController;
  late Map<String, dynamic> geoJsonData;
  List<dynamic> mapData = [];
  late Map<String, dynamic> provinceData;

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    initMap();
    mapController.onFeatureTapped.add((id, point, coordinates) {
      debugPrint('Current ID: $id');
    });
  }

  void displayProvinceInfo(dynamic id) {
    var data = mapData[id];
    print(data);
    // var featureData;
    // showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         title: const Text('Point info'),
    //         content: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             Text('Latitude: ${featureData['lat']}'),
    //             Text('Longitude: ${featureData['lng']}'),
    //             Text('District: ${featureData['district']}'),
    //             Text('KQI: ${featureData['kqi']}'),
    //           ],
    //         ),
    //         actions: [
    //           ElevatedButton(
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //             child: const Text('Đóng'),
    //           ),
    //         ],
    //       );
    //     },
    //   );
  }

  void initMap() async {
    try {
      String data = await rootBundle.loadString('assets/vietnam_province.geojson');
      geoJsonData = json.decode(data);

      List<dynamic> features = geoJsonData['features'];

      List<Map<String, dynamic>> layerData = [];

      for(int i = 0; i < features.length; i++) {
        layerData.add(
          {
            "type": "FeatureCollection",
            "features": features[i]
          }
        );     
      }

      for(int i = 0; i < layerData.length; i++) {
        mapController.addGeoJsonSource('sourceId$i', 
          layerData[i]
        );

        mapController.addLayer('sourceId$i', 'layerId$i', const FillLayerProperties(
          fillColor: 'lightgreen',
          fillOutlineColor: 'red'
        ));     
      }

      // for (int i = 0; i < features.length; i++) {
      //   features[i]['id'] = features[i]['properties']['Name'];
      //   //todo
      // }

      // geoJsonData['features'] = features;

    } catch(e) {
      debugPrint('Error adding layer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white
        ),
        centerTitle: true,
        title: const Text(
          'Vietnam Map',
          style: TextStyle(color: Colors.white, fontSize: 26),
        ),
        backgroundColor: Colors.blue,
      ),
      body: MapboxMap(
        accessToken: 'sk.eyJ1IjoiaGlldW5tMTIxMiIsImEiOiJjbGptanBtMmExNmhjM3FrMjE1bHZpdzVmIn0.TwqdH0eYn4xy34qcyFWgkQ',
        styleString: MapboxStyles.MAPBOX_STREETS,
        initialCameraPosition: const CameraPosition(
          target: LatLng(16.102622, 105.690185),
          zoom: 5
        ),
        onMapCreated: _onMapCreated,
      )
    );
  }
}