import 'package:flutter/material.dart';
import 'app.dart';
import 'core/network/connectivity_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectivityService.instance.startMonitoring();
  runApp(const StudyApp());
}
