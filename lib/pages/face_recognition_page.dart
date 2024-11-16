import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:vector_math/vector_math.dart' hide Colors;

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  File? _selectedImage;
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
  }

  Future<void> _initializeFaceDetector() async {
    try {
      _faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        mode: FaceDetectorMode.accurate,
      ));
      setState(() {
        _isModelReady = true;
      });
    } catch (e) {
      debugPrint("Error initializing face detector: $e");
    }
  }



  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      if (_isModelReady) {
        _detectFacesInImage(_selectedImage!);
      } else {
        _showDetectionResult("Model is not ready. Please try again later.");
      }
    }
  }

  Future<List<double>> _extractFaceSignature(Face face) async {
    final List<double> signature = [];

    final leftEye = face.getLandmark(FaceLandmarkType.leftEye);
    final rightEye = face.getLandmark(FaceLandmarkType.rightEye);

    if (leftEye == null || rightEye == null) return signature;

    final double eyeDistance = math.sqrt(
      math.pow(rightEye.position.dx - leftEye.position.dx, 2) +
          math.pow(rightEye.position.dy - leftEye.position.dy, 2),
    );

    final landmarks = [
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
    ];

    for (var landmarkType in landmarks) {
      final landmark = face.getLandmark(landmarkType);
      if (landmark != null) {
        signature
            .add((landmark.position.dx - leftEye.position.dx) / eyeDistance);
        signature
            .add((landmark.position.dy - leftEye.position.dy) / eyeDistance);
        signature
            .add((landmark.position.dx - rightEye.position.dx) / eyeDistance);
        signature
            .add((landmark.position.dy - rightEye.position.dy) / eyeDistance);
      }
    }

    return signature;
  }

  bool _compareSignatures(
      List<double> newSignature, List<double> storedSignature) {
    final int minLength = math.min(newSignature.length, storedSignature.length);

    double totalDistance = 0.0;
    for (int i = 0; i < minLength; i++) {
      totalDistance += (newSignature[i] - storedSignature[i]).abs();
    }

    double averageDistance = totalDistance / minLength;
    const double dynamicThreshold = 0.14;

    return averageDistance <= dynamicThreshold;
  }

  Future<void> _recordAttendance(Face detectedFace) async {
    final signature = await _extractFaceSignature(detectedFace);
    final faceSignaturesRef =
        FirebaseFirestore.instance.collection('face_signature');
    bool isFaceRecognized = false;
    String? recognizedName;

    final querySnapshot = await faceSignaturesRef.get();

    for (var doc in querySnapshot.docs) {
      List<double> storedSignature = List<double>.from(doc['signature']);
      if (_compareSignatures(signature, storedSignature)) {
        isFaceRecognized = true;
        recognizedName = doc['name'];
        break;
      }
    }

    if (isFaceRecognized && recognizedName != null) {
      await _recordAttendanceForToday(recognizedName, signature);
    } else {
      _showNameInputDialog(signature);
    }
  }

  void _showNameInputDialog(List<double> signature) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Name"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Enter your name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _storeFaceSignatureWithName(nameController.text, signature);
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _storeFaceSignatureWithName(
      String name, List<double> signature) async {
    try {
      await FirebaseFirestore.instance.collection('face_signature').add({
        'name': name,
        'signature': signature,
        'time': DateTime.now(),
      });

      await _recordAttendanceForToday(name, signature);
      _showDetectionResult("Face detected. Attendance recorded for $name.");
    } catch (e) {
      debugPrint("Error storing face signature: $e");
    }
  }

  Future<void> _recordAttendanceForToday(
      String name, List<double> signature) async {
    String today = DateTime.now().toIso8601String().split('T').first;
    final attendanceRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(today)
        .collection('data');

    final existingAttendanceSnapshot =
        await attendanceRef.where('name', isEqualTo: name).get();

    bool alreadyRecorded = false;
    for (var doc in existingAttendanceSnapshot.docs) {
      List<double> storedSignature = List<double>.from(doc['signature']);
      if (_compareSignatures(signature, storedSignature)) {
        alreadyRecorded = true;
        break;
      }
    }

    if (!alreadyRecorded) {
      try {
        await attendanceRef.add({
          'name': name,
          'signature': signature,
          'time': DateTime.now(),
        });
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc(today)
            .set({"date": today}, SetOptions(merge: true));
      _showDetectionResult("Attendance recorded for $name.");
      } catch (e) {
        debugPrint("Error recording attendance: $e");
      }
    } else {
      _showDetectionResult("Attendance already recorded for $name today.");
    }
  }

  Future<void> _detectFacesInImage(File imageFile) async {
    try {
      if (!_isModelReady) {
        _showDetectionResult("Model is still loading. Please wait.");
        return;
      }

      final inputImage = InputImage.fromFile(imageFile);
      setState(() {
        _isDetecting = true;
      });

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        await _recordAttendance(faces.first);
      } else {
        _showDetectionResult("No face detected.");
      }
    } catch (e) {
      debugPrint("Error during face detection: $e");
      _showDetectionResult("Error during face detection. Please try again.");
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  void _showDetectionResult(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Detection Result"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Attendance System')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _selectedImage != null
              ? Container(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.4,
                  color: Colors.grey.shade300,
                  child: const Center(child: Text("No image selected")),
                ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isDetecting || !_isModelReady
                    ? null
                    : () => _pickImage(ImageSource.camera),
                child: const Text("Capture Image"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _isDetecting || !_isModelReady
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                child: const Text("Pick from Gallery"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
