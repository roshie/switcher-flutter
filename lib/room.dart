// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';

class Room extends StatefulWidget {
  final String deviceId;
  const Room({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<Room> createState() => _RoomState();
}

class _RoomState extends State<Room> {
  // Prepare for socket connection
  IO.Socket socket = IO.io(backendURL, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  // Pre-defined vars
  String roomName = 'loading';
  Map<String, dynamic> switches = <String, dynamic>{'switches': {}};

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
      setState(() {
        if (data.isEmpty || !data.containsKey(widget.deviceId)) {
          roomName = 'NA';
        } else {
          switches['switches'] = data[widget.deviceId]['switches'];
          roomName = data[widget.deviceId]['name'];
        }
      });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey.shade900,
      body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/blurBG.jpg"),
              fit: BoxFit.cover,
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
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          children: [
            Expanded(
              child: Icon(
                Icons.error_outline,
                color: Colors.grey.shade700,
                size: 60,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "Uh Oh! Seems Like the controller for the room is Offline.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If no network access
    else if (roomName == 'NoNetworkAccess') {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          children: [
            Expanded(
              child: Icon(
                Icons.wifi_off_outlined,
                color: Colors.grey.shade700,
                size: 60,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "The device is Offine. Please go back online. ",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If online
    else if (roomName != "loading" &&
        roomName != "NoNetworkAccess" &&
        !switches['switches'].isEmpty) {
      List<Widget> switchWidget = [];

      switches['switches'].forEach((name, value) {
        Widget switchRow = Padding(
          padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
          child: Container(
            height: 100,
            decoration: const BoxDecoration(color: Colors.black12),
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    name.split("_").join(" "),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Transform.scale(
                    scale: 1.5,
                    child: Switch(
                        value: value == 1 ? true : false,
                        inactiveTrackColor: Colors.grey.shade400,
                        onChanged: (bool val) {
                          _toggleSwitch(name, val);
                        }),
                  )
                ],
              ),
            ),
          ),
        );

        switchWidget.add(switchRow);
      });

      // If loading
      return Padding(
        padding: const EdgeInsets.only(top: 35.0, bottom: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switchWidget,
        ),
      );
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Padding(
            padding: EdgeInsets.all(18.0),
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

  void _toggleSwitch(name, val) {
    setState(() {
      switches['switches'][name] = val ? 1 : 0;
    });
    socket.emit('switch', {
      'switchName': name,
      'toggleState': val ? 1 : 0,
      'deviceId': widget.deviceId
    });
  }

  void _goBack() {
    Navigator.pop(context);
  }
}
