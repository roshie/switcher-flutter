// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';
import 'room.dart';

void main() {
  // Run App
  runApp(MaterialApp(home: Home()));
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

  get scaffoldKey => null;

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
    
    return  Scaffold(      
       
      appBar: AppBar(
      title: const Text("Welcome"),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset("Assets/images/template.jpg")
          ],
        ),

      ),
      
      
      
      
    );
        
        

        
      
    
  }
}
