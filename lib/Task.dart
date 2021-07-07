import 'package:flutter/material.dart';

class Task {
  Task({required this.title, this.date, this.time, this.done = false});
  String title;
  bool done;
  DateTime? date;
  TimeOfDay? time;

  static emptyTask() {
    return new Task(title: "");
  }
}

class TaskGenerator {
  TaskGenerator({required this.type, required this.base});
  TaskType type;
  Task base;
}

abstract class TaskType {
  Task generate(Task baseTask);
  bool finished();
}

class TaskTypeOnce extends TaskType {
  TaskTypeOnce({required this.time, required this.date});

  TimeOfDay time;
  DateTime date;

  bool done = false;

  @override
  Task generate(Task baseTask) {
    done = true;
    baseTask.date = this.date;
    baseTask.time = this.time;
    return baseTask;
  }

  @override
  bool finished() {
    return done;
  }
}
