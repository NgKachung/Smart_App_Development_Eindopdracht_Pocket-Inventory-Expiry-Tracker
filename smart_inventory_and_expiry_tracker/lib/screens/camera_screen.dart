import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'add_product_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available');
      _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scan QR'),
      ),
      child: SafeArea(
        child: _error != null
            ? Center(child: Text('Camera error: $_error'))
            : (_isReady && _controller != null)
                ? Stack(
                    children: [
                      Center(child: CameraPreview(_controller!)),
                      Positioned(
                        right: 18,
                        bottom: 24,
                        child: GestureDetector(
                          onTap: () async {
                            final product = await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const AddProductScreen()));
                            // product is a Map when saved; integration can insert it into lists.
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                            ),
                            child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CupertinoActivityIndicator()),
      ),
    );
  }
}
