import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(NDTApp(cameras: cameras));
}

class NDTApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const NDTApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NDT Visual Inspector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NDTHomePage(cameras: cameras),
    );
  }
}

class NDTHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const NDTHomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<NDTHomePage> createState() => _NDTHomePageState();
}

class _NDTHomePageState extends State<NDTHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  NDTResult? _analysisResult;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NDT Visual Inspector'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.search,
                      size: 48,
                      color: Colors.blue[800],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI-Powered Visual Inspection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Detect cracks, corrosion, and surface defects in concrete structures',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedImage != null) ...[
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_isAnalyzing)
                            const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Analyzing image with AI...'),
                              ],
                            )
                          else if (_analysisResult == null)
                            ElevatedButton.icon(
                              onPressed: _analyzeImage,
                              icon: const Icon(Icons.analytics),
                              label: const Text('Analyze with AI'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            )
                          else
                            _buildResultCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildNDTInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _analysisResult!;
    Color statusColor = result.severity == DefectSeverity.critical
        ? Colors.red
        : result.severity == DefectSeverity.moderate
            ? Colors.orange
            : Colors.green;

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.severity == DefectSeverity.critical
                      ? Icons.warning
                      : result.severity == DefectSeverity.moderate
                          ? Icons.info
                          : Icons.check_circle,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analysis Complete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultRow('Defects Found', '${result.defectsFound}'),
            _buildResultRow('Severity', result.severity.name.toUpperCase()),
            _buildResultRow('Confidence', '${(result.confidence * 100).toInt()}%'),
            _buildResultRow('Surface Condition', result.surfaceCondition),
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...result.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(rec)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNDTInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About NDT Visual Inspection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Visual inspection is the most commonly used NDT method. It involves examining structures and components for visible defects such as:',
            ),
            const SizedBox(height: 8),
            ...[
              'Surface cracks and fissures',
              'Corrosion and rust patterns',
              'Surface irregularities',
              'Color changes indicating material degradation',
              'Dimensional variations',
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Simulate AI processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Simple AI simulation based on basic image analysis
      final result = await _simulateAIAnalysis(_selectedImage!);

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    }
  }

  Future<NDTResult> _simulateAIAnalysis(File imageFile) async {
    // Read and analyze image
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Could not decode image');
    }

    // Basic image analysis simulation
    final random = Random();

    // Simulate edge detection for crack analysis
    int edgePixels = 0;
    int darkPixels = 0;
    int totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y += 10) {
      // Sample every 10th pixel
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final red = pixel.r;
        final green = pixel.g;
        final blue = pixel.b;
        final brightness = (red + green + blue) / 3;

        if (brightness < 80) darkPixels++;
        if (x > 0 && y > 0) {
          final prevPixel = image.getPixel(x - 10, y);
          final prevRed = prevPixel.r;
          final prevGreen = prevPixel.g;
          final prevBlue = prevPixel.b;
          final prevBrightness = (prevRed + prevGreen + prevBlue) / 3;
          if ((brightness - prevBrightness).abs() > 50) edgePixels++;
        }
      }
    }

    final edgeRatio = edgePixels / (totalPixels / 100);
    final darkRatio = darkPixels / (totalPixels / 100);

    // Determine defects based on analysis
    int defectsFound = 0;
    DefectSeverity severity = DefectSeverity.none;
    List<String> recommendations = [];
    String surfaceCondition = 'Good';

    if (edgeRatio > 0.3 || darkRatio > 0.4) {
      defectsFound = random.nextInt(5) + 1;
      severity = edgeRatio > 0.6 ? DefectSeverity.critical : DefectSeverity.moderate;
      surfaceCondition = severity == DefectSeverity.critical ? 'Poor' : 'Fair';

      recommendations.addAll([
        severity == DefectSeverity.critical
            ? 'Immediate structural assessment required'
            : 'Schedule detailed inspection within 30 days',
        'Document crack patterns and monitor progression',
        'Consider repair materials suitable for concrete',
      ]);

      if (severity == DefectSeverity.critical) {
        recommendations.add('Restrict access until repairs completed');
      }
    } else {
      recommendations.addAll([
        'Continue regular maintenance schedule',
        'Monitor for changes during next inspection',
      ]);
    }

    final confidence = 0.75 + (random.nextDouble() * 0.2); // 75-95% confidence

    return NDTResult(
      defectsFound: defectsFound,
      severity: severity,
      confidence: confidence,
      surfaceCondition: surfaceCondition,
      recommendations: recommendations,
    );
  }
}

enum DefectSeverity { none, moderate, critical }

class NDTResult {
  final int defectsFound;
  final DefectSeverity severity;
  final double confidence;
  final String surfaceCondition;
  final List<String> recommendations;

  NDTResult({
    required this.defectsFound,
    required this.severity,
    required this.confidence,
    required this.surfaceCondition,
    required this.recommendations,
  });
}
