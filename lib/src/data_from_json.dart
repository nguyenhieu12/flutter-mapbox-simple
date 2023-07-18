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
  late Map<String, dynamic> lowKqiGeoJson;
  late Map<String, dynamic> mediumKqiGeoJson;
  late Map<String, dynamic> highKqiGeoJson;
  late Map<String, dynamic> featuresMap;
  late MapboxMapController mapController;
  double lowThreshold = -105.0;
  double highThreshold = -101.0;
  int addCircleTime = 0;
  bool isLowSelected = false;
  bool isMediumSelected = false;
  bool isHighSelected = false;

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
      featuresMap = { for (var item in jsonData) item['pCellId']: item };

      List<Map<String, dynamic>> lowData = [];
      List<Map<String, dynamic>> mediumData = [];
      List<Map<String, dynamic>> highData = [];

      for (var item in jsonData) {
        double kqi = item['kqi'];
        if (kqi < -105.0) {
          lowData.add(item);
        } else if (kqi >= lowThreshold && kqi <= highThreshold) {
          mediumData.add(item);
        } else {
          highData.add(item);
        }
      }

      print('Length of low: ${lowData.length}');
      print('Length of medium: ${mediumData.length}');
      print('Length of high: ${highData.length}');

      lowKqiGeoJson = createGeoJson(lowData);
      mediumKqiGeoJson = createGeoJson(mediumData);
      highKqiGeoJson = createGeoJson(highData);

    } catch (e) {
      debugPrint('Error loading JSON data: $e');
    }
  }

  Map<String, dynamic> createGeoJson(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> features = data.map((item) {
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

    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  void addLayer(String sourceId, String layerId, Map<String, dynamic> geoJson, String color) async {
    
    try {

      mapController.addGeoJsonSource(sourceId, geoJson);

      mapController.addCircleLayer(sourceId, layerId, CircleLayerProperties(
        circleColor: color, // < -105 red, -105 -> -101 orange, > -101 lightgreen
        circleRadius: 8,
      ));

    } catch (e) {
      debugPrint('Error adding circle layer: $e');
    }
  }

  void addAllCircleLayers() {
    if(!isLowSelected && !isMediumSelected && !isHighSelected) {
      addLayer('lowKqiGeoJson', 'lowLayer', lowKqiGeoJson, 'red');
      addLayer('mediumKqiGeoJson', 'mediumLayer', mediumKqiGeoJson, 'orange');
      addLayer('highKqiGeoJson', 'highLayer', highKqiGeoJson, 'lightgreen');
      setState(() {
        isLowSelected = !isLowSelected;
        isMediumSelected = !isMediumSelected;
        isHighSelected = !isHighSelected;
      });
    } else if(!isMediumSelected && !isHighSelected) {
        addLayer('mediumKqiGeoJson', 'mediumLayer', mediumKqiGeoJson, 'orange');
        addLayer('highKqiGeoJson', 'highLayer', highKqiGeoJson, 'lightgreen');
        setState(() {
          isMediumSelected = !isMediumSelected;
          isHighSelected = !isHighSelected;
        });
    } else if(!isLowSelected && !isHighSelected) {
        addLayer('lowKqiGeoJson', 'lowLayer', lowKqiGeoJson, 'red');
        addLayer('highKqiGeoJson', 'highLayer', highKqiGeoJson, 'lightgreen');
        setState(() {
          isLowSelected = !isLowSelected;
          isHighSelected = !isHighSelected;
        });
    } else if(!isLowSelected && !isMediumSelected) {
        addLayer('lowKqiGeoJson', 'lowLayer', lowKqiGeoJson, 'red');
        addLayer('mediumKqiGeoJson', 'mediumLayer', mediumKqiGeoJson, 'orange');
        setState(() {
          isLowSelected = !isLowSelected;
          isMediumSelected = !isMediumSelected;
        });
    } else if(!isLowSelected) {
        addLayer('lowKqiGeoJson', 'lowLayer', lowKqiGeoJson, 'red');
        setState(() {
          isLowSelected = !isLowSelected;
        });
    } else if(!isMediumSelected) {
        addLayer('mediumKqiGeoJson', 'mediumLayer', mediumKqiGeoJson, 'orange');
        setState(() {
          isMediumSelected = !isMediumSelected;
        });
    } else if(!isHighSelected) {
        addLayer('highKqiGeoJson', 'highLayer', highKqiGeoJson, 'lightgreen');
        setState(() {
          isHighSelected = !isHighSelected;
        });
    } else {
      return;
    }
  }

  void removeAllCircleLayers() {
    mapController.removeLayer('lowLayer');
    mapController.removeLayer('mediumLayer');
    mapController.removeLayer('highLayer');
    mapController.removeSource('lowKqiGeoJson');
    mapController.removeSource('mediumKqiGeoJson');
    mapController.removeSource('highKqiGeoJson');
    setState(() {
      isLowSelected = !isLowSelected;
      isMediumSelected = !isMediumSelected;
      isHighSelected = !isHighSelected;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      addAllCircleLayers();
                    },
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      removeAllCircleLayers();
                    },
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      
                    },
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.filter_alt_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Text('Low kqi',
                      style: TextStyle(
                        fontSize: 18
                      
                      ),
                    ),
                    Checkbox(
                      checkColor: Colors.white,
                      value: isLowSelected,
                      onChanged: (bool? value) {
                        if(!isLowSelected) {
                          addLayer('lowqiGeoJson', 'lowLayer', mediumKqiGeoJson, 'red');
                          setState(() {
                            isLowSelected = !isLowSelected;
                          });
                        } else {
                          mapController.removeLayer('lowLayer');
                          mapController.removeSource('lowqiGeoJson');
                          setState(() {
                            isLowSelected = !isLowSelected;
                          });
                        }
                      },
                    )
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Medium kqi',
                      style: TextStyle(
                        fontSize: 18
                      
                      ),
                    ),
                    Checkbox(
                      checkColor: Colors.white,
                      value: isMediumSelected,
                      onChanged: (bool? value) {
                        if(!isMediumSelected) {
                          addLayer('mediumKqiGeoJson', 'mediumLayer', mediumKqiGeoJson, 'orange');
                          setState(() {
                            isMediumSelected = !isMediumSelected;
                          });
                        } else {
                          mapController.removeLayer('mediumLayer');
                          mapController.removeSource('mediumKqiGeoJson');
                          setState(() {
                            isMediumSelected = !isMediumSelected;
                          });
                        }
                      },
                    )
                    ],
                  ),
                  Row(
                    children: [
                      const Text('High kqi',
                      style: TextStyle(
                        fontSize: 18
                      
                      ),
                    ),
                    Checkbox(
                      checkColor: Colors.white,
                      value: isHighSelected,
                      onChanged: (bool? value) {
                        if(!isHighSelected) {
                          addLayer('highKqiGeoJson', 'highLayer', highKqiGeoJson, 'lightgreen');
                          setState(() {
                            isHighSelected = !isHighSelected;
                          });
                        } else {
                          mapController.removeLayer('highLayer');
                          mapController.removeSource('highKqiGeoJson');
                          setState(() {
                            isHighSelected = !isHighSelected;
                          });
                        }
                      },
                    )
                    ],
                  ),
                ],
              )
              // FloatingActionButton(
              //   backgroundColor: Colors.blue,
              //   onPressed: () {
              //     removeAllCircleLayers();
              //   },
              //   shape: const CircleBorder(),
              //   child: const Icon(
              //     Icons.filter_alt_rounded,
              //       size: 34,
              //       color: Colors.white,
              //     ),
              //   ),
            ],
          )
        ],
      ),
    );
  }
}