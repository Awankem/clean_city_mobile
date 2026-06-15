import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/report_providers.dart';
import 'location_picker_page.dart';
import 'package:latlong2/latlong.dart';

class SubmitReportPage extends ConsumerStatefulWidget {
  const SubmitReportPage({super.key});

  @override
  ConsumerState<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends ConsumerState<SubmitReportPage> {
  final List<File> _images = [];
  final _addressController = TextEditingController(text: 'Detecting location...');
  String _coordinates = '';
  double? _lat;
  double? _lng;
  bool _isSubmitting = false;
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 5));
      if (!serviceEnabled) throw Exception('Location disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _addressController.text = 'Detected Location Area';
        _coordinates =
            'Coordinates: ${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lat = 5.9631;
        _lng = 10.1591;
        _addressController.text = 'Commercial Avenue, Bamenda';
        _coordinates = 'Coordinates: 5.9631° N, 10.1591° E';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(reportRepositoryProvider);
      await repository.submitReport(
        categoryId: _selectedCategoryId!,
        description: _descriptionController.text,
        latitude: _lat ?? 0.0,
        longitude: _lng ?? 0.0,
        locationName: _addressController.text,
        imagePaths: _images.map((f) => f.path).toList(),
      );

      if (!mounted) return;

      ref.invalidate(cityReportsProvider);
      ref.invalidate(myReportsProvider);

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorPopup(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }

    final pickedFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _images.add(File(pickedFile.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primary),
                ),
                title: const Text('Take Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // White header with back button + title
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 20),
                                color: AppColors.onSurface,
                                onPressed: () => context.pop(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'New Report',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Document an environmental issue in your city.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.outline,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -- EVIDENCE PHOTOS section --
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: _sectionLabel(
                                    'EVIDENCE PHOTOS (${_images.length}/5)')),
                            if (_images.length < 5)
                              TextButton.icon(
                                onPressed: _showImagePickerOptions,
                                icon: const Icon(Icons.add_a_photo, size: 16),
                                label: const Text('Add',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_images.isEmpty)
                          GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_enhance_outlined,
                                      size: 44,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.6)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tap to capture evidence',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  _images.length + (_images.length < 5 ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _images.length) {
                                  return GestureDetector(
                                    onTap: _showImagePickerOptions,
                                    child: Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: AppColors.surfaceContainerHigh),
                                      ),
                                      child: const Icon(
                                          Icons.add_a_photo_outlined,
                                          color: AppColors.primary),
                                    ),
                                  );
                                }
                                return Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        image: DecorationImage(
                                          image: FileImage(_images[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),

                        // -- DETECTED LOCATION section --
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                          Icons.location_on_rounded,
                                          color: AppColors.primary,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'DETECTED LOCATION',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.outline,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  if (_lat == null ||
                                                      _lng == null) return;
                                                  final result = await Navigator
                                                      .push<LocationPickerResult>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          LocationPickerPage(
                                                        initialLocation: LatLng(
                                                            _lat!, _lng!),
                                                      ),
                                                    ),
                                                  );

                                                  if (result != null &&
                                                      mounted) {
                                                    setState(() {
                                                      _lat = result.coordinates
                                                          .latitude;
                                                      _lng = result.coordinates
                                                          .longitude;
                                                      _addressController.text =
                                                          result.address;
                                                      _coordinates =
                                                          'Coordinates: ${_lat!.toStringAsFixed(4)}° N, ${_lng!.toStringAsFixed(4)}° E';
                                                    });
                                                  }
                                                },
                                                child: const Text(
                                                  'Edit on Map',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          TextField(
                                            controller: _addressController,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.onSurface,
                                            ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              border: InputBorder.none,
                                            ),
                                          ),
                                          if (_coordinates.isNotEmpty)
                                            Text(
                                              _coordinates,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.outline,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Map preview placeholder
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(20)),
                                child: Container(
                                  height: 130,
                                  color: const Color(0xFFD8E8D4),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: Size.infinite,
                                        painter: _MapGridPainter(),
                                      ),
                                      const Icon(Icons.location_on,
                                          color: AppColors.primary, size: 40),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // -- REPORT CATEGORY section --
                        _sectionLabel('REPORT CATEGORY'),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: categoriesAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            ),
                            error: (err, stack) => const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Failed to load categories',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            data: (categories) {
                              return DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                                hint: const Text('Select Category',
                                    style:
                                        TextStyle(color: AppColors.outline)),
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.onSurface),
                                items: categories
                                    .map<DropdownMenuItem<int>>((cat) {
                                  return DropdownMenuItem<int>(
                                    value: cat['id'] as int,
                                    child: Text(cat['name'] as String),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCategoryId = val),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // -- ADDITIONAL DETAILS section --
                        _sectionLabel('ADDITIONAL DETAILS'),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(20),
                              hintText: 'Describe the issue in a few words...',
                              hintStyle: TextStyle(
                                  color: AppColors.outline, fontSize: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // -- SUBMIT BUTTON --
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send_rounded, size: 20),
                            label: Text(
                              _isSubmitting ? 'Submitting...' : 'Submit Report',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.outline,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDD4B8)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
