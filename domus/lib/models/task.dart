import 'package:flutter/material.dart';
class Task with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final DateTime time;
  bool complete;

  Task(
      {required this.id,
      required this.title,
      required this.description,
      required this.time,
      required this.complete});

  void completeTask() {
    complete = !complete;
    notifyListeners();
  }
}
