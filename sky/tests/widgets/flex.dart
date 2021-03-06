// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets.dart';

import '../resources/display_list.dart';

class TestApp extends App {
  Widget build() {
    return new Container(
      padding: new EdgeDims.all(50.0),
      child: new Row([
          new Card(
            child: new Container(
              width: 300.0,
              height: 500.0,
              child: new Column([
                  new Text('TOP'),
                  new Flexible(
                    child: new Container(
                      decoration: new BoxDecoration(backgroundColor: new Color(0xFF509050)),
                      child: new Column([new Text('bottom')],
                        alignItems: FlexAlignItems.stretch
                      )
                    )
                  )
                ],
                alignItems: FlexAlignItems.stretch
              )
            )
          ),
          new Card(
            child: new Container(
              width: 300.0,
              height: 500.0,
              child: new Column([
                  new Flexible(
                    child: new Container(
                      decoration: new BoxDecoration(backgroundColor: new Color(0xFF509050)),
                      child: new Column([new Text('top')],
                        alignItems: FlexAlignItems.stretch
                      )
                    )
                  ),
                  new Text('BOTTOM')
                ],
                alignItems: FlexAlignItems.stretch
              )
            )
          )
        ]
      )
    );
  }
}

main() async {
  TestRenderView renderViewOverride = new TestRenderView();
  TestApp app = new TestApp();
  runApp(app, renderViewOverride: renderViewOverride);
  await renderViewOverride.checkFrame();
  renderViewOverride.endTest();
}
