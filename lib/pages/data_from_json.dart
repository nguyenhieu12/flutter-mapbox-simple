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
  List<Map<String, dynamic>> lowData = [];
  List<Map<String, dynamic>> mediumData = [];
  List<Map<String, dynamic>> highData = [];
  double lowThreshold = -105.0;
  double highThreshold = -101.0;
  int addCircleTime = 0;
  bool isLowSelected = false;
  bool isMediumSelected = false;
  bool isHighSelected = false;
  bool isVisible = false;

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    mapController.onFeatureTapped.add((id, point, coordinates) {
      displayPointData(id, point, coordinates);
    });
  }
  
  void displayPointData(dynamic featureId, Point<double> point, LatLng latLng) {
    var featureData = featuresMap[featureId];
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Point info'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Latitude: ${featureData['lat']}'),
                Text('Longitude: ${featureData['lng']}'),
                Text('District: ${featureData['district']}'),
                Text('KQI: ${featureData['kqi']}'),
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

  Future<void> loadJSONData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/zdt_point_80k.json');
      jsonData = json.decode(jsonString);
      featuresMap = { for (var item in jsonData) item['pCellId']: item };

    } catch (e) {
      debugPrint('Error loading JSON data: $e');
    }
  }

  Future<void> loadGeoJson() async {
    debugPrint('Initial low threshold: $lowThreshold');
    debugPrint('Initial high threshold: $highThreshold');

    for (var item in jsonData) {
     double kqi = item['kqi'];
      if (kqi < lowThreshold) {
        lowData.add(item);
      } else if ((kqi >= lowThreshold) && (kqi <= highThreshold)) {
        mediumData.add(item);
      } else {
        highData.add(item);
      }
    }   

    debugPrint('Length of low: ${lowData.length}');
    debugPrint('Length of medium: ${mediumData.length}');
    debugPrint('Length of high: ${highData.length}');

    lowKqiGeoJson = createGeoJson(lowData);
    mediumKqiGeoJson = createGeoJson(mediumData);
    highKqiGeoJson = createGeoJson(highData);
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

  Future<void> addAllCircleLayers() async {
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

  Future<void> removeAllCircleLayers() async {
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

  void displayThresholdOptions(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    List<double> listLow = [10.0, 20.0, 30.0, 40.0];
    listLow.insert(0, lowThreshold);

    List<double> listHigh = [50.0, 60.0, 70.0, 80.0];
    listHigh.insert(0, highThreshold);

    double lowValue = lowThreshold;
    double highValue = highThreshold;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Choose threshold')),
          content: Container(
            width: screenWidth * 0.8,
            height: screenHeight * 0.3,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DropdownButton<double>(
                      hint: Text(lowThreshold.toString()),
                      value: lowValue,
                      items: listLow.map((value) {
                        return DropdownMenuItem<double>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if(newValue! >= highThreshold) {
                          setState(() {
                            isVisible = true;
                          });
                        } else {
                          
                          setState(() {
                            debugPrint('Old low threshold: $lowThreshold');
                            lowThreshold = newValue;
                            debugPrint('New low threshold: $lowThreshold');
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      menuMaxHeight: screenHeight * 0.35,
                    ),
                    DropdownButton<double>(
                      hint: Text(highThreshold.toString()),
                      value: highValue,
                      items: listHigh.map((value) {
                        return DropdownMenuItem<double>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if(newValue! <= lowThreshold) {
                          setState(() {
                            isVisible = true;
                          });
                        } else {
                          setState(() {
                            debugPrint('Old high threshold: $highThreshold');
                            highThreshold = newValue;
                            debugPrint('New high threshold: $highThreshold');
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      menuMaxHeight: screenHeight * 0.35,
                    ),
                  ],
                ),
                Visibility(
                  visible: isVisible,
                  child: const Text('Low threshold cannot lower than high threshold'),
                )
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
            
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadJSONData();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'JSON Data',
          style: TextStyle(color: Colors.white, fontSize: 26),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(25),
            width: screenWidth * 0.95,
            height: screenHeight * 0.6,
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
                  SizedBox(
                    height: screenHeight * 0.06,
                    child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: () {
                        loadGeoJson();
                        addAllCircleLayers();
                      },
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                  ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: screenHeight * 0.06,
                      child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: () {
                        removeAllCircleLayers();
                      },
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.remove_circle_outline_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: screenHeight * 0.06,
                      child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: () {
                        displayThresholdOptions(context);
                      },
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.filter_alt_outlined,
                          size: 35,
                          color: Colors.white,
                        ),
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
            ],
          )
        ],
      ),
    );
  }
}