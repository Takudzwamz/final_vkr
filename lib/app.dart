
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widget/recogniser.dart';

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
    return MaterialApp(
      title: 'Interior Quality Assessment',
      theme: ThemeData.light(),
      home: const PlantRecogniser(),
      debugShowCheckedModeBanner: false,
    );
  }
}
