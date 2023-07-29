import 'dart:convert';
import 'package:uuid/uuid.dart';
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
  String oldId = '';
  late Map<String, dynamic> provinceData;
  Uuid uuid = const Uuid();

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    initMap();
    
    mapController.onFeatureTapped.add((id, point, coordinates) {
      print('Current ID: $id');
      print('Current ID string: $oldId');
      handleProvinceTapped(id);
    });
  }

  void handleProvinceTapped(dynamic id) {
    
    if (oldId.isEmpty) {
      updateLayer(id);
    } else {
      removeAndRenderLayer(id);
    }
  }

  void removeAndRenderLayer(id) {

    mapController.removeLayer('layerId-$id');
    mapController.removeSource('sourceId-$id');

    mapController.removeLayer('layerId-$oldId');
    mapController.removeSource('sourceId-$oldId');

    Map<String, dynamic> oldFeatureCollection = {
      "type": "FeatureCollection",
      "features": [provinceData[oldId]],
    };

    mapController.addGeoJsonSource('sourceId-$oldId', oldFeatureCollection);
    mapController.addLayer('sourceId-$oldId', 'layerId-$oldId', const FillLayerProperties(
      fillColor: 'lightgreen',
      fillOutlineColor: 'red',
    ));

    Map<String, dynamic> currentFeatureCollection = {
      "type": "FeatureCollection",
      "features": [provinceData[id]],
    };

    mapController.addGeoJsonSource('sourceId-$id', currentFeatureCollection);
    mapController.addLayer('sourceId-$id', 'layerId-$id', const FillLayerProperties(
      fillColor: 'yellow',
      fillOutlineColor: 'red',
    ));

    oldId = id;
  }

  void updateLayer(dynamic id) {
    
    mapController.removeLayer('layerId-$id');
    mapController.removeSource('sourceId-$id');
    

    Map<String, dynamic> featureCollection = {
      "type": "FeatureCollection",
      "features": [provinceData[id]],
    };

    mapController.addGeoJsonSource('sourceId-$id', featureCollection);
    mapController.addLayer('sourceId-$id', 'layerId-$id', const FillLayerProperties(
      fillColor: 'yellow',
      fillOutlineColor: 'red',
    ));

    setState(() {
      oldId = id;
    });

  }

  void initMap() async {
    try {
      String data = await rootBundle.loadString('assets/vietnam_province.geojson');
      geoJsonData = json.decode(data);

      List<dynamic> features = geoJsonData['features'];

      for (int i = 0; i < features.length; i++) {
        features[i]['id'] = uuid.v4();
      }

      geoJsonData['features'] = features;

      provinceData = { for (var item in geoJsonData['features']) item['id'] : item };

      for (int i = 0; i < features.length; i++) {
        Map<String, dynamic> feature = features[i];
        List<Map<String, dynamic>> featureList = [feature];

        Map<String, dynamic> featureCollection = {
          "type": "FeatureCollection",
          "features": featureList,
        };

        mapController.addGeoJsonSource('sourceId-${feature['id']}', featureCollection);

        mapController.addLayer('sourceId-${feature['id']}', 'layerId-${feature['id']}', const FillLayerProperties(
          fillColor: 'lightgreen',
          fillOutlineColor: 'red',
        ));

        print('Add layer $i success');
      }
    } catch (e) {
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