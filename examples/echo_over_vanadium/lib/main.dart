// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


// For me to run this from mojo_run...
// mojo/devtools/common/mojo_run --enable-multiprocess --config-file mojo/tools/configs/sky_desktop --config-alias SKY_SRC=$HOME/sky-checkout/src "mojo:window_manager https://sky/examples/echo_over_vanadium/lib/main.dart"
// mojo/devtools/common/mojo_run --android --enable-multiprocess --config-file mojo/tools/configs/sky --config-alias SKY_SRC=$HOME/sky-checkout/src "mojo:window_manager https://sky/examples/echo_over_vanadium/lib/main.dart"

import 'package:sky/widgets.dart';

import 'dart:async';

import 'package:mojo/core.dart';
import 'package:sky/mojo/embedder.dart' show embedder;
import 'package:mojo/bindings.dart';

//import 'package:mojom/mojo/examples/echo.mojom.dart';
import 'copied_echo.mojom.dart'; // Taken from gen/dart-gen/mojom/lib/examples/echo.mojom.dart; I guess Sky doesn't have these mojom files in their android_Debug though.


class EchoOverVanadiumApp extends App {
  //final EchoProxy echoProxy = new EchoProxy.unbound();
  final ForwardEchoProxy echoProxy = new ForwardEchoProxy.unbound();

  EchoOverVanadiumApp() : super();

  String sentMessage = '';
  String gotMessage = '';
  bool connected = false;

  void _connect() {
    if (connected) return;
    //embedder.connectToService('mojo:echo_server', echoProxy);
    //embedder.connectToService('https://core.mojoapps.io/go_echo_server.mojo', echoProxy); // works with echo_server.mojo, but must use --enable-multiprocess for this one
    embedder.connectToService('https://core.mojoapps.io/go_forward_echo_server.mojo', echoProxy);

    connected = true;
  }

  Future<bool> doEcho() async {
    print('click!');
    _connect();
    String msg = 'Hello ' + gotMessage;
    setState(() {
      sentMessage = msg;
      print('Sending message $sentMessage');
    });
    try {
      //final EchoEchoStringResponseParams result = await echoProxy.ptr.echoString(msg);
      String endpoint = '/@5@wsh@172.17.166.74:33841@cbf4008c9abb8a430b1b455058e1e7ba@s@alexfandrianto@alexfandrianto0.mtv.corp.google.com-18361@@/mojo:go_echo_server/mojo::examples::Echo';
      final ForwardEchoEchoForwardResponseParams result = await echoProxy.ptr.echoForward(msg, endpoint);

      setState(() {
        gotMessage = result.value;
        print('Got message $gotMessage');
      });
    } catch(e) {
      print('Error echoing: ' + e.toString());
      return false;
    }
    return true;
  }

  Future close({bool immediate: false}) async {
    await echoProxy.close(immediate: immediate);
    return;
  }

  Widget build() {
    return new Container(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFF00ACC1)
      ),
      child: new Flex([
        new RaisedButton(
          child: new Text('CLICK ME'),
          onPressed: doEcho
        ),
        new Text('Sent message $sentMessage'),
        new Text('Got message $gotMessage')
      ],
      direction: FlexDirection.vertical)
    );
  }
}

void main() {
  runApp(new EchoOverVanadiumApp());
}