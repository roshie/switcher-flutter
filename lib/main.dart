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
    // home: Room(deviceId: "5a8vCih28D8ve0LkAAAB"),
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

  Map<String, dynamic> availableDevices = <String, dynamic>{};
  String actState = "loading";

  List<Color> activeTile = [
    Color(0xffE37B33),
    Color(0xffE90846),
  ];
  List<Color> inactiveTile = [
    Color(0xff808080).withOpacity(0.15),
    Color(0xff808080).withOpacity(0.15),
  ];

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  Future<void> initSocket() async {
    // Connect to Flask server
    socket.connect();
    socket.onConnect((_) {
      print('Connected to Flask server');
      socket.emit('recognize', {'type': 'client'});
    });

    socket.onConnectError((data) {
      print("Error while connecting to Flask server");
      setState(() {
        actState = "NoNetworkAccess";
      });
      print(data);
    });

    // Listen to server
    socket.on('devices', (data) {
      print(data);
      setState(() {
        if (data.isEmpty) {
          actState = 'NA';
        } else {
          availableDevices = data;
          actState = "available";
        }
      });
    });

    // While disconnecting...
    socket.onDisconnect((_) {
      print('disconnected from server');
      setState(() {
        actState = "NoNetworkAccess";
      });
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/blurBG.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), BlendMode.softLight),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
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
                ...loadThePage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> loadThePage() {
    if (actState == "NA") {
      return DisplayInfoWidget("You Have No Rooms Online. ", actState);
    } else if (actState == "NoNetworkAccess") {
      return DisplayInfoWidget(
          "The device is Offine. Please go back online. ", actState);
    } else if (actState == "available") {
      List<Widget> col = [];

      List<Widget> row = [];

      availableDevices.forEach((name, data) {
        if (row.length == 2) {
          col.add(Row(
            children: row,
          ));
          row = [];
        }

        int noOfSwitches = 0;
        int turnedOn = 0;

        data["switches"].forEach((switchName, val) {
          noOfSwitches++;
          if (val == 1) turnedOn++;
        });

        row.add(
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Room(
                      deviceId: name,
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: turnedOn > 0 ? activeTile : inactiveTile),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: getRelevantIcon(data["name"])),
                    Text(
                      data["name"].split("_").join(" "),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      "$noOfSwitches devices" +
                          (turnedOn > 0 ? ", $turnedOn turned On" : ""),
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
                          value: turnedOn > 0 ? true : false,
                          onChanged: (value) {
                            setAllDevices(name, value);
                            setState(() {
                              turnedOn = value ? noOfSwitches : 0;
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
          ),
        );
      });
      col.add(Row(
        children: row,
      ));
      return col;
    }
    return [
      Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 80.0),
              child: Transform.scale(
                scale: 2,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              ),
            ),
            Center(
              child: Text(
                "Loading...",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          ])
    ];
  }

  void setAllDevices(String name, bool value) {
    var result = {};
    availableDevices[name]["switches"].forEach((switchName, switchVal) {
      result[switchName] = value ? 1 : 0;
    });
    setState(() {
      availableDevices[name]["switches"] = result;
    });

    socket.emit("switch", {'deviceId': name, "switches": result});
  }

  List<Widget> DisplayInfoWidget(String message, String type) {
    return [
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Icon(
            type == "NoNetworkAccess"
                ? Icons.wifi_off_outlined
                : Icons.error_outline,
            color: Colors.grey.shade700,
            size: 60,
          ),
        ),
      ),
      Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    ];
  }

  Widget getRelevantIcon(String type) {
    if (type == "Living_Room") {
      return FaIcon(
        FontAwesomeIcons.couch,
        size: 30,
        color: Colors.white,
      );
    } else if (type == "Kitchen") {
      return FaIcon(
        Icons.kitchen,
        size: 30,
        color: Colors.white,
      );
    } else if (type == "Bathroom") {
      return Icon(
        FontAwesomeIcons.bath,
        size: 30,
        color: Colors.white,
      );
    } else if (type == "Bedroom") {
      return FaIcon(
        FontAwesomeIcons.bed,
        size: 30,
        color: Colors.white,
      );
    } else if (type == "Dining_Room") {
      return FaIcon(
        FontAwesomeIcons.utensils,
        size: 30,
        color: Colors.white,
      );
    } else if (type == "Parking") {
      return FaIcon(
        FontAwesomeIcons.utensilSpoon,
        size: 30,
        color: Colors.white,
      );
    }

    return FaIcon(
      FontAwesomeIcons.star,
      size: 30,
      color: Colors.white,
    );
  }
}
