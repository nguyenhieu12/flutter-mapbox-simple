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
  Map<String, dynamic> provinceData = {};
  Uuid uuid = const Uuid();
  bool _isNorthDomainSelected = false;
  bool _isCentralDomainSelected = false;
  bool _isSouthDomainSelected = false;
  bool _isAllDomainsSeletecd = false;
  List<dynamic> domainName = ['Miền Bắc', 'Miền Trung', 'Miền Nam'];
  Map<String, dynamic> geoJsonByDomain = {};
  

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    initMap();
    
    mapController.onFeatureTapped.add((id, point, coordinates) {
      // debugPrint('Province: ${provinceData[id]['properties']['Name_VI']}');
      handleProvinceTapped(id);
    });
  }

  void handleProvinceTapped(dynamic id) {

    showModalBottomSheet(
      context: context,
      builder: ((context) {
        return Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Center(
                child: Text('Thông tin tỉnh',
                  style: TextStyle(
                    fontSize: 22
                  ),
                ),
              ),
              Center(
                child: Text('Tỉnh: ${provinceData[id]['properties']['Name_VI']}',
                  style: const TextStyle(
                    fontSize: 20
                  ),
                ),
              )
            ]
          ),
        );
      }),
    );

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
      fillColor: 'red',
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
      fillColor: 'lightgrey',
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
      fillColor: 'red',
      fillOutlineColor: 'black',
    ));

    debugPrint('BBB: sourceId-$id');
    debugPrint('BBB: layerId-$id');

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

      String domains = await rootBundle.loadString('assets/province_domain.json');

      Map<String, dynamic> domaninsData = json.decode(domains);

      List<List<dynamic>> provinces = [];

      for(int i = 0; i < domainName.length; i++) {
        provinces.add(domaninsData[domainName[i]]);
      }

      for(int i = 0; i < provinces.length; i++) {
        List<Map<String, dynamic>> listFeatures = [];

        for(int j = 0; j < provinces[i].length; j++) {
          for(int k = 0; k < features.length; k++) {
            if(provinces[i][j] == features[k]['properties']['Name_VI']) {
              listFeatures.add(features[k]);
            }
          }
        }

        Map<String, dynamic> featureCollection = {
          "type": "FeatureCollection",
          "features": listFeatures,
        };

        geoJsonByDomain[domainName[i]] = listFeatures;

        await mapController.addGeoJsonSource('sourceId-${domainName[i]}', featureCollection);

        await mapController.addLayer('sourceId-${domainName[i]}', 'layerId-${domainName[i]}', const FillLayerProperties(
          fillColor: 'lightgrey',
          fillOutlineColor: 'black',
        ));

        debugPrint('AAA: sourceId-${domainName[i]}');
        debugPrint('AAA: layerId-${domainName[i]}');
      }

    } catch (e) {
      debugPrint('Error adding layer: $e');
    }
  }

  void filterAndRemoveByDomain(String domain, String? color) async {
    
    await mapController.removeLayer('layerId-$domain');
    await mapController.removeSource('sourceId-$domain');

    Map<String, dynamic> featureCollection = {
      "type": "FeatureCollection",
      "features": geoJsonByDomain[domain],
    };

    await mapController.addGeoJsonSource('sourceId-$domain', featureCollection);
    await mapController.addLayer('sourceId-$domain', 'layerId-$domain', FillLayerProperties(
      fillColor: (color ?? ((domain == 'Miền Bắc') ? 'lightgreen' : (domain == 'Miền Trung' ? 'lightyellow' : 'lightpink'))) ,
      fillOutlineColor: 'black',
    ));

    oldId = '';
    
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
                        if(_isCentralDomainSelected && _isSouthDomainSelected) {
                          _isAllDomainsSeletecd = value;
                        }
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      } else {
                        filterAndRemoveByDomain('Miền Bắc', 'lightgrey');
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
                        if(_isNorthDomainSelected && _isSouthDomainSelected) {
                          _isAllDomainsSeletecd = value;
                        }
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      } else {
                        filterAndRemoveByDomain('Miền Trung', 'lightgrey');
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
                        if(_isNorthDomainSelected && _isCentralDomainSelected) {
                          _isAllDomainsSeletecd = value;
                        }
                        setState(() {
                          Navigator.pop(context);
                          displayMenuOptions();
                        });
                      } else {
                        filterAndRemoveByDomain('Miền Nam', 'lightgrey');
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
                        filterAndRemoveByDomain('Miền Bắc', 'lightgrey');
                        filterAndRemoveByDomain('Miền Trung', 'lightgrey');
                        filterAndRemoveByDomain('Miền Nam', 'lightgrey');
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
    double screenHeight = MediaQuery.of(context).size.height;

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
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: screenHeight * 0.75,
                child: MapboxMap(
                  accessToken: 'sk.eyJ1IjoiaGlldW5tMTIxMiIsImEiOiJjbGptanBtMmExNmhjM3FrMjE1bHZpdzVmIn0.TwqdH0eYn4xy34qcyFWgkQ',
                  styleString: 'mapbox://styles/hieunm1212/clkq6rt3s00cb01ph7e3z6dtx',
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(15.102622, 105.690185),
                    zoom: 4.6
                  ),
                  onMapCreated: _onMapCreated,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(    
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 158, 255, 47),
                          shape: BoxShape.circle
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Miền Bắc',
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 230, 44),
                          shape: BoxShape.circle
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Miền Trung',
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(97, 255, 94, 118),
                          shape: BoxShape.circle
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Miền Nam',
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ],
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Được chọn',
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Không được chọn',
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
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