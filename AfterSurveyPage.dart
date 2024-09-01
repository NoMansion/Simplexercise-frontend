import 'package:flutter/material.dart';

class AfterSurveyPage extends StatefulWidget {
  const AfterSurveyPage({super.key});

  @override
  State<AfterSurveyPage> createState() => _AfterSurveyPage();
}

class _AfterSurveyPage extends State<AfterSurveyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text ('Survey complete!')
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Next, record a video of you doing a body weight squat. Face the camera while you do it, and try to form a 90 degree angle at your knees using your legs.',
                  textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/three');
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }
}