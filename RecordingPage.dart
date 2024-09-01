
import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/survey_kit.dart';
import 'CameraPage.dart';
import 'main.dart';
List<String> results = [];

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final OrderedTask task1 = OrderedTask(id: TaskIdentifier(), steps: <Step>[
    InstructionStep(
      title: 'Workout survey',
      text: 'Fill out the survey as your first step towards a personal workout plan.',
      buttonText: 'Begin survey',
    ),
    QuestionStep(
      text: 'How many days a week would you like to work out?',
      isOptional: false,
      answerFormat: const SingleChoiceAnswerFormat(
        textChoices: <TextChoice>[
          TextChoice(text: '1', value: '1'),
          TextChoice(text: '2', value: '2'),
          TextChoice(text: '3', value: '3'),
          TextChoice(text: '4', value: '4'),
          TextChoice(text: '5', value: '5'),
          TextChoice(text: '6', value: '6'),
          TextChoice(text: '7', value: '7'),
        ],
      ),
    ),
    QuestionStep(
      text: 'How long would you like each workout to be?',
      isOptional: false,
      answerFormat: const SingleChoiceAnswerFormat(
        textChoices: <TextChoice>[
          TextChoice(text: 'Under 30 minutes', value: '30'),
          TextChoice(text: '30-60 minutes', value: '30-60'),
          TextChoice(text: '60-90 minutes', value: '60-90'),
          TextChoice(text: '90-120 minutes', value: '90-120'),
          TextChoice(text: 'Over 120 minutes', value: '120'),
        ],
      ),
    ),
    QuestionStep(
      text: 'How general (covers all parts of the body) or specific (targets your weakest areas) do you want the workout plan to be?',
      isOptional: false,
      answerFormat: const SingleChoiceAnswerFormat(
        textChoices: <TextChoice>[
          TextChoice(text: 'Very general', value: 'Very general'),
          TextChoice(text: 'Somewhat general', value: 'Somewhat general'),
          TextChoice(text: 'In between', value: 'In between'),
          TextChoice(text: 'Somewhat specific', value: 'Somewhat specific'),
          TextChoice(text: 'Very specific', value: 'Very specific'),
        ],
      ),
    ),
    CompletionStep(
      stepIdentifier: StepIdentifier(id: 'completion_step'),
      title: 'You have completed the survey!',
      text: 'On the next page, please record a video of yourself doing a bodyweight squat. For best results, face the camera, have your full body in view, and attempt to hold a 90 degree angle at your knees for 15 seconds.',
      buttonText: 'Submit survey and move to next page',
    ),
  ]);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Survey'),
      ),
      body: SurveyKit(
        task: task1,
        onResult: (SurveyResult result) {
          // Clear the results array before adding new entries
          results.clear();

          // Read finish reason from result (result.finishReason)
          // and evaluate the results
          for (var stepResult in result.results) {
            for (var questionResult in stepResult.results) {
              if (questionResult.result != null && questionResult.result.toString().isNotEmpty) {
                // Print for debugging
                print('Adding result: ${questionResult.result}');
                results.add(extractAfterSecondLastComma(questionResult.toString()));
              }
            }
          }
          // Navigate to another page after storing the results
          Navigator.push(context, MaterialPageRoute(builder: (context) => CameraPage(cameras: cameras)));
        },
      ),
    );
  }
}

String extractAfterSecondLastComma(String input) {
  // Split the input string by commas
  List<String> parts = input.split(',');

  // Trim the spaces around the second-to-last part and return
  return parts[parts.length - 2].trim();
}
