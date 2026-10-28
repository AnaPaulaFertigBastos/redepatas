import 'package:flutter/material.dart';

import 'app/redepatas_app.dart';
import 'notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final push = PushService();
  await push.initialize();
  runApp(RedePatasApp(push: push));
}
