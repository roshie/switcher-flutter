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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
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
                Center(
                  child: Text(
                    roomName.split('_').join(" "),
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Text("Children here")
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

  void _goBack() {
    Navigator.pop(context);
  }
}
