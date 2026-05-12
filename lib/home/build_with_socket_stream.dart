import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// STEP1:  Stream setup
class StreamSocket {
  final _socketResponse = StreamController<String>();

  void Function(String) get addResponse => _socketResponse.sink.add;

  Stream<String> get getResponse => _socketResponse.stream;

  void dispose() {
    _socketResponse.close();
  }
}

StreamSocket streamSocket = StreamSocket();

//STEP2: Add this function in main function in main.dart file and add incoming data to the stream
void connectAndListen() {
  IO.Socket socket = IO.io(
    'https://api.ambufast.com/notification',
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({
          'token': 'dbd283689ecb70182703123f9bcde41ca9e24d79',
        })
        .enableAutoConnect()
        .build(),
  );

  socket.onConnect((_) {
    print('connect');
    socket.emit('msg', 'test');
  });

  //When an event received from server, data is added to the stream
  socket.on('event', (data) => streamSocket.addResponse);
  socket.onDisconnect((data) {
    print('disconnect');
    streamSocket.addResponse('Disconnected from server \n$data');
  });
  socket.onError((error) {
    print('error: $error');
    streamSocket.addResponse('Error: $error');
  });
  socket.onConnectError((error) {
    print('connect error: $error');
    streamSocket.addResponse('Connect error: $error');
  });
  socket.onAny((event, data) => print('onAny: $event: $data'));

  socket.connect();

  socket.emit('ping', '123');
  socket.onPong((data) {
    print('pong: $data');
    streamSocket.addResponse('Received pong: $data');
  });
  socket.onPong((data) {
    print('pong: $data');
    streamSocket.addResponse('Received pong: $data');
  });

  socket.on('notification:new', (data) {
    log('[onNotificationNew] \ndata: $data', name: 'SocketService');
    streamSocket.addResponse('New notification: $data');
  });
}

//Step3: Build widgets with StreamBuilder

class BuildWithSocketStream extends StatelessWidget {
  BuildWithSocketStream({super.key}) {
    connectAndListen();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: streamSocket.getResponse,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return Container(
            alignment: Alignment.center,
            child: Text(snapshot.data ?? 'Nothing received yet'),
          );
        },
      ),
    );
  }
}
