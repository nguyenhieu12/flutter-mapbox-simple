import 'package:flutter/material.dart';
import 'package:map_tracking/pages/change_style.dart';
import 'package:map_tracking/pages/circle_layer.dart';
import 'package:map_tracking/pages/data_from_json.dart';
import 'package:map_tracking/pages/vietnam_map.dart';
import 'package:map_tracking/pages/zoom_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width * 0.8;
    const buttonColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Home Page',
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(40, 20, 30, 10),
            width: screenWidth,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ZoomPage()));
              },
              backgroundColor: buttonColor,
              child: const Text(
                'ZoomIn/ZoomOut',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(40, 20, 30, 10),
            width: screenWidth,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeStyle()));
              },
              backgroundColor: buttonColor,
              child: const Text(
                'Change map style',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(40, 20, 30, 10),
            width: screenWidth,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CircleLayer()));
              },
              backgroundColor: buttonColor,
              child: const Text(
                'Add Circle Layer',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(40, 20, 30, 10),
            width: screenWidth,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DataFromJSON()));
              },
              backgroundColor: buttonColor,
              child: const Text(
                'Data from JSON',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(40, 20, 30, 10),
            width: screenWidth,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VietnamMap()));
              },
              backgroundColor: buttonColor,
              child: const Text(
                'Vietnam Map',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ),
        ]
      ),
    );
  }
}
