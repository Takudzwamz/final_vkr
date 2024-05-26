

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../classifier/classifier.dart';
import '../styles.dart';
import 'photo_view.dart';

const _labelsFileName = 'assets/labels.txt';
const _modelFileName = 'model.tflite';

class PlantRecogniser extends StatefulWidget {
  const PlantRecogniser({super.key});

  @override
  State<PlantRecogniser> createState() => _PlantRecogniserState();
}

enum _ResultStatus {
  notStarted,
  notFound,
  found,
}

class _PlantRecogniserState extends State<PlantRecogniser> {
  bool _isAnalyzing = false;
  final picker = ImagePicker();
  File? _selectedImageFile;

  // Result
  _ResultStatus _resultStatus = _ResultStatus.notStarted;
  String _plantLabel = ''; // Name of Error Message
  double _accuracy = 0.0;

  late Classifier _classifier;

  @override
  void initState() {
    super.initState();
    _loadClassifier();
  }

  Future<void> _loadClassifier() async {
    debugPrint(
      'Start loading of Classifier with '
      'labels at $_labelsFileName, '
      'model at $_modelFileName',
    );

    final classifier = await Classifier.loadWith(
      labelsFileName: _labelsFileName,
      modelFileName: _modelFileName,
    );
    _classifier = classifier!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgColor,
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: _buildTitle(),
          ),
          const SizedBox(height: 20),
          _buildPhotolView(),
          const SizedBox(height: 10),
          _buildResultView(),
          const Spacer(flex: 5),
          _buildListingAdCard(),
          _buildPickPhotoButton(
            title: 'снимать фото',
            source: ImageSource.camera,
          ),
          _buildPickPhotoButton(
            title: 'Выберите из галереи',
            source: ImageSource.gallery,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPhotolView() {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        PlantPhotoView(file: _selectedImageFile),
        _buildAnalyzingText(),
      ],
    );
  }

  Widget _buildListingAdCard() {
  return Padding(
    padding: const EdgeInsets.only(right: 30.0, left: 30.0, bottom: 10.0), 
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 3,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.home, color: Colors.blue), // Icon for home
              Text(
                '3-комнатная квартира',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Set text color to black
                ),
              ),
              
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green), // Icon for price
              SizedBox(width: 5),
              Text(
                'Руб 2500,000',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.crop_square, color: Colors.orange), // Icon for size
              SizedBox(width: 5),
              Text(
                '120 кв. м',
                style: TextStyle(fontSize: 16, color: Colors.black), 
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red), // Icon for location
              SizedBox(width: 5),
              Text(
                'г. Москва, ул. Ленина, 123',
                style: TextStyle(fontSize: 13, color: Colors.black), 
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAnalyzingText() {
    if (!_isAnalyzing) {
      return const SizedBox.shrink();
    }
    return const Text('Analyzing...', style: kAnalyzingTextStyle);
  }

  Widget _buildTitle() {
    return const Text(
      'оценки качества отделочных работ помещения',
      style: kTitleTextStyle,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPickPhotoButton({
    required ImageSource source,
    required String title,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 20.0), // Adjust the value as needed
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25), // Adjust the value as needed
        child: TextButton(
          onPressed: () => _onPickPhoto(source),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(kColorBrown),
          ),
          child: Container(
            width: 300,
            height: 30,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: kButtonFont,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: kColorGreen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setAnalyzing(bool flag) {
    setState(() {
      _isAnalyzing = flag;
    });
  }

  void _onPickPhoto(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      return;
    }

    final imageFile = File(pickedFile.path);
    setState(() {
      _selectedImageFile = imageFile;
    });

    _analyzeImage(imageFile);
  }

  void _analyzeImage(File image) {
    _setAnalyzing(true);

    final imageInput = img.decodeImage(image.readAsBytesSync())!;

    final resultCategory = _classifier.predict(imageInput);

    final result = resultCategory.score >= 0.8
        ? _ResultStatus.found
        : _ResultStatus.notFound;
    final plantLabel = resultCategory.label;
    final accuracy = resultCategory.score;

    _setAnalyzing(false);

    setState(() {
      _resultStatus = result;
      _plantLabel = plantLabel;
      _accuracy = accuracy;
    });
  }

  Widget _buildResultView() {
    Widget icon;
    String hint = '';
    if (_resultStatus == _ResultStatus.notFound) {
      icon = const Icon(Icons.error_outline, color: Colors.red, size: 24);
      hint = 'Не удалось распознать';
    } else if (_resultStatus == _ResultStatus.found) {
      // Display thumbs up icon for 'good' and thumbs down icon for 'bad'
      if (_plantLabel == 'good') {
        icon = const Icon(Icons.thumb_up, color: Colors.green, size: 24);
        hint = 'Хорошо';
      } else if (_plantLabel == 'bad') {
        icon = const Icon(Icons.thumb_down, color: Colors.red, size: 24);
        hint = 'Плохо';
      } else {
        // Placeholder icon if _plantLabel is neither 'good' nor 'bad'
        icon = const Icon(Icons.help_outline, color: Colors.grey, size: 24);
        hint = 'Неопределенный результат';
      }
    } else {
      // Placeholder icon if _resultStatus is not found
      icon = const Icon(Icons.help_outline, color: Colors.grey, size: 24);
      hint = 'Неопределенный результат';
    }

    var accuracyLabel = '';
    if (_resultStatus == _ResultStatus.found) {
      accuracyLabel = 'Точность: ${(_accuracy * 100).toStringAsFixed(2)}%';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8), // Add spacing between icon and text
            Text(hint, style: TextStyle(color: Colors.black, fontSize: 20)),
          ],
        ),
        const SizedBox(height: 10),
        Text(accuracyLabel, style: kResultRatingTextStyle),
      ],
    );
  }


}
