// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

class Measurement extends FitnessItem {
  Measurement({ DateTime when, this.weight }) : super(when: when);
  Measurement.fromJson(Map json) : super.fromJson(json), weight = json['weight'];

  final double weight;

  // TODO(jackson): Internationalize
  String get displayWeight => "${weight.toStringAsFixed(1)} lbs";

  @override
  Map toJson() {
    Map json = super.toJson();
    json['weight'] = weight;
    json['type'] = runtimeType.toString();
    return json;
  }

  FitnessItemRow toRow({ FitnessItemHandler onDismissed }) {
    return new MeasurementRow(measurement: this, onDismissed: onDismissed);
  }
}

class MeasurementRow extends FitnessItemRow {
  MeasurementRow({ Measurement measurement, FitnessItemHandler onDismissed })
    : super(item: measurement, onDismissed: onDismissed);

  Widget buildContent() {
    Measurement measurement = item;
    List<Widget> children = [
      new Flexible(
        child: new Text(
          measurement.displayWeight,
          style: Theme.of(this).text.subhead
        )
      ),
      new Flexible(
        child: new Text(
          measurement.displayDate,
          style: Theme.of(this).text.caption.copyWith(textAlign: TextAlign.right)
        )
      )
    ];
    return new Row(
      children,
      alignItems: FlexAlignItems.baseline,
      textBaseline: DefaultTextStyle.of(this).textBaseline
    );
  }
}

class MeasurementDateDialog extends StatefulComponent {
  MeasurementDateDialog({ this.navigator, this.previousDate });

  Navigator navigator;
  DateTime previousDate;

  @override
  void initState() {
    _selectedDate = previousDate;
  }

  void syncConstructorArguments(MeasurementDateDialog source) {
    navigator = source.navigator;
    previousDate = source.previousDate;
  }

  DateTime _selectedDate;

  void _handleDateChanged(DateTime value) {
    setState(() {
      _selectedDate = value;
    });
  }

  Widget build() {
    return new Dialog(
      content: new DatePicker(
        selectedDate: _selectedDate,
        firstDate: new DateTime(2015, 8),
        lastDate: new DateTime(2101),
        onChanged: _handleDateChanged
      ),
      contentPadding: EdgeDims.zero,
      actions: [
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: navigator.pop
        ),
        new FlatButton(
          child: new Text('OK'),
          onPressed: () {
            navigator.pop(_selectedDate);
          }
        ),
      ]
    );
  }
}

class MeasurementFragment extends StatefulComponent {

  MeasurementFragment({ this.navigator, this.onCreated });

  Navigator navigator;
  FitnessItemHandler onCreated;

  void syncConstructorArguments(MeasurementFragment source) {
    navigator = source.navigator;
    onCreated = source.onCreated;
  }

  String _weight = "";
  DateTime _when = new DateTime.now();
  String _errorMessage = null;

  void _handleSave() {
    double parsedWeight;
    try {
      parsedWeight = double.parse(_weight);
    } on FormatException catch(e) {
      print("Exception $e");
      setState(() {
        _errorMessage = "Save failed";
      });
    }
    onCreated(new Measurement(when: _when, weight: parsedWeight));
    navigator.pop();
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/close",
        onPressed: navigator.pop),
      center: new Text('New Measurement'),
      right: [new InkWell(
        child: new GestureDetector(
          onTap: _handleSave,
          child: new Text('SAVE')
        )
      )]
    );
  }

  void _handleWeightChanged(String weight) {
    setState(() {
      _weight = weight;
    });
  }

  static final GlobalKey weightKey = new GlobalKey();

  void _handleDatePressed() {
    showDialog(navigator, (navigator) {
      return new MeasurementDateDialog(navigator: navigator, previousDate: _when);
    }).then((DateTime value) {
      if (value == null)
        return;
      setState(() {
        _when = value;
      });
    });
  }

  Widget buildBody() {
    Measurement measurement = new Measurement(when: _when);
    // TODO(jackson): Revisit the layout of this pane to be more maintainable
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: const EdgeDims.all(20.0),
        child: new Column([
          new GestureDetector(
            onTap: _handleDatePressed,
            child: new Container(
              height: 50.0,
              child: new Column([
                new Text('Measurement Date'),
                new Text(measurement.displayDate, style: Theme.of(this).text.caption),
              ], alignItems: FlexAlignItems.start)
            )
          ),
          new Input(
            key: weightKey,
            placeholder: 'Enter weight',
            keyboardType: KeyboardType_NUMBER,
            onChanged: _handleWeightChanged
          ),
        ], alignItems: FlexAlignItems.stretch)
      )
    );
  }

  Widget buildSnackBar() {
    if (_errorMessage == null)
      return null;
    // TODO(jackson): This doesn't show up, unclear why.
    return new SnackBar(content: new Text(_errorMessage), showing: true);
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildBody(),
      snackBar: buildSnackBar()
    );
  }
}
