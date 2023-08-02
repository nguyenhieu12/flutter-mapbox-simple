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
  bool _isNorthDomainSelected = false;
  bool _isCentralDomainSelected = false;
  bool _isSouthDomainSelected = false;
  bool _isAllDomainsSeletecd = false;
  

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    initMap();
    
    mapController.onFeatureTapped.add((id, point, coordinates) {
      handleProvinceTapped(id);
    });
  }

  void handleProvinceTapped(dynamic id) {
    if (oldId.isEmpty) {
      updateLayer(id);
    }
    else if(id == oldId) {
      return;
    } else {
      removeAndRenderLayer(id);
    }
  }

  void removeAndRenderLayer(id) {

    mapController.removeLayer('layerId-$id');
    mapController.removeSource('sourceId-$id');

    Map<String, dynamic> currentFeatureCollection = {
      "type": "FeatureCollection",
      "features": [provinceData[id]],
    };

    mapController.addGeoJsonSource('sourceId-$id', currentFeatureCollection);
    mapController.addLayer('sourceId-$id', 'layerId-$id', const FillLayerProperties(
      fillColor: 'lightgreen',
      fillOutlineColor: 'black',
    ));

    mapController.removeLayer('layerId-$oldId');
    mapController.removeSource('sourceId-$oldId');

    Map<String, dynamic> oldFeatureCollection = {
      "type": "FeatureCollection",
      "features": [provinceData[oldId]],
    };

    mapController.addGeoJsonSource('sourceId-$oldId', oldFeatureCollection);
    mapController.addLayer('sourceId-$oldId', 'layerId-$oldId', const FillLayerProperties(
      fillColor: 'grey',
      fillOutlineColor: 'black',
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
      fillColor: 'lightgreen',
      fillOutlineColor: 'black',
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

      // geoJsonData['features'] = features;

      provinceData = { for (var item in features) item['id'] : item };

      String domains = await rootBundle.loadString('assets/province_domain.json');

      Map<String, dynamic> domaninsData = json.decode(domains);

      List<dynamic> domainName = ['Miền Bắc', 'Miền Trung', 'Miền Nam'];

      List<dynamic> provinces = [];

      for(int i = 0; i < domainName.length; i++) {
        provinces.add(domaninsData[domainName[i]]);
      }

      // for(int i = 0; i < provinces.length; i++) {
      //   for(int j = 0; j < features.length; j++) {
      //     if()
      //   }
      // }

      for (int i = 0; i < features.length; i++) {
        Map<String, dynamic> feature = features[i];
        List<Map<String, dynamic>> featureList = [feature];

        Map<String, dynamic> featureCollection = {
          "type": "FeatureCollection",
          "features": featureList,
        };

        mapController.addGeoJsonSource('sourceId-${feature['id']}', featureCollection);

        mapController.addLayer('sourceId-${feature['id']}', 'layerId-${feature['id']}', const FillLayerProperties(
          fillColor: 'grey',
          fillOutlineColor: 'black',
        ));

      }
    } catch (e) {
      debugPrint('Error adding layer: $e');
    }
  }

  void filterAndRemoveByDomain(String domain, String? color) async {
    
    String domains = await rootBundle.loadString('assets/province_domain.json');

    Map<String, dynamic> domaninsData = json.decode(domains);

    List<dynamic> provinces = domaninsData[domain];

    List<dynamic> features = geoJsonData['features'];

    for(int i = 0; i < provinces.length; i++) { 
      for(int j = 0; j < features.length; j++) {
        if(provinces[i] == features[j]['properties']['Name_VI']) {
          
          String id = features[j]['id'];

          await mapController.removeLayer('layerId-$id');
          await mapController.removeSource('sourceId-$id');

          Map<String, dynamic> currentFeatureCollection = {
            "type": "FeatureCollection",
            "features": [provinceData[id]],
          };

          await mapController.addGeoJsonSource('sourceId-$id', currentFeatureCollection);
          await mapController.addLayer('sourceId-$id', 'layerId-$id', FillLayerProperties(
            fillColor: (color ?? ((domain == 'Miền Bắc') ? 'lightgreen' : (domain == 'Miền Trung' ? 'lightyellow' : 'lightpink'))) ,
            fillOutlineColor: 'black',
          ));
        }
      }    
    }
  }

  void displayMenuOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Text('Lọc theo miền',
              style: TextStyle(
                fontSize: 24
              ),
            ),
          ),
          content: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Miền Bắc',
                    style: TextStyle(
                      fontSize: 20
                    ),
                  ),
                  Checkbox(
                    value: _isNorthDomainSelected,
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      if(!_isNorthDomainSelected) {
                        filterAndRemoveByDomain('Miền Bắc', null);
                        _isNorthDomainSelected = value!;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      } else {
                        filterAndRemoveByDomain('Miền Bắc', 'grey');
                        _isNorthDomainSelected = value!;
                        _isAllDomainsSeletecd = value;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      }
                    }
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Miền Trung',
                    style: TextStyle(
                      fontSize: 20
                    ),
                  ),
                  Checkbox(
                    value: _isCentralDomainSelected,
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      if(!_isCentralDomainSelected) {
                        filterAndRemoveByDomain('Miền Trung', null);
                        _isCentralDomainSelected = value!;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      } else {
                        filterAndRemoveByDomain('Miền Trung', 'grey');
                        _isCentralDomainSelected = value!;
                        _isAllDomainsSeletecd = value;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      }
                    }
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Miền Nam',
                    style: TextStyle(
                      fontSize: 20
                    ),
                  ),
                  Checkbox(
                    value: _isSouthDomainSelected,
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      if(!_isSouthDomainSelected) {
                        filterAndRemoveByDomain('Miền Nam', null);
                        _isSouthDomainSelected = value!;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      } else {
                        filterAndRemoveByDomain('Miền Nam', 'grey');
                        _isSouthDomainSelected = value!;
                        _isAllDomainsSeletecd = value;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      }
                    }
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Tất cả',
                    style: TextStyle(
                      fontSize: 20
                    ),
                  ),
                  Checkbox(
                    value: _isAllDomainsSeletecd,
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      if(!_isAllDomainsSeletecd) {
                        filterAndRemoveByDomain('Miền Bắc', null);
                        filterAndRemoveByDomain('Miền Trung', null);
                        filterAndRemoveByDomain('Miền Nam', null);
                        _isNorthDomainSelected = value!;
                        _isCentralDomainSelected = value;
                        _isSouthDomainSelected = value;
                        _isAllDomainsSeletecd = value;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      } else {
                        filterAndRemoveByDomain('Miền Bắc', 'grey');
                        filterAndRemoveByDomain('Miền Trung', 'grey');
                        filterAndRemoveByDomain('Miền Nam', 'grey');
                        _isNorthDomainSelected = value!;
                        _isCentralDomainSelected = value;
                        _isSouthDomainSelected = value;
                        _isAllDomainsSeletecd = value;
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      }
                    }
                  )
                ],
              )
            ],
          ),
          actions: [
            Center(
              child: Container(
                decoration: const BoxDecoration(
                  boxShadow: null
                ),
                width: 100,
                height: 35,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Áp dụng',
                    style: TextStyle(
                      fontSize: 16
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWitdh = MediaQuery.of(context).size.width;

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
      body: Stack(
        children: [
          MapboxMap(
            accessToken: 'sk.eyJ1IjoiaGlldW5tMTIxMiIsImEiOiJjbGptanBtMmExNmhjM3FrMjE1bHZpdzVmIn0.TwqdH0eYn4xy34qcyFWgkQ',
            styleString: 'mapbox://styles/hieunm1212/clkq6rt3s00cb01ph7e3z6dtx',
            initialCameraPosition: const CameraPosition(
              target: LatLng(16.102622, 105.690185),
              zoom: 5
            ),
            onMapCreated: _onMapCreated,
          ),
          Align(
            alignment: Alignment.topRight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: screenWitdh * 0.12,
                    height: screenWitdh * 0.12,
                    child: FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.blue.shade500,
                      onPressed: () async {
                        displayMenuOptions();
                      },
                      child: const Icon(
                        Icons.filter_alt_rounded,
                          color: Colors.white,  
                          size: 28,
                        ),
                    ),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(10.0),
                //   child: SizedBox(
                //     width: screenWitdh * 0.12,
                //     height: screenWitdh * 0.12,
                //     child: FloatingActionButton(
                //       shape: const CircleBorder(),
                //       backgroundColor: Colors.blue.shade500,
                //       onPressed: () async {
                //         initMap();
                //       },
                //       child: const Icon(
                //         Icons.swap_horizontal_circle_sharp,
                //           color: Colors.white,  
                //           size: 28,
                //         ),
                //     ),
                //   ),
                // ),
              ],
            )       
          )
        ],
      )
    );
  }
}