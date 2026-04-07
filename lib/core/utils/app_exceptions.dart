import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

class AppExceptions {
  static String handleError(dynamic error) {
    if (error is BadRequestException) {
      return error.message;
    } else if (error is UnauthorizedException) {
      return error.message;
    } else if (error is ForbiddenException) {
      return error.message;
    } else if (error is NotFoundException) {
      return error.message;
    } else if (error is ServerException) {
      return error.message;
    } else if (error is FetchDataException) {
      return error.message;
    } else if (error is TimeoutException) {
      return 'Connection timeout. Please try again.';
    } else {
      return AppStrings.somethingWentWrong;
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Custom Exception Classes
class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class FetchDataException implements Exception {
  final String message;
  FetchDataException(this.message);
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
