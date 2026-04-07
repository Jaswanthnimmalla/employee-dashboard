import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // ================= CONFIG =================

  static const String cloudName = "daavatdft";

  // ================= ATTENDANCE CONFIG =================

  static const String uploadPreset = "attendance_upload";
  static const String assetFolder = "attendenceenary";

  // ================= LEAVE CONFIG =================

  static const String leavePreset = "leave_upload";
  static const String leaveFolder = "leaves";

  // ================= REQUEST CONFIG (NEW) =================

  static const String requestPreset = "request_upload";
  static const String requestFolder = "requests";

  // ======================================================
  // ================= ATTENDANCE SELFIE ==================
  // ======================================================

  static Future<String?> uploadAttendanceSelfie(
    File file, {
    required String userId,
    required DateTime date,
  }) async {
    try {
      print("Uploading attendance selfie...");

      final fileName =
          "attendance_${userId}_${date.year}${date.month}${date.day}_${DateTime.now().millisecondsSinceEpoch}";

      return await _uploadFile(
        file,
        fileName: fileName,
        preset: uploadPreset,
        folder: assetFolder,
      );
    } catch (e) {
      print("Attendance upload error: $e");
      return null;
    }
  }

  // ======================================================
  // ================= LEAVE PROOF ========================
  // ======================================================

  static Future<String?> uploadLeaveProof(
    File file, {
    required String userId,
  }) async {
    try {
      print("Uploading leave proof...");

      final fileName =
          "leave_${userId}_${DateTime.now().millisecondsSinceEpoch}";

      return await _uploadFile(
        file,
        fileName: fileName,
        preset: leavePreset,
        folder: leaveFolder,
      );
    } catch (e) {
      print("Leave upload error: $e");
      return null;
    }
  }

  // ======================================================
  // ================= REQUEST FILE UPLOAD (NEW) ==========
  // ======================================================

  static Future<String?> uploadRequestFile(
    File file, {
    required String userId,
  }) async {
    try {
      print("Uploading request file...");

      final fileName =
          "request_${userId}_${DateTime.now().millisecondsSinceEpoch}";

      return await _uploadFile(
        file,
        fileName: fileName,
        preset: requestPreset,
        folder: requestFolder,
      );
    } catch (e) {
      print("Request upload error: $e");
      return null;
    }
  }

  // ======================================================
  // ================= GENERAL FILE =======================
  // ======================================================

  static Future<String?> uploadGeneralFile(
    File file, {
    String? fileName,
  }) async {
    try {
      print("Uploading general file...");

      final name = fileName ?? "file_${DateTime.now().millisecondsSinceEpoch}";

      return await _uploadFile(
        file,
        fileName: name,
        preset: uploadPreset,
        folder: assetFolder,
      );
    } catch (e) {
      print("General upload error: $e");
      return null;
    }
  }

  // ================= PROFILE PHOTO UPLOAD =================

  static const String profilePreset = "profile_upload";
  static const String profileFolder = "profiles";

  static Future<String?> uploadProfilePhoto(
    File file, {
    required String userId,
  }) async {
    try {
      print("Uploading profile photo...");

      final fileName =
          "profile_${userId}_${DateTime.now().millisecondsSinceEpoch}";

      return await _uploadFile(
        file,
        fileName: fileName,
        preset: profilePreset,
        folder: profileFolder,
      );
    } catch (e) {
      print("Profile upload error: $e");
      return null;
    }
  }

  // ======================================================
  // ================= CORE UPLOAD METHOD =================
  // ======================================================

  static Future<String?> _uploadFile(
    File file, {
    required String fileName,
    required String preset,
    required String folder,
  }) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload",
      );

      var request = http.MultipartRequest(
        "POST",
        uri,
      );

      // Required fields

      request.fields['upload_preset'] = preset;
      request.fields['folder'] = folder;
      request.fields['public_id'] = fileName;
      request.fields['resource_type'] = "auto";

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      print("Preset: $preset");
      print("Folder: $folder");

      var response = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final responseData = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODY: $responseData");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);

        final fileUrl = data['secure_url'];

        print("Upload success: $fileUrl");

        return fileUrl;
      }

      print("Upload failed");

      return null;
    } catch (e) {
      print("Cloudinary error: $e");

      return null;
    }
  }
}
