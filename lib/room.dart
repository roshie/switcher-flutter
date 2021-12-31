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
    socket.onDisconnect((_) => print('disconnected from server'));
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade900,
        body: loadThePage(roomName, switches));
  }

  Widget loadThePage(String roomName, Map<String, dynamic> switches) {
    if (roomName == 'NA') {
      return const Center(
          child: Text(
        "The Device is in offline.",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ));
    } else if (roomName != "loading" && !switches['switches'].isEmpty) {
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black, spreadRadius: 5, blurRadius: 15)
                ],
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
                gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 15.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decorationColor: Colors.white),
                    ),
                    onPressed: _goBack,
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28.0),
                  child: Text(
                    roomName.split('_').join(" "),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 35.0, bottom: 35.0)),
          Column(
            children: switchWidget,
          )
        ],
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
