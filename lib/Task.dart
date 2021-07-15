import 'package:flutter/material.dart';

class Task {
  Task(
      {this.id = 0,
      required this.title,
      this.date,
      this.icon,
      this.done = false,
      this.fail = false,
      this.xp = 0,
      this.money = 0,
      this.moneyLost = 0,
      this.xpLost = 0,
      this.directToFail = false,
      this.userRemovedFromFail = false,
      this.taskAddedPoints = false,
      this.taskType});
  int id;
  String title;
  bool done;
  bool fail;
  IconData? icon;
  DateTime? date;
  TaskType? taskType;
  //Control
  bool directToFail;
  bool userRemovedFromFail;
  bool taskAddedPoints;
  //Profile Effects
  double xp;
  double money;
  double xpLost;
  double moneyLost;

  static emptyTask() {
    return new Task(title: "");
  }

  Task clone() {
    return Task(
        id: this.id,
        title: this.title,
        date: this.date,
        done: this.done,
        fail: this.fail,
        taskType: this.taskType);
  }
}

class TaskGenerator {
  TaskGenerator({required this.type, required this.base});
  TaskType type;
  Task base;
}

abstract class TaskType {
  TaskType(
      {required this.xpPerTask,
      required this.xpPerTaskCombo,
      required this.moneyPerTask,
      required this.moneyPerTaskCombo,
      required this.xpLost,
      required this.moneyLost});
  Task generate(Task baseTask);
  bool finished();
  double xpPerTask;
  double xpPerTaskCombo;
  double moneyPerTask;
  double moneyPerTaskCombo;
  double xpLost;
  double moneyLost;
}

class TaskTypeOnce extends TaskType {
  TaskTypeOnce(
      {required double xpPerTask,
      required double xpPerTaskCombo,
      required double moneyPerTask,
      required double moneyPerTaskCombo,
      required double xpLost,
      required double moneyLost,
      required this.date,
      required this.id})
      : super(
            xpPerTask: xpPerTask,
            xpLost: xpLost,
            xpPerTaskCombo: xpPerTaskCombo,
            moneyLost: moneyLost,
            moneyPerTask: moneyPerTask,
            moneyPerTaskCombo: moneyPerTaskCombo);

  DateTime date;
  int id;

  bool done = false;

  @override
  Task generate(Task baseTask) {
    done = true;
    Task newTask = baseTask.clone();
    newTask.date = this.date;
    newTask.id = this.id;
    newTask.taskType = this;
    newTask.xp = this.xpPerTask;
    newTask.money = this.moneyPerTask;
    newTask.xpLost = this.xpLost;
    newTask.moneyLost = this.moneyLost;
    return newTask;
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
    var onLongPress = () {
      var a = task;
      if (!a.done) {
        //Because its going from not done -> fail
        a.directToFail = true;
        a.done = true;
        a.fail = true;
      } else if (!a.fail) {
        a.directToFail = false;
        a.done = true;
        a.fail = true;
      } else {
        onPressed();
        return;
      }
      taskChanged(a);
    };

    return Container(
        color: Color.fromARGB(255, 226, 226, 226),
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
                              onLongPress: onLongPress,
                              background: task.done
                                  ? task.fail
                                      ? Colors.red
                                      : Colors.green
                                  : Colors.blue,
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
      {Key? key,
      this.icon,
      this.background,
      required this.onPressed,
      this.onLongPress})
      : super(key: key);

  final IconData? icon;
  final Color? background;

  final void Function() onPressed;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: ButtonStyle(
        shape: MaterialStateProperty.all<CircleBorder>(CircleBorder()),
        backgroundColor: background == null
            ? null
            : MaterialStateProperty.all<Color>(background!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: icon != null ? Icon(icon) : null,
      ),
    );
  }
}
