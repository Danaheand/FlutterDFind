import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageViewer extends StatelessWidget {
  const ImageViewer({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Imagen del Recordatorio'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: XFile(path).readAsBytes(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done || !snap.hasData) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(snap.data!),
            );
          },
        ),
      ),
    );
  }
}
