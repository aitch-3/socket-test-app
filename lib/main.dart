import 'dart:async';
import 'dart:convert';
import 'package:msgpack_dart/msgpack_dart.dart';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketChannel _channel;
  bool _connected = false;
  StreamSubscription _socketSubscription;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo;
  String _token;

  final _message$ = BehaviorSubject<Map<dynamic, dynamic>>();

  // @override
  // Future<void> initState() async {
  //   androidInfo = await deviceInfo.androidInfo;

  //   print(androidInfo.toString());
  //   print(androidInfo.version);
  //   print(androidInfo.board);
  //   print(androidInfo.bootloader);
  //   print(androidInfo.brand);
  //   print(androidInfo.device);
  //   print(androidInfo.display);
  //   print(androidInfo.fingerprint);
  //   print(androidInfo.hardware);
  //   print(androidInfo.host);
  //   print(androidInfo.id);
  //   print(androidInfo.manufacturer);
  //   print(androidInfo.model);
  //   print(androidInfo.product);
  //   print(androidInfo.supported32BitAbis);
  //   print(androidInfo.supported64BitAbis);
  //   print(androidInfo.supportedAbis);
  //   print(androidInfo.tags);
  //   print(androidInfo.type);
  //   print(androidInfo.isPhysicalDevice);
  //   print(androidInfo.androidId);

  //   super.initState();
  // }

  Future<void> _getDeviceInfo() async {
    androidInfo = await deviceInfo.androidInfo;

    print(androidInfo.toString());
    print(androidInfo.version);
    print(androidInfo.board); // exynos7884B
    print(androidInfo.bootloader); // A202KKKU4BTF2
    print(androidInfo.brand); // samsung
    print(androidInfo.device); // a20e
    print(androidInfo.display); // QP1A.190711.020.A202KKKU4BTF2
    print(androidInfo
        .fingerprint); // amsung/a20ektt/a20e:10/QP1A.190711.020/A202KKKU4BTF2:user/release-keys
    print(androidInfo.hardware); //exynos7884B
    print(androidInfo.host); // SWDI3223
    print(androidInfo.id); // QP1A.190711.020
    print(androidInfo.manufacturer); // samsung
    print(androidInfo.model); // SM-A202K
    print(androidInfo.product); // a20ektt
    print(androidInfo.supported32BitAbis); // [armeabi-v7a, armeabi]
    print(androidInfo.supported64BitAbis); // [arm64-v8a]
    print(androidInfo.supportedAbis); // [arm64-v8a, armeabi-v7a, armeabi]
    print(androidInfo.tags); // release-keys
    print(androidInfo.type); // user
    print(androidInfo.isPhysicalDevice); // true
    print(androidInfo.androidId); // d4ccbd0fc6604815
  }

  @override
  void initState() {
    _getDeviceInfo();
    super.initState();
  }

  void _connectSocket() {
    if (_connected) {
      if (_channel != null) {
        _channel.sink.close();
        _channel = null;

        _socketSubscription?.cancel();
        _socketSubscription = null;

        setState(() {
          _connected = false;
        });
      }
    } else {
      _channel = IOWebSocketChannel.connect('ws://192.168.0.34:1000',
          pingInterval: Duration(seconds: 2),
          headers: {
            'gateway-uuid': androidInfo.androidId,
            'client-type': 'gateway',
          });
      _listenSocketEvents(_channel);
      setState(() {
        _connected = true;
      });
    }
  }

  void _listenSocketEvents(WebSocketChannel channel) {
    print('----testpiotn1-----');

    _socketSubscription = channel.stream.listen(
      (onData) {
        print('---cehckpiotn1---');
        print(onData);
        Map<dynamic, dynamic> message = deserialize(onData);
        print(message);
        print(message.runtimeType);
        _message$.add(message);

        if (message['type'] == 'initialization') {
          _token = message['data']['token'];
        }
      },
      onError: (error) {
        print('---cehckpiotn2---');
        print(error);

        _message$.add(null);
        setState(() {
          _connected = false;
        });
      },
      onDone: () {
        print('---cehckpiotn3---');
        _message$.add(null);
        setState(() {
          _connected = false;
        });
      },
      cancelOnError: true,
    );
  }

  void _send() {
    if (_channel != null) {
      List<int> _converedData =
          serialize({'type': 'test', 'token': _token, 'data': 'a'});
      List<int> _serializedData = List.of(_converedData);

      _channel.sink.add(_serializedData);
    }
  }

  void _send3() {
    if (_channel != null) {
      List<int> _converedData =
          serialize({'type': 'test', 'token': _token, 'data': 'b'});
      List<int> _serializedData = List.of(_converedData);

      _channel.sink.add(_serializedData);
    }
  }

  void _send2() {
    if (_channel != null) {
      List<int> _converedData =
          serialize({'type': 'test', 'token': _token + 'a', 'data': 'b'});
      List<int> _serializedData = List.of(_converedData);

      _channel.sink.add(_serializedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(_connected ? 'Socket Connected' : 'Socket Disconnected'),
                StreamBuilder(
                  stream: _message$,
                  builder: (
                    context,
                    AsyncSnapshot<Map<dynamic, dynamic>> snapshot,
                  ) {
                    if (snapshot.hasData) {
                      return Container(
                        child: Text(json.encode(snapshot.data)),
                      );
                    }

                    return Container();
                  },
                ),
              ],
            ),
          ),
          Positioned(
            width: MediaQuery.of(context).size.width,
            top: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RaisedButton(
                  onPressed: _connectSocket,
                  child: Text(_connected ? 'Disconnect' : 'Connect'),
                ),
                RaisedButton(
                  onPressed: _connected ? _send : null,
                  child: Text('Send'),
                ),
                RaisedButton(
                  onPressed: _connected ? _send3 : null,
                  child: Text('Send2'),
                ),
                RaisedButton(
                  onPressed: _connected ? _send2 : null,
                  child: Text('Wrong Data'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
