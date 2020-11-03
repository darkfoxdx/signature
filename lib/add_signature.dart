import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'crop_screen.dart';

class SignatureData {
  final File file;
  final int width;
  final int height;

  SignatureData({this.file, this.width, this.height});
}

class AddSignature extends StatefulWidget {
  @override
  _AddSignatureState createState() => _AddSignatureState();

  static Future<SignatureData> launch(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddSignature()),
    );
  }
}

class _AddSignatureState extends State<AddSignature> {
  var images = List<FileSystemEntity>();

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<FileSystemEntity>> getDirectory() async {
    final directory =
        (await getExternalStorageDirectory()).path + "/signature/";

    var folder = Directory(directory);
    if (!await folder.exists()) {
      await folder.create();
    }
    images = await folder.list().toList();
    return images;
  }

  Future<Uint8List> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    return byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
  }

  Future<Uint8List> takePhoto() async {
    var pickedFile = await ImagePicker().getImage(
        source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    var cropped = await CropScreen.launch(context, pickedFile.path);
    var imageData = await cropped.readAsBytes();
    var processedImage = await processSignatureImage(imageData);

    final directory =
        (await getExternalStorageDirectory()).path + "/signature/";

    var folder = Directory(directory);
    if (!await folder.exists()) {
      await folder.create();
    }
    var file = await File("${directory}signature_${DateTime.now()}.png")
        .writeAsBytes(processedImage);
    setState(() {});
    return await file.readAsBytes();
  }

  Future<Uint8List> processSignatureImage(Uint8List imageData) async {
    var image = img.decodeImage(imageData);
    var matrix = image.getBytes(format: img.Format.rgba);

    var gray = image.clone();
    img.grayscale(gray);

    var grayMatrix = gray.getBytes(format: img.Format.rgba);
    var thresholdMatrix =
        Uint8List.fromList(grayMatrix.map((e) => e > 140 ? 255 : 0).toList());

    var bitwiseAndMatrix = Uint8List(matrix.length);
    for (int i = 0; i < matrix.length; i++) {
      bitwiseAndMatrix[i] = 255 * (matrix[i] & ~thresholdMatrix[i]);
      if ((i + 1) % 4 == 0) {
        bitwiseAndMatrix[i] = ~thresholdMatrix[i - 1];
      }
    }

    var result = img.Image.fromBytes(
        image.width, image.height, bitwiseAndMatrix,
        format: img.Format.rgba);
    result = img.invert(result);
    var coord = img.findTrim(image, mode: img.TrimMode.topLeftColor);
    result = img.copyCrop(result, coord[0], coord[1], coord[2], coord[3]);
    return img.encodePng(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () => takePhoto(),
          ),
        ],
      ),
      body: Container(
        child: FutureBuilder<List<FileSystemEntity>>(
          future: getDirectory(),
          builder: (BuildContext context,
              AsyncSnapshot<List<FileSystemEntity>> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data.isNotEmpty) {
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    var file = snapshot.data[snapshot.data.length - index - 1];
                    return InkWell(
                      child: Image.file(file),
                      // onTap: () {
                        // File image = file;
                        // var decode = img.decodePng(image.readAsBytesSync());
                        // Navigator.of(context).pop(SignatureData(
                        //     file: image,
                        //     width: decode.width,
                        //     height: decode.height));
                      // },
                    );
                  },
                );
              } else {
                return Text("No Data, Take Photo");
              }
            } else {
              return Text("Loading");
            }
          },
        ),
      ),
    );
  }
}
