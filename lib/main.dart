import 'package:flutter/widgets.dart';
import 'package:sound_foundry/app/app.dart';
import 'package:sound_foundry/app/bootstrap/bootstrap.dart';

void main() async {
  final container = await AppBootstrap.bootstrap();
  runApp(EchoBloomApp(container: container));
}
