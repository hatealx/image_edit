import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _createDirectory();
  runApp(MyApp());
}

Future<void> _createDirectory() async {
  if (await Permission.storage.request().isGranted) {
    List<Directory>? externalDirs = await getExternalStorageDirectories();

    if (externalDirs != null && externalDirs.isNotEmpty) {
      Directory externalDir = externalDirs.first;
      String appDataPath = '${externalDir.parent.parent.parent.parent.path}/editimage';

      try {
        Directory appDataDir = Directory(appDataPath);
        if (!await appDataDir.exists()) {
          await appDataDir.create(recursive: true);
          print("editimage directory created at: $appDataPath");
        }
      } catch (e) {
        print("Error creating folder: $e");
      }
    }
  } else {
    print("Storage permission denied");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageMarginExample(),
    );
  }
}

class ImageMarginExample extends StatefulWidget {
  @override
  _ImageMarginExampleState createState() => _ImageMarginExampleState();
}

class _ImageMarginExampleState extends State<ImageMarginExample> {
  double _topMargin = 0.0;
  double _leftMargin = 0.0;
  double _bottomMargin = 0.0;
  double _rightMargin = 0.0;

  Uint8List? _imageBytes;
  final picker = ImagePicker();
  final ScreenshotController screenshotController = ScreenshotController();
  final TextEditingController _imageNameController = TextEditingController();

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _saveImage(String imageName) async {
    try {
      List<Directory>? externalDirs = await getExternalStorageDirectories();
      if (externalDirs != null && externalDirs.isNotEmpty) {
        Directory externalDir = externalDirs.first;
        String appDataPath = '${externalDir.parent.parent.parent.parent.path}/editimage';
        final directory = Directory(appDataPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        String fileName = '$imageName.png';
        String filePath = path.join(directory.path, fileName);
        
        int counter = 1;
        while (await File(filePath).exists()) {
          fileName = '$imageName($counter).png';
          filePath = path.join(directory.path, fileName);
          counter++;
        }

        screenshotController.capture().then((Uint8List? image) async {
          if (image != null) {
            final file = File(filePath);
            await file.writeAsBytes(image);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image saved to $filePath')),
            );
          }
        }).catchError((error) {
          print('Error capturing image: $error');
        });
      }
    } catch (error) {
      print('Error saving image: $error');
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save Image'),
          content: TextField(
            controller: _imageNameController,
            decoration: InputDecoration(hintText: 'Enter image name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String imageName = _imageNameController.text;
                if (imageName.isNotEmpty) {
                  Navigator.of(context).pop();
                  _saveImage(imageName);
                  _imageNameController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a name for the image')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showMarginForm() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Top Margin', _topMargin, (value) {
                setState(() {
                  _topMargin = double.tryParse(value) ?? 0.0;
                });
              }),
              _buildTextField('Left Margin', _leftMargin, (value) {
                setState(() {
                  _leftMargin = double.tryParse(value) ?? 0.0;
                });
              }),
              _buildTextField('Bottom Margin', _bottomMargin, (value) {
                setState(() {
                  _bottomMargin = double.tryParse(value) ?? 0.0;
                });
              }),
              _buildTextField('Right Margin', _rightMargin, (value) {
                setState(() {
                  _rightMargin = double.tryParse(value) ?? 0.0;
                });
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Advanced Image Margin and Resize'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _showSaveDialog,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showMarginForm,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Screenshot(
                controller: screenshotController,
                child: _imageBytes == null
                    ? Text('No image selected.')
                    : Container(
                        color: Colors.white, // Background color to see the margin
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: _topMargin,
                            left: _leftMargin,
                            bottom: _bottomMargin,
                            right: _rightMargin,
                          ),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.contain, // Adjust image fit here
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _getImage,
                  child: Text('Select Image'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, double value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: value.toString(),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}