import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({required this.camera, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PoseDetectionScreen(camera: camera),
    );
  }
}

class PoseDetectionScreen extends StatefulWidget {
  final CameraDescription camera;

  const PoseDetectionScreen({required this.camera, Key? key}) : super(key: key);

  @override
  State<PoseDetectionScreen> createState() => _PoseDetectionScreenState();
}

class _PoseDetectionScreenState extends State<PoseDetectionScreen> {
  late CameraController _cameraController;
  late PoseDetector _poseDetector;
  bool _isProcessing = false;
  List<PoseLandmark> _landmarks = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    await _cameraController.initialize();
    setState(() {});
  }

  Future<void> _captureAndDetectPose() async {
    if (_isProcessing || !_cameraController.value.isInitialized) return;

    _isProcessing = true;

    try {
      final image = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final poses = await _poseDetector.processImage(inputImage);

      setState(() {
        _landmarks = poses.isNotEmpty
            ? poses.first.landmarks.values.toList()
            : [];
      });
    } catch (e) {
      debugPrint('Error during pose detection: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pose Detection'),
      ),
      body: Column(
        children: [
          if (_cameraController.value.isInitialized)
            AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            )
          else
            Center(child: CircularProgressIndicator()),
          ElevatedButton(
            onPressed: _captureAndDetectPose,
            child: Text('Detect Pose'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _landmarks.length,
              itemBuilder: (context, index) {
                final landmark = _landmarks[index];
                return ListTile(
                  title: Text(landmark.type.toString()),
                  subtitle: Text(
                      'x: ${landmark.x}, y: ${landmark.y}, z: ${landmark.z}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
