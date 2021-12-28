import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  Map<String, dynamic> toJSON() {
    var icon = this.icon == null
        ? null
        : {
            "codePoint": this.icon?.codePoint,
            "fontFamily": this.icon?.fontFamily,
            "fontPackage": this.icon?.fontPackage,
            "matchTextDirection": this.icon?.matchTextDirection,
          };
    return {
      "id": this.id,
      "title": this.title,
      "done": this.done,
      "fail": this.fail,
      "icon": icon,
      "date": this.date == null ? null : this.date!.toIso8601String(),
      "taskType": this.taskType == null ? null : this.taskType!.toJson(),
      "directToFail": this.directToFail,
      "taskAddedPoints": this.taskAddedPoints,
      "xp": this.xp,
      "money": this.money,
      "xpLost": this.xpLost,
      "moneyLost": this.moneyLost,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var icon = json["icon"] != null
        ? IconData(json["icon"]["codePoint"],
            fontFamily: json["icon"]["fontFamily"],
            fontPackage: json["icon"]["fontPackage"],
            matchTextDirection: json["icon"]["matchTextDirection"])
        : null;
    return Task(
      id: json["id"],
      title: json["title"],
      done: json["done"],
      fail: json["fail"],
      icon: icon,
      date: json["date"] == null ? null : DateTime.tryParse(json["date"]),
      taskType:
          json["taskType"] == null ? null : TaskType.fromJson(json["taskType"]),
      directToFail: json["directToFail"],
      taskAddedPoints: json["taskAddedPoints"],
      xp: json["xp"],
      money: json["money"],
      xpLost: json["xpLost"],
      moneyLost: json["moneyLost"],
    );
  }
}

class TaskGenerator {
  TaskGenerator({required this.type, required this.base});
  TaskType type;
  Task base;
  Map<String, dynamic> toJson() {
    return {"base": base.toJSON(), "type": type.toJson()};
  }

  factory TaskGenerator.fromJson(Map<String, dynamic> json) {
    return TaskGenerator(
        type: TaskType.fromJson(json["type"]),
        base: Task.fromJson(json['base']));
  }
}

abstract class TaskType {
  TaskType(
      {required this.xpPerTask,
      required this.xpPerTaskCombo,
      required this.moneyPerTask,
      required this.moneyPerTaskCombo,
      required this.xpLost,
      required this.moneyLost,
      required this.date,
      required this.done,
      required this.id});

  Task? generate(Task baseTask, List<Task> oldTasks);

  bool finished() {
    return this.done;
  }

  Task? generateGhostTask(Task baseTask, List<Task> oldTasks);
  Map<String, dynamic> toJson();

  factory TaskType.fromJson(Map<String, dynamic> json) {
    if (json["type"] == "once") {
      return TaskTypeOnce.fromJson(json["json"]);
    } else if (json["type"] == "repeatEveryDay") {
      return TaskTypeRepeatEveryDay.fromJson(json["json"]);
    } else if (json["type"] == "failTask") {
      return TaskTypeFailTask.fromJson(json["json"]);
    } else {
      throw Exception("InvalidJson");
    }
  }

  double xpPerTask;
  double xpPerTaskCombo;
  double moneyPerTask;
  double moneyPerTaskCombo;
  double xpLost;
  double moneyLost;
  DateTime date;
  int id;
  bool done = false;
}

class TaskTypeOnce extends TaskType {
  TaskTypeOnce(
      {required double xpPerTask,
      required double xpPerTaskCombo,
      required double moneyPerTask,
      required double moneyPerTaskCombo,
      required double xpLost,
      required double moneyLost,
      required DateTime date,
      required int id,
      bool done = false})
      : super(
            xpPerTask: xpPerTask,
            xpLost: xpLost,
            xpPerTaskCombo: xpPerTaskCombo,
            moneyLost: moneyLost,
            moneyPerTask: moneyPerTask,
            moneyPerTaskCombo: moneyPerTaskCombo,
            date: date,
            id: id,
            done: done);

  @override
  Task generate(Task baseTask, List<Task> oldTasks) {
    done = true;
    Task newTask = baseTask.clone();
    newTask.date = this.date;
    newTask.id = this.id;
    newTask.taskType = this;
    newTask.xp = this.xpPerTask;
    newTask.money = this.moneyPerTask;
    newTask.xpLost = this.xpLost;
    newTask.moneyLost = this.moneyLost;
    if (this.date.isBefore(DateTime.now())) {
      newTask.userRemovedFromFail = true;
    }
    return newTask;
  }

  @override
  Task? generateGhostTask(Task baseTask, List<Task> oldTasks) {
    return null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'once',
      'json': {
        "xpPerTask": this.xpPerTask,
        "xpLost": this.xpLost,
        "xpPerTaskCombo": this.xpPerTaskCombo,
        "moneyLost": this.moneyLost,
        "moneyPerTask": this.moneyPerTask,
        "moneyPerTaskCombo": this.moneyPerTaskCombo,
        "done": this.done,
        "id": this.id,
        "date": date.toIso8601String()
      }
    };
  }

  factory TaskTypeOnce.fromJson(Map<String, dynamic> json) {
    return TaskTypeOnce(
        date: DateTime.tryParse(json["date"])!,
        moneyLost: json["moneyLost"],
        moneyPerTask: json["moneyPerTask"],
        moneyPerTaskCombo: json["moneyPerTaskCombo"],
        xpLost: json["xpLost"],
        xpPerTask: json["xpPerTask"],
        xpPerTaskCombo: json["xpPerTaskCombo"],
        id: json["id"],
        done: json["done"]);
  }
}

class TaskTypeRepeatEveryDay extends TaskType {
  TaskTypeRepeatEveryDay(
      {required double xpPerTask,
      required double xpPerTaskCombo,
      required double moneyPerTask,
      required double moneyPerTaskCombo,
      required double xpLost,
      required double moneyLost,
      required DateTime date,
      bool done = false,
      required int id})
      : super(
            xpPerTask: xpPerTask,
            xpLost: xpLost,
            xpPerTaskCombo: xpPerTaskCombo,
            moneyLost: moneyLost,
            moneyPerTask: moneyPerTask,
            moneyPerTaskCombo: moneyPerTaskCombo,
            id: id,
            done: done,
            date: date);

  @override
  Task? generate(Task baseTask, List<Task> oldTasks) {
    //done = true;

    Task? lastTask;

    oldTasks
        .where((element) =>
            (element.taskType is TaskTypeRepeatEveryDay) &&
            element.id == this.id)
        .forEach((element) {
      if (lastTask == null && element.date != null) {
        lastTask = element;
      } else if (lastTask != null &&
          element.date != null &&
          lastTask!.date!.isBefore(element.date!)) {
        lastTask = element;
      }
    });

    DateTime today = DateTime.now();
    if (lastTask != null &&
        today.year == lastTask!.date!.year &&
        today.month == lastTask!.date!.month &&
        today.day == lastTask!.date!.day) return null;

    //Generate new task
    Task newTask = baseTask.clone();
    newTask.date = DateTime(
        today.year, today.month, today.day, this.date.hour, this.date.minute);
    newTask.id = this.id;
    newTask.taskType = this;
    newTask.xp = this.xpPerTask;
    newTask.money = this.moneyPerTask;
    newTask.xpLost = this.xpLost;
    newTask.moneyLost = this.moneyLost;
    if (newTask.date!.isBefore(DateTime.now())) {
      newTask.userRemovedFromFail = true;
    }
    return newTask;
  }

  @override
  Task? generateGhostTask(Task baseTask, List<Task> oldTasks) {
    Task? lastTask;

    oldTasks
        .where((element) => element.taskType is TaskTypeRepeatEveryDay)
        .forEach((element) {
      if (lastTask == null && element.date != null && element.id == this.id) {
        lastTask = element;
      } else if (lastTask != null &&
          element.date != null &&
          lastTask!.date!.isBefore(element.date!) &&
          element.id == this.id) {
        lastTask = element;
      }
    });

    DateTime today = DateTime.now();
    if (lastTask == null ||
        (today.year == lastTask!.date!.year &&
            today.month == lastTask!.date!.month &&
            today.day == lastTask!.date!.day &&
            !lastTask!.done)) return null;

    DateTime tomorrow = DateTime.now().add(Duration(hours: 24));

    //Generate new task
    Task newTask = baseTask.clone();
    newTask.date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
        this.date.hour, this.date.minute);
    newTask.id = this.id;
    newTask.taskType = this;
    newTask.xp = this.xpPerTask;
    newTask.money = this.moneyPerTask;
    newTask.xpLost = this.xpLost;
    newTask.moneyLost = this.moneyLost;
    return newTask;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'repeatEveryDay',
      'json': {
        "xpPerTask": this.xpPerTask,
        "xpLost": this.xpLost,
        "xpPerTaskCombo": this.xpPerTaskCombo,
        "moneyLost": this.moneyLost,
        "moneyPerTask": this.moneyPerTask,
        "moneyPerTaskCombo": this.moneyPerTaskCombo,
        "done": this.done,
        "id": this.id,
        "date": date.toIso8601String()
      }
    };
  }

  factory TaskTypeRepeatEveryDay.fromJson(Map<String, dynamic> json) {
    return TaskTypeRepeatEveryDay(
        date: DateTime.tryParse(json["date"])!,
        moneyLost: json["moneyLost"],
        moneyPerTask: json["moneyPerTask"],
        moneyPerTaskCombo: json["moneyPerTaskCombo"],
        xpLost: json["xpLost"],
        xpPerTask: json["xpPerTask"],
        xpPerTaskCombo: json["xpPerTaskCombo"],
        id: json["id"],
        done: json["done"]);
  }
}

class TaskTypeFailTask extends TaskType {
  TaskTypeFailTask({
    required double xpPerTask,
    required double xpPerTaskCombo,
    required double moneyPerTask,
    required double moneyPerTaskCombo,
    required double xpLost,
    required double moneyLost,
    required DateTime date,
    required int id,
    bool done = false,
  }) : super(
            xpPerTask: xpPerTask,
            xpLost: xpLost,
            xpPerTaskCombo: xpPerTaskCombo,
            moneyLost: moneyLost,
            moneyPerTask: moneyPerTask,
            moneyPerTaskCombo: moneyPerTaskCombo,
            id: id,
            date: date,
            done: done);

  factory TaskTypeFailTask.fromJson(Map<String, dynamic> json) {
    return TaskTypeFailTask(
        date: DateTime.tryParse(json["date"])!,
        moneyLost: json["moneyLost"],
        moneyPerTask: json["moneyPerTask"],
        moneyPerTaskCombo: json["moneyPerTaskCombo"],
        xpLost: json["xpLost"],
        xpPerTask: json["xpPerTask"],
        xpPerTaskCombo: json["xpPerTaskCombo"],
        id: json["id"],
        done: json["done"]);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'fail',
      'json': {
        "xpPerTask": this.xpPerTask,
        "xpLost": this.xpLost,
        "xpPerTaskCombo": this.xpPerTaskCombo,
        "moneyLost": this.moneyLost,
        "moneyPerTask": this.moneyPerTask,
        "moneyPerTaskCombo": this.moneyPerTaskCombo,
        "done": this.done,
        "id": this.id,
        "date": this.date.toIso8601String()
      }
    };
  }

  @override
  Task generate(Task baseTask, List<Task> oldTasks) {
    done = true;
    Task newTask = baseTask.clone();
    newTask.date = this.date;
    newTask.id = this.id;
    newTask.taskType = this;
    newTask.xp = this.xpPerTask;
    newTask.money = this.moneyPerTask;
    newTask.xpLost = this.xpLost;
    newTask.moneyLost = this.moneyLost;
    if (this.date.isBefore(DateTime.now())) {
      newTask.userRemovedFromFail = true;
    }
    return newTask;
  }

  @override
  Task? generateGhostTask(Task baseTask, List<Task> oldTasks) {
    return null;
  }
}

class TaskWidget extends StatelessWidget {
  const TaskWidget(
      {Key? key,
      required this.task,
      this.ghost = false,
      required this.taskChanged})
      : super(key: key);
  final bool ghost;
  final Task task;
  final ValueChanged<Task> taskChanged;

  @override
  Widget build(BuildContext context) {
    var onPressed = () {
      var a = task;
      //Treat if this is a ghost list item then it works diferently. A simple tap
      //Will mark task as done
      if (ghost) {
        a.done = true;
        taskChanged(a);
        return;
      }
      a.done = !a.done;
      taskChanged(a);
    };
    var onLongPress = () {
      var a = task;
      //Treat if this is a ghost list item then it works diferently. A long tap
      //Will mark task as fail
      if (ghost) {
        a.fail = true;
        taskChanged(a);
        return;
      }

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

    String date = ghost ? "Available " : '';
    var f = NumberFormat("00");

    var sDate = !ghost;

    if (isTheSameDay(task.date!, DateTime.now())) {
      if (task.date!.hour == 23 && task.date!.minute == 59) {
        date += "Until the end Today";
        sDate = false;
      } else {
        date += "Today ";
      }
    } else if (isTheSameDay(
        task.date!, DateTime.now().add(Duration(hours: 24)))) {
      date += "Tomorow ";
    } else {
      date += f.format(task.date!.day) +
          "/" +
          f.format(task.date!.month) +
          "/" +
          f.format(task.date!.year);
    }
    if (sDate) {
      date += " " +
          task.date!.hour.toString() +
          " : " +
          f.format(task.date!.minute);
    }

    return Container(
        color: Color.fromARGB(255, 226, 226, 226),
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(date)],
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

bool isTheSameDay(DateTime time1, DateTime time2) {
  return time1.day == time2.day &&
      time1.month == time2.month &&
      time1.year == time2.year;
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
