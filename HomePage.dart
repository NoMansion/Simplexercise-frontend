import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RecordingPage.dart';
import 'workout.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final String workoutName;
  final String workoutPlan;

  const HomePage({super.key, this.workoutName = '', this.workoutPlan = ''});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<Workout> workouts = [
  ];

  late SharedPreferences sp;
  bool _isOnCooldown = false; // Variable to track cooldown state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add this widget as an observer
    _initializePreferences();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runCodeOnRelaunch();
    }
  }

  void _runCodeOnRelaunch() {
    // Code to run every time the app is relaunched
    print("App is relaunched or resumed");
  }

  Future<void> _initializePreferences() async {
    sp = await SharedPreferences.getInstance();
    await _readFromSp();

    // Add new workout if provided in the widget
    if (widget.workoutName.isNotEmpty && widget.workoutPlan.isNotEmpty) {
      _addWorkout(widget.workoutName, widget.workoutPlan);
    }
  }

  Future<void> _saveIntoSp() async {
    // Ensure SharedPreferences is initialized
    List<String> workoutListString = workouts.map((workout) => jsonEncode(workout.toJson())).toList();
    await sp.setStringList('myData', workoutListString);
  }

  Future<void> _readFromSp() async {
    List<String>? workoutListString = sp.getStringList('myData');
    if (workoutListString != null) {
      setState(() {
        workouts = workoutListString.map((workout) => Workout.fromJson(jsonDecode(workout))).toList();
      });
    }
  }

  void _renameWorkout(int index, String newName) {
    setState(() {
      workouts[index].name = newName;
    });
    _saveIntoSp(); // Save the updated workouts list
  }

  void _addWorkout(String workoutName, String workoutPlan) {
    setState(() {
      workouts.add(Workout(name: workoutName, plan: workoutPlan));
    });
    _saveIntoSp(); // Save the updated workouts list
  }

  void _deleteWorkout(int index) {
    setState(() {
      workouts.removeAt(index);
    });
    _saveIntoSp(); // Save the updated workouts list
  }

  Future<void> _confirmDeleteWorkout(int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this workout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteWorkout(index);
    }
  }

  Future<bool> _testServerConnection() async {
    final url = Uri.parse('your URL'); // Replace with your Django server URL
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void _showDialog(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _startCooldown() {
    setState(() {
      _isOnCooldown = true;
    });
    Timer(const Duration(seconds: 15), () {
      setState(() {
        _isOnCooldown = false;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove this widget as an observer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Simplexercise'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isOnCooldown
                ? null // Disable button if on cooldown
                : () async {
                    bool connection = await _testServerConnection();
                    if (connection) {
                      _startCooldown(); // Start cooldown when button is pressed
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordingPage()));
                    } else {
                      _showDialog('Error', 'Failed to connect to server, try again later');
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Click the plus sign in the top right to fill out a quick survey, record a video of a simple exercise, then receive a custom AI powered training plan.\n\nSee previously created plans below:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.purple[100], // Light purple background color
                  margin: const EdgeInsets.symmetric(vertical: 4.0), // Optional: add some vertical margin
                  child: ListTile(
                    title: Text(workouts[index].name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                TextEditingController controller = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Rename Workout'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(hintText: "Enter new name"),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _renameWorkout(index, controller.text);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Rename'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _confirmDeleteWorkout(index);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutDetailPage(workout: workouts[index])));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutDetailPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailPage({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(workout.plan),
      ),
    );
  }
}
