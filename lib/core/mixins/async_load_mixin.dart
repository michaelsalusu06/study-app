import 'package:flutter/material.dart';

mixin AsyncLoadMixin<T extends StatefulWidget> on State<T> {
  bool isLoading = false;
  String? errorMessage;

  void setLoading(bool value) => setState(() => isLoading = value);

  void setError(String? msg) => setState(() {
        isLoading = false;
        errorMessage = msg;
      });

  void clearError() => setState(() => errorMessage = null);
}
