import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'HomePage.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<Note> futureNote;

  @override
  void initState() {
    super.initState();
    futureNote = fetchNoteWithRetry();
  }
  
  Future<Note> fetchNoteWithRetry() async {
    const int maxRetries = 6; // Number of retries
    const Duration retryInterval = Duration(seconds: 5); // Retry interval

    for (int i = 0; i < maxRetries; i++) {
      try {
        final note = await fetchLatestNote();
        // Check if the note is less than 30 seconds old
        final createdTime = DateTime.parse(note.created);
        final now = DateTime.now();
        final duration = now.difference(createdTime);

        if (duration.inSeconds < 240 && note.workoutPlan != "no workout plan" && !note.completed) {
          return note;
        } else {
          // Wait before retrying if the note is older than 30 seconds or has "no workout plan"
          if (i < maxRetries - 1) {
            await Future.delayed(retryInterval);
          }
        }
      } catch (e) {
        if (i == maxRetries - 1) {
          rethrow; // Rethrow if it's the last retry
        }
        await Future.delayed(retryInterval);
      }
    }
    throw Exception('Failed to fetch valid data after $maxRetries attempts');

  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: const Text('Results:'),
      automaticallyImplyLeading: false, // Hides the back arrow
    ),
    body: FutureBuilder<Note>(
      future: futureNote,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog(context, snapshot.error.toString());
          });
          return Container(); // Return an empty container while the dialog is being shown
        } else if (snapshot.hasData) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Here is your custom workout plan:\n${snapshot.data!.workoutPlan}',
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20), 
                  ElevatedButton(
                    onPressed: () async {
                      final workoutName = await _showWorkoutNameDialog(context);
                      if (workoutName != null && workoutName.isNotEmpty) {
                        await markNoteAsCompleted(workoutName);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              workoutName: workoutName,
                              workoutPlan: snapshot.data!.workoutPlan
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Back to home'),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    ),
  );
}

Future<void> _showErrorDialog(BuildContext context, String errorMessage) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: <Widget>[
          TextButton(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
        ],
      );
    },
  );
}

  Future<String?> _showWorkoutNameDialog(BuildContext context) async {
    String workoutName = '';
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Workout Name'),
          content: TextField(
            onChanged: (value) {
              workoutName = value;
            },
            decoration: const InputDecoration(hintText: "Workout Name"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(workoutName);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class Note {
  final String workoutPlan;
  final String created; 
  final bool completed;

  Note({
    required this.workoutPlan,
    required this.created,
    required this.completed
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('workoutPlan') && json.containsKey('created')) {
      return Note(
        workoutPlan: json['workoutPlan'],
        created: json['created'],
        completed: json['completed']
      );
    } else {
      throw Exception('Invalid JSON format');
    }
  }
}

Future<Note> fetchLatestNote() async {
  final response = await http.get(Uri.parse('your URL'));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    return Note.fromJson(jsonResponse);
  } else {
    throw Exception('Failed to load latest note. Status code: ${response.statusCode}');
  }
}

Future<void> markNoteAsCompleted(String workoutName) async {
  final url = Uri.parse('your URL');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'workoutName': workoutName,
    }),
  );

  if (response.statusCode == 200) {
    // Successfully marked as completed
    print('Note marked as completed');
  } else {
    // Error handling
    print('Failed to mark note as completed');
    print('Error: ${response.body}');
    MaterialPageRoute(builder: (context) => HomePage());
  }
}


