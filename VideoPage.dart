import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'HomePage.dart';
import 'ResultsPage.dart';
import 'package:video_player/video_player.dart';
import 'RecordingPage.dart';

String filePath = "";

class VideoPage extends StatefulWidget {
  final String filePath;

  const VideoPage({super.key, required this.filePath});

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoPlayerController;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    await _videoPlayerController.initialize();
    await _videoPlayerController.setLooping(true);
    await _videoPlayerController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        elevation: 0,
        backgroundColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // print('do something with the file');
              filePath = (widget.filePath);
              fileUpload(File(widget.filePath));
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultsPage()));
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder(
        future: _initVideoPlayer(),
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return VideoPlayer(_videoPlayerController);
          }
        },
      ),
    );
  }
}

Future<void> fileUpload(File videoFile) async {
  Uri uri = Uri.parse("your URL");

  var request = http.MultipartRequest('POST', uri);
  String fileName = videoFile.path.split("/").last;

  request.files.add(await http.MultipartFile.fromPath(
    'cv', // This is the field name that Django will look for
    videoFile.path,
    filename: fileName,
    contentType: MediaType('application', 'octet-stream'), // You can set the appropriate content type
  ));

  request.fields['name'] = fileName;
  request.fields['numDays'] = results[0];
  request.fields['length'] = results[1];
  request.fields['focus'] = results[2];
  var response = await request.send();
  results.clear();
  // Handle response
  if (response.statusCode == 200) {
    print('Uploaded!');
  } else {
    print('Upload failed: ${response.reasonPhrase}');
     MaterialPageRoute(builder: (context) => HomePage());
  }
}



