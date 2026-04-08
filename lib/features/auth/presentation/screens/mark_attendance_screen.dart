import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:employee_dashboard_app/core/utils/attendance_time_logic.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isCheckingLocation = false;
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  String? _attendanceId;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  Position? _currentPosition;
  String _locationAddress = '';
  File? _selfieImage;
  String? _photoUrl;
  final TextEditingController _notesController = TextEditingController();
  String _selectedWorkType = 'Office';
  double _totalHours = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> _workTypes = [
    'Office',
    'Remote',
    'Client Visit',
    'Field Work'
  ];

  bool _locationAlreadyDetected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _scaleAnimation =
        Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _initializeScreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_locationAlreadyDetected) {
        _checkLocationAndGetPosition();
      }
    }
  }

  Future<void> _initializeScreen() async {
    await _checkTodayAttendance();
    await _checkLocationAndGetPosition();
  }

  Future<void> _checkLocationAndGetPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationSettingsDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionPermanentlyDeniedDialog();
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _checkTodayAttendance() async {
    try {
      setState(() => _isLoading = true);

      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final query = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('dateString', isEqualTo: todayString)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final hasCheckIn =
            data.containsKey('checkInTime') && data['checkInTime'] != null;
        final hasCheckOut =
            data.containsKey('checkOutTime') && data['checkOutTime'] != null;

        setState(() {
          _isCheckedIn = hasCheckIn;
          _attendanceId = doc.id;

          if (hasCheckIn) {
            _checkInTime = (data['checkInTime'] as Timestamp).toDate();
          }

          _isCheckedOut = hasCheckOut;

          if (hasCheckOut) {
            _checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
            _totalHours = data['totalHours'] ?? 0.0;
          }

          _notesController.text = data['notes'] ?? '';
          _selectedWorkType = data['workType'] ?? 'Office';
          _photoUrl = data['photoUrl'] ?? '';
        });
      } else {
        setState(() {
          _isCheckedIn = false;
          _isCheckedOut = false;
          _attendanceId = null;
          _checkInTime = null;
          _checkOutTime = null;
          _photoUrl = null;
          _selfieImage = null;
          _notesController.clear();
          _totalHours = 0.0;
        });
      }
    } catch (e) {
      print("Error checking today's attendance: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isCheckingLocation) return;

    setState(() => _isCheckingLocation = true);

    try {
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        setState(() => _currentPosition = lastPosition);
        _getAddressFromLatLng(lastPosition);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );

      setState(() => _currentPosition = position);

      await _getAddressFromLatLng(position);

      if (mounted) {
        _locationAlreadyDetected = true;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📍 Location detected"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Location error: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingLocation = false);
      }
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          _locationAddress =
              '${place.street}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      print('Geocoding error: $e');
      if (mounted) {
        setState(() {
          _locationAddress =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_off,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Location Services Off',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Location services are required to mark attendance.\nPlease enable location services to continue.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            icon: const Icon(
              Icons.settings,
              size: 22, // bigger icon
              color: Colors.white,
            ),
            label: const Text(
              'Open Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_disabled,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Location Permission Required',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This app needs location access to verify your attendance.\nPlease allow location access "While Using the App".',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            icon: const Icon(Icons.location_on, size: 18),
            label: const Text('Allow Access'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.block, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Permission Permanently Denied',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Location permission is permanently denied.\nPlease enable it in app settings to mark attendance.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            icon: const Icon(Icons.settings_applications, size: 18),
            label: const Text('Open App Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null && mounted) {
      setState(() => _selfieImage = File(image.path));
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selfieImage == null) return null;
    final user = _auth.currentUser;
    return await CloudinaryService.uploadAttendanceSelfie(_selfieImage!,
        userId: user!.uid, date: DateTime.now());
  }

  Future<void> _markCheckIn() async {
    if (_selfieImage == null) {
      _showSnackBar('Please take a selfie first', Colors.red);
      return;
    }

    if (_currentPosition == null) {
      _showSnackBar('Getting location...', Colors.orange);
      await _getCurrentLocation();
      if (_currentPosition == null) {
        _showSnackBar('Location required. Please enable GPS.', Colors.red);
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final user = _auth.currentUser;
      final now = DateTime.now();

      final status = AttendanceTimeLogic.getStatus(now);
      String? photoUrl = await _uploadToCloudinary();

      final docRef = await _firestore.collection('attendance').add({
        'dateString': DateFormat('yyyy-MM-dd').format(now),
        'attendanceId': '',
        'userId': user!.uid,
        'userName':
            user.displayName ?? user.email?.split('@').first ?? 'Employee',
        'userEmail': user.email,
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        'checkInTime': Timestamp.fromDate(now),
        'checkOutTime': null,
        'status': status,
        'latitude': _currentPosition?.latitude ?? 0.0,
        'longitude': _currentPosition?.longitude ?? 0.0,
        'locationAddress': _locationAddress.isNotEmpty
            ? _locationAddress
            : 'Location not available',
        'photoUrl': photoUrl,
        'notes': _notesController.text,
        'workType': _selectedWorkType,
        'totalHours': 0.0,
        'month': now.month,
        'year': now.year,
        'timestamp': Timestamp.fromDate(now),
      });

      await docRef.update({'attendanceId': docRef.id});

      setState(() {
        _isCheckedIn = true;
        _attendanceId = docRef.id;
        _checkInTime = now;
        _photoUrl = photoUrl;
      });

      _showSnackBar(
          '✅ Checked in at ${DateFormat('hh:mm a').format(now)}', Colors.green);
      await _checkTodayAttendance();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _markCheckOut() async {
    if (_attendanceId == null) {
      _showSnackBar('No active check-in found', Colors.red);
      await _checkTodayAttendance();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _getCurrentLocation();

      final now = DateTime.now();
      final totalHours = now.difference(_checkInTime!).inHours +
          (now.difference(_checkInTime!).inMinutes % 60) / 60;

      await _firestore.collection('attendance').doc(_attendanceId).update({
        'checkOutTime': Timestamp.fromDate(now),
        'totalHours': totalHours,
        'latitude': _currentPosition?.latitude ?? 0.0,
        'longitude': _currentPosition?.longitude ?? 0.0,
        'locationAddress': _locationAddress.isNotEmpty
            ? _locationAddress
            : 'Location not available',
      });

      setState(() {
        _isCheckedOut = true;
        _checkOutTime = now;
        _totalHours = totalHours;
      });

      _showSnackBar(
          '✅ Checked out! Total: ${totalHours.toStringAsFixed(1)} hours',
          Colors.green);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final isTablet = screenWidth > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        centerTitle: true,
        elevation: 6,
        shadowColor: Colors.black26,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mark Attendance",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF8E2DE2),
                Color(0xFFFF7043),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white24,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await _checkTodayAttendance();
              await _getCurrentLocation();
            },
            color: const Color(0xFF1E3A8A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: 20,
              ),
              child: Column(
                children: [
                  _buildHeaderCard(isTablet),
                  const SizedBox(height: 20),
                  _buildCurrentTimeCard(),
                  const SizedBox(height: 20),
                  _buildStatusCard(isSmall),
                  const SizedBox(height: 20),
                  _buildLocationCard(isSmall),
                  const SizedBox(height: 20),
                  _buildWorkTypeDropdown(),
                  const SizedBox(height: 20),
                  _buildSelfieCard(isSmall),
                  const SizedBox(height: 20),
                  _buildNotesCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(isTablet),
                  if (_isCheckedIn && !_isCheckedOut) ...[
                    const SizedBox(height: 20),
                    _buildProgressCard(),
                  ],
                  if (_isCheckedOut) ...[
                    const SizedBox(height: 20),
                    _buildSummaryCard(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeCard() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF1E3A8A).withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.access_time,
                    color: Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Time',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    DateFormat('hh:mm:ss a').format(now),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.calendar_today,
                    color: Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Week Day',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    DateFormat('EEEE').format(now),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isTablet) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = hour < 12
        ? 'Morning'
        : hour < 17
            ? 'Afternoon'
            : 'Evening';

    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good $greeting!',
                    style: TextStyle(
                        fontSize: isTablet ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, MMMM d, yyyy').format(now),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    _isCheckedOut
                        ? 'Day Complete 🎉'
                        : (_isCheckedIn
                            ? 'Currently Working 💼'
                            : 'Ready to Start ✨'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Icon(_isCheckedOut ? Icons.celebration : Icons.work,
                size: isTablet ? 50 : 42, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF8E1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.login,
                      color: const Color(0xFF10B981), size: 28),
                ),
                const SizedBox(height: 8),
                const Text('CHECK IN',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  _checkInTime != null
                      ? DateFormat('hh:mm a').format(_checkInTime!)
                      : '--:--',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          Container(height: 50, width: 1, color: Colors.grey.shade200),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout,
                      color: const Color(0xFFF59E0B), size: 28),
                ),
                const SizedBox(height: 8),
                const Text('CHECK OUT',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  _checkOutTime != null
                      ? DateFormat('hh:mm a').format(_checkOutTime!)
                      : '--:--',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _currentPosition != null
              ? [
                  Colors.green.shade50,
                  Colors.white,
                ]
              : [
                  Colors.orange.shade50,
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _currentPosition != null ? Colors.green : Colors.orange,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _currentPosition != null
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                    _currentPosition != null
                        ? Icons.gps_fixed
                        : Icons.location_searching,
                    color:
                        _currentPosition != null ? Colors.green : Colors.orange,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentPosition != null
                          ? 'Location Detected'
                          : (_isCheckingLocation
                              ? 'Detecting...'
                              : 'Auto-detecting...'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _currentPosition != null
                              ? Colors.green.shade700
                              : Colors.orange.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _locationAddress.isEmpty
                          ? (_isCheckingLocation
                              ? 'Fetching location...'
                              : 'Waiting for location...')
                          : _locationAddress,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isCheckingLocation)
                const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              if (!_isCheckingLocation && _currentPosition == null)
                IconButton(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh,
                        color: Color(0xFF1E3A8A), size: 22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkTypeDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE3F2FD),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1E3A8A),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.work_outline,
                color: Color(0xFF1E3A8A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Work Type',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButtonFormField<String>(
                  value: _selectedWorkType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A)),
                  items: _workTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  type == 'Office'
                                      ? Icons.business_center
                                      : type == 'Remote'
                                          ? Icons.home_work
                                          : type == 'Client Visit'
                                              ? Icons.people
                                              : Icons.location_on,
                                  size: 18,
                                  color: const Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 8),
                                Text(type),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: !_isCheckedIn
                      ? (value) => setState(() => _selectedWorkType = value!)
                      : null,
                  icon: Icon(Icons.arrow_drop_down,
                      color:
                          !_isCheckedIn ? const Color(0xFF1E3A8A) : Colors.grey,
                      size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF3E5F5),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.deepPurple,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.camera_alt,
                color: Color(0xFF1E3A8A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selfie Verification',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Text(
                  _selfieImage != null
                      ? 'Photo taken ✓'
                      : (_photoUrl != null
                          ? 'Verified ✓'
                          : 'Take a selfie to check in'),
                  style: TextStyle(
                      fontSize: 12,
                      color: _selfieImage != null || _photoUrl != null
                          ? Colors.green
                          : Colors.grey.shade600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: (!_isCheckedIn && !_isCheckedOut) ? _takeSelfie : null,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
              ),
              child: ClipOval(
                child: _selfieImage != null
                    ? Image.file(_selfieImage!, fit: BoxFit.cover)
                    : (_photoUrl != null && _photoUrl!.isNotEmpty
                        ? Image.network(_photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey))
                        : const Icon(Icons.camera_alt,
                            size: 28, color: Color(0xFF1E3A8A))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8F5E9),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.green,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.note_outlined,
                color: Color(0xFF1E3A8A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: 2,
              enabled: !_isCheckedOut,
              decoration: InputDecoration(
                hintText: 'Add work notes...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    final now = DateTime.now();

    final cutoffTime = DateTime(
      now.year,
      now.month,
      now.day,
      11,
      40,
    );

    final isTimeUp = now.isAfter(cutoffTime);

    Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed:
              (_isProcessing || (_isCheckedIn && !_isCheckedOut) || isTimeUp)
                  ? null
                  : _markCheckIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: _isProcessing ? 0 : 4,
          ),
          child: _isProcessing && !_isCheckedIn
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCheckedIn ? Icons.check_circle : Icons.login,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTimeUp
                          ? 'Time Up'
                          : (_isCheckedIn ? 'Checked In' : 'Check In'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
    if (_isCheckedOut) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 22,
          ),
          label: const Text(
            'Back to Dashboard',
            style: TextStyle(
              fontSize: 18, // bigger text
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: (_isProcessing || (_isCheckedIn && !_isCheckedOut))
                  ? null
                  : _markCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: _isProcessing ? 0 : 4,
              ),
              child: _isProcessing && !_isCheckedIn
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isCheckedIn ? Icons.check_circle : Icons.login,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(_isCheckedIn ? 'Checked In' : 'Check In',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: (_isProcessing || !_isCheckedIn || _isCheckedOut)
                  ? null
                  : _markCheckOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: _isProcessing ? 0 : 4,
              ),
              child: _isProcessing && _isCheckedIn && !_isCheckedOut
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isCheckedOut ? Icons.check_circle : Icons.logout,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(_isCheckedOut ? 'Checked Out' : 'Check Out',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    if (_checkInTime == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final hoursWorked = now.difference(_checkInTime!).inHours +
        (now.difference(_checkInTime!).inMinutes % 60) / 60;
    final percentage = (hoursWorked / 8).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 15, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          const Text('Today\'s Progress',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem(
                  'Worked', '${hoursWorked.toStringAsFixed(1)}h'),
              _buildProgressItem('Remaining',
                  '${(8 - hoursWorked).clamp(0.0, 8.0).toStringAsFixed(1)}h'),
              _buildProgressItem('Target', '8.0h'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white30,
                color: Colors.white,
                minHeight: 8),
          ),
          const SizedBox(height: 8),
          Text('${(percentage * 100).toStringAsFixed(0)}% completed',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 60, color: Colors.green),
          const SizedBox(height: 12),
          const Text('Attendance Completed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('Total: ${_totalHours.toStringAsFixed(1)} hours',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green)),
          ),
          const Divider(height: 32),
          _buildSummaryRow(
              'Check In',
              _checkInTime != null
                  ? DateFormat('hh:mm a').format(_checkInTime!)
                  : '--:--',
              Icons.login,
              const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildSummaryRow(
              'Check Out',
              _checkOutTime != null
                  ? DateFormat('hh:mm a').format(_checkOutTime!)
                  : '--:--',
              Icons.logout,
              const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildSummaryRow('Work Type', _selectedWorkType, Icons.work_outline,
              const Color(0xFF1E3A8A)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
