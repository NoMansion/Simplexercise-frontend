import 'VideoPage.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isRecording = false;
  late CameraController _cameraController;
  late Future<void> cameraValue;
  bool isFlashOn = false;
  bool isRearCamera = true;

  @override
  void initState() {
    startCamera(0);
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void startCamera(int camera) {
    _cameraController = CameraController(
      widget.cameras[camera],
      ResolutionPreset.high,
      enableAudio: false,
    );
    cameraValue = _cameraController.initialize();
  }

  void _recordVideo() async {
  await cameraValue;

  // Retry initialization check for up to 3 seconds
  const maxRetries = 30; // 3 seconds / 100ms = 30 retries
  const retryDelay = Duration(milliseconds: 100);

  for (int i = 0; i < maxRetries; i++) {
    if (_cameraController.value.isInitialized) {
      break; // Exit loop if the camera controller is initialized
    }
    await Future.delayed(retryDelay); // Wait before checking again
  }

  // Check again after retries
  if (!_cameraController.value.isInitialized) {
    // Handle the case when the camera controller is still not initialized
    print('Camera controller is not initialized after retrying.');
    return;
  }

  if (_isRecording) {
    // Add a delay to ensure the recording has started properly
    await Future.delayed(Duration(seconds: 1));
    final file = await _cameraController.stopVideoRecording();
    setState(() => _isRecording = false);
    final route = MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => VideoPage(filePath: file.path),
    );
    Navigator.push(context, route);
  } else {
    await _cameraController.prepareForVideoRecording();
    await _cameraController.startVideoRecording();
    setState(() => _isRecording = true);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: cameraValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CameraPreview(_cameraController),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: FloatingActionButton(
                          backgroundColor: Colors.red,
                          child: Icon(_isRecording ? Icons.stop : Icons.circle),
                          onPressed: () => _recordVideo(),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5, top: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isFlashOn = !isFlashOn;
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(50, 0, 0, 0),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: isFlashOn
                                    ? const Icon(
                                        Icons.flash_on,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                    : const Icon(
                                        Icons.flash_off,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                              ),
                            ),
                          ),
                          const Gap(10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isRearCamera = !isRearCamera;
                              });
                              isRearCamera ? startCamera(0) : startCamera(1);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(50, 0, 0, 0),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: isRearCamera
                                    ? const Icon(
                                        Icons.camera_rear,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                    : const Icon(
                                        Icons.camera_front,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}