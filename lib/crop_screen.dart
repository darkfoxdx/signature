import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';

class CropScreen extends StatefulWidget {
  final File file;

  CropScreen(this.file);

  @override
  _CropScreenState createState() => _CropScreenState();

  static Future<File> launch(BuildContext context, String filepath) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CropScreen(File(filepath))),
    );
  }
}

class _CropScreenState extends State<CropScreen> {
  final cropKey = GlobalKey<CropState>();

  File _cropped;

  Future<void> _cropImage() async {
//    final scale = cropKey.currentState.scale;
    final area = cropKey.currentState.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return;
    }

    // scale up to use maximum possible number of pixels
    // this will sample image in higher resolution to make cropped image larger

    final file = await ImageCrop.cropImage(
      file: widget.file,
      area: area,
    );

    final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: 500,
    );

    _cropped?.delete();
    _cropped = sample;

    Navigator.of(context).pop(_cropped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
        backgroundColor: const Color(0xFFFFC629),
        title: Text("Crop"),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Crop.file(
                widget.file,
                key: cropKey,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: RaisedButton(
                shape: StadiumBorder(),
                color: const Color(0xFFFFC629),
                onPressed: () => _cropImage(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Text("Crop Image"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
