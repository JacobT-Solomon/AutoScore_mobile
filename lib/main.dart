import 'dart:convert';
import 'dart:io' show File; // for non-web file saving
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;



void main() {
  runApp(const ScoreboardApp());
}

class ScoreboardApp extends StatelessWidget {
  const ScoreboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoScore Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const ScoreboardPage(),
    );
  }
}

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  int team1Score = 0;
  int team2Score = 0;
  String team1Name = "Team 1";
  String team2Name = "Team 2";
  bool recording = false;
  bool hasSaved = false;
  late DateTime startTime;
  List<Map<String, dynamic>> scoreEvents = [];

  /// ----------------------------
  /// START / RESET RECORDING LOGIC
  /// ----------------------------
  Future<void> recordEvent() async {
    if (!recording) {
      // Start a new recording session
      startTime = DateTime.now();
      recording = true;
      hasSaved = false;
      scoreEvents.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording started")),
      );
      setState(() {});
      return;
    }

    // Already recording — check if user wants to reset
    if (recording && !hasSaved) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Unsaved Recording"),
          content: const Text(
              "You are already recording and haven't saved yet.\nPressing Record again will wipe your current data.\n\nDo you want to start a new recording?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes, Start New"),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      // Wipe previous unsaved session
      setState(() {
        team1Score = 0;
        team2Score = 0;
        scoreEvents.clear();
        startTime = DateTime.now();
        hasSaved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Started new recording (previous wiped)")),
      );
      return;
    }

    // Recording already, and previous has been saved — start new clean recording
    if (recording && hasSaved) {
      setState(() {
        team1Score = 0;
        team2Score = 0;
        scoreEvents.clear();
        startTime = DateTime.now();
        hasSaved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New recording started")),
      );
    }
  }

  /// ----------------------------
  /// LOG SCORE CHANGES
  /// ----------------------------
  void logScoreChange() {
    if (!recording) return;
    final elapsed =
        DateTime.now().difference(startTime).inMilliseconds / 1000.0;

    setState(() {
      scoreEvents.add({
        "time": elapsed,
        "team1": team1Score,
        "team2": team2Score,
      });
    });
  }

  /// ----------------------------
  /// SAVE JSON TO FILE / DOWNLOAD
  /// ----------------------------
  Future<void> saveJsonFile() async {
    final data = {
      "team1_name": team1Name,
      "team2_name": team2Name,
      "team1_score": team1Score,
      "team2_score": team2Score,
      "score_events": scoreEvents,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    if (kIsWeb) {
      // 📂 On web: download as file (works on all modern Flutter versions)

      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'score_events${DateTime.now().millisecondsSinceEpoch}.json')
        ..click();
      html.Url.revokeObjectUrl(url);
}





    setState(() {
      hasSaved = true;
    });
  }

  /// ----------------------------
  /// RESET SCORES
  /// ----------------------------
  void resetScores() {
    setState(() {
      team1Score = 0;
      team2Score = 0;
    });
  }

  /// ----------------------------
  /// UI BUILD
  /// ----------------------------
  @override
  Widget build(BuildContext context) {
    const TextStyle scoreStyle = TextStyle(
      fontSize: 80,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scoreboard Recorder"),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Team names
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(team1Name, style: const TextStyle(fontSize: 24)),
                Text(team2Name, style: const TextStyle(fontSize: 24)),
              ],
            ),

            // Scores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(team1Score.toString(), style: scoreStyle),
                Text(team2Score.toString(), style: scoreStyle),
              ],
            ),

            // Score buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => team1Score++);
                        logScoreChange();
                      },
                      child: const Text('+', style: TextStyle(fontSize: 32)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (team1Score > 0) team1Score--;
                        });
                        logScoreChange();
                      },
                      child: const Text('-', style: TextStyle(fontSize: 32)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => team2Score++);
                        logScoreChange();
                      },
                      child: const Text('+', style: TextStyle(fontSize: 32)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (team2Score > 0) team2Score--;
                        });
                        logScoreChange();
                      },
                      child: const Text('-', style: TextStyle(fontSize: 32)),
                    ),
                  ],
                ),
              ],
            ),

            // Control buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: recordEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        recording ? Colors.redAccent : Colors.red,
                  ),
                  child: Text(
                    recording ? "Recording..." : "Record",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: resetScores,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("Reset Scores",
                      style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: saveJsonFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child:
                      const Text("Save JSON", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
