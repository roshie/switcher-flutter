// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';
import 'room.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  // Run App
  runApp(MaterialApp(
    // home: Room(deviceId: "qcGZjp0zrLRX1BUUAAAv"),
    home: Home(),
    theme: ThemeData(fontFamily: 'Poppins'),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Prepare for socket connection
  IO.Socket socket = IO.io(backendURL, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  var availableDevices = <String, dynamic>{'devices': 'loading'};

  bool switch1 = false;
  bool switch2 = false;
  List<Color> activeTile = [
    Color(0xffE37B33),
    Color(0xffE90846),
  ];
  List<Color> inactiveTile = [
    Color(0xff808080).withOpacity(0.15),
    Color(0xff808080).withOpacity(0.15),
  ];
  late List<Color> gradientList;

  @override
  void initState() {
    super.initState();
    gradientList = switch1 ? activeTile : inactiveTile;
    initSocket();
  }

  Future<void> initSocket() async {
    // Connect to node server
    socket.connect();
    socket.onConnect((_) {
      print('Connected to Node server');
      socket.emit('recognize', {'type': 'client'});
    });

    socket.onConnectError((data) {
      print("Error while connecting to Node server");
      print(data);
    });

    // Listen to server
    socket.on('devices', (data) {
      print(data);
      setState(() {
        if (data.isEmpty) {
          availableDevices['devices'] = 'NA';
        } else {
          availableDevices['devices'] = data;
        }
      });
    });

    // While disconnecting...
    socket.onDisconnect((_) => print('disconnected from server'));
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // -----------put your code here Joekin--------------

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/blurBG.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4), BlendMode.softLight),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, left: 10.0),
                  child: TextButton(
                    onPressed: null,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey.shade900,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.home,
                          size: 30,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 100,
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Home',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Control Your Appliances',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: gradientList),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: FaIcon(
                            FontAwesomeIcons.couch,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Living Room",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          "4 devices",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Transform.scale(
                            scale: 1.5,
                            child: Switch(
                              value: switch1,
                              onChanged: (value) {
                                setState(() {
                                  switch1 = value;
                                  gradientList =
                                      value ? activeTile : inactiveTile;
                                });
                              },
                              activeTrackColor: Color(0xffE90846),
                              inactiveTrackColor: Colors.grey,
                              activeColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CustomSwitch {}
