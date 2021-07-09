import 'package:flutter/material.dart';

class Task {
  Task(
      {this.id = 0,
      required this.title,
      this.date,
      this.icon,
      this.done = false,
      this.taskType});
  int id;
  String title;
  bool done;
  IconData? icon;
  DateTime? date;
  TaskType? taskType;

  static emptyTask() {
    return new Task(title: "");
  }

  Task clone() {
    return Task(
        id: this.id,
        title: this.title,
        date: this.date,
        done: this.done,
        taskType: this.taskType);
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
  TaskTypeOnce({required this.date, required this.id});

  DateTime date;
  int id;

  bool done = false;

  @override
  Task generate(Task baseTask) {
    done = true;
    Task newTask = baseTask.clone();
    newTask.date = this.date;
    newTask.id = this.id;
    return baseTask;
  }

  @override
  bool finished() {
    return done;
  }
}

class TaskWidget extends StatelessWidget {
  const TaskWidget({Key? key, required this.task, required this.taskChanged})
      : super(key: key);
  final Task task;
  final ValueChanged<Task> taskChanged;

  @override
  Widget build(BuildContext context) {
    var onPressed = () {
      var a = task;
      a.done = !a.done;
      taskChanged(a);
    };

    return Container(
        color: Colors.grey.shade500,
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(task.date.toString())],
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Row(
                    children: [
                      Container(
                          child: TaskWidgetIcon(
                              onPressed: onPressed,
                              background: task.done ? Colors.blue : Colors.grey,
                              icon: task.icon)),
                      Text(task.title),
                    ],
                  ),
                )
              ],
            )));
  }
}

class TaskWidgetIcon extends StatelessWidget {
  const TaskWidgetIcon(
      {Key? key, this.icon, this.background, required this.onPressed})
      : super(key: key);

  final IconData? icon;
  final Color? background;

  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? Ink(
            decoration:
                ShapeDecoration(shape: CircleBorder(), color: background),
            child: IconButton(onPressed: onPressed, icon: Icon(icon)))
        : ElevatedButton(
            onPressed: onPressed,
            style: ButtonStyle(
              shape: MaterialStateProperty.all<CircleBorder>(CircleBorder()),
              backgroundColor: background == null
                  ? null
                  : MaterialStateProperty.all<Color>(background!),
            ),
            child: const Padding(
              padding: const EdgeInsets.all(1.0),
            ),
          );
  }
}
