// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';

class Room extends StatefulWidget {
  final String deviceId;
  const Room({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<Room> createState() => _RoomState();
}

class _RoomState extends State<Room> with SingleTickerProviderStateMixin {
  // Prepare for socket connection
  IO.Socket socket = IO.io(backendURL, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  // Pre-defined vars
  String roomName = 'loading';
  Map<String, dynamic> switches = <String, dynamic>{'switches': {}};
  late TabController _tabController;
  int applicanceLength = 1;

  List<Color> activeTile = [
    Color(0xffE37B33),
    Color(0xffE90846),
  ];
  List<Color> inactiveTile = [
    Color(0xff808080).withOpacity(0.3),
    Color(0xff808080).withOpacity(0.3),
  ];

  @override
  void initState() {
    super.initState();
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
      setState(() {
        roomName = "NoNetworkAccess";
      });
      print(data);
    });

    // Listen to server
    socket.on('devices', (data) {
      print(data);
      int len = 0;
      setState(() {
        if (data.isEmpty || !data.containsKey(widget.deviceId)) {
          roomName = 'NA';
        } else {
          switches['switches'] = data[widget.deviceId]['switches'];
          roomName = data[widget.deviceId]['name'];
          switches['switches'].forEach((name, value) {
            len++;
          });
          applicanceLength = len;
        }
      });

      _tabController = TabController(length: applicanceLength, vsync: this);
    });

    // While disconnecting...
    socket.onDisconnect((_) {
      print('disconnected from server');
      setState(() {
        roomName = "NoNetworkAccess";
      });
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
    _tabController.dispose();
  }

  void switchOnOff(name, value) {
    socket.emit("switch", {
      'deviceId': widget.deviceId,
      "switchName": name,
      "toggleState": value
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey.shade900,
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
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30.0, left: 10.0),
                child: TextButton(
                  onPressed: _goBack,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade900,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 20, top: 15.0, bottom: 15.0, right: 12.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: loadThePage(roomName, switches)),
            ],
          )),
    );
  }

  Widget loadThePage(String roomName, Map<String, dynamic> switches) {
    // If the room is offline
    if (roomName == 'NA') {
      return DisplayInfoWidget(
          "Uh Oh! Seems Like the controller for the room is Offline.",
          roomName);
    }

    // If no network access
    else if (roomName == 'NoNetworkAccess') {
      return DisplayInfoWidget(
          "The device is Offine. Please go back online. ", roomName);
    }

    // If online
    else if (roomName != "loading" &&
        roomName != "NoNetworkAccess" &&
        !switches['switches'].isEmpty) {
      List<Widget> applianceTabs = [];
      List<Widget> applianceContent = [];

      switches['switches'].forEach((name, value) {
        Widget tab = Container(
          width: 80,
          height: 80,
          child: Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              name.split("_").join(" "),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          )),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                100,
              ),
              color: Colors.grey.withOpacity(0.075),
              border: Border.all(color: Colors.grey.shade900)),
        );

        Widget tabContent = Center(
            child: Container(
          height: 200,
          width: 200,
          child: Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  switches["switches"][name] =
                      switches["switches"][name] == 1 ? 0 : 1;
                });
                try {
                  switchOnOff(name, switches["switches"][name]);
                } catch (a) {
                  // print(a);
                }
              },
              child: Container(
                height: 190,
                width: 190,
                alignment: Alignment.center,
                child: Text(
                  switches['switches'][name] == 1 ? "On" : "Off",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.grey.shade900, Colors.black],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight),
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: switches['switches'][name] == 1
                      ? activeTile
                      : inactiveTile,
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight),
              borderRadius: BorderRadius.circular(100)),
        ));

        applianceTabs.add(tab);
        applianceContent.add(tabContent);
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName.split("_").join(" "),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  applicanceLength.toString() + ' Devices',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // give the tab bar a height [can change hheight to preferred height]
          Container(
            height: 80,
            child: TabBar(
              controller: _tabController,
              // give the indicator a decoration (color and border radius)
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    100,
                  ),
                  gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        Color(0xffE37B33),
                        Color(0xffE90846),
                      ])),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: Colors.transparent,

              tabs: applianceTabs,
            ),
          ),
          // tab bar view here
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: applianceContent,
            ),
          ),
        ],
      );
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 35.0),
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          Center(
            child: Text(
              "Loading...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        ]);
  }

  void _goBack() {
    Navigator.pop(context);
  }

  Widget DisplayInfoWidget(String message, String type) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          Expanded(
            child: Icon(
              type == "NoNetworkAccess"
                  ? Icons.wifi_off_outlined
                  : Icons.error_outline,
              color: Colors.grey.shade700,
              size: 60,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
