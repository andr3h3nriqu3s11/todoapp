import 'package:app/Task.dart';

abstract class TaskType {
  TaskType(
      {required this.xpPerTask,
      required this.xpPerTaskCombo,
      required this.moneyPerTask,
      required this.moneyPerTaskCombo,
      required this.xpLost,
      required this.moneyLost,
      required this.id});

  Task? generate(Task baseTask, Iterable<Task> oldTasks);
  bool finished();
  Task? generateGhostTask(Task baseTask, Iterable<Task> oldTasks);
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

  String id;
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
      required String id,
      this.done = false})
      : super(
            xpPerTask: xpPerTask,
            xpLost: xpLost,
            xpPerTaskCombo: xpPerTaskCombo,
            moneyLost: moneyLost,
            moneyPerTask: moneyPerTask,
            moneyPerTaskCombo: moneyPerTaskCombo,
            id: id);

  bool done;
  DateTime date;

  @override
  bool finished() {
    return this.done;
  }

  @override
  Task generate(Task baseTask, Iterable<Task> oldTasks) {
    done = true;
    Task newTask = baseTask.clone()..generateIdUUId();
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
  Task? generateGhostTask(Task baseTask, Iterable<Task> oldTasks) {
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
      required this.date,
      required String id})
      : super(
            xpPerTask: xpPerTask,
            xpLost: xpLost,
            xpPerTaskCombo: xpPerTaskCombo,
            moneyLost: moneyLost,
            moneyPerTask: moneyPerTask,
            moneyPerTaskCombo: moneyPerTaskCombo,
            id: id);

  DateTime date;

  @override
  bool finished() {
    return false;
  }

  @override
  Task? generate(Task baseTask, Iterable<Task> oldTasks) {
    //done = true;

    Task? lastTask;

    oldTasks
        .where((element) =>
            (element.taskType is TaskTypeRepeatEveryDay) &&
            element.generatorId == this.id)
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
    Task newTask = baseTask.clone()..generateIdUUId();
    newTask.date = DateTime(
        today.year, today.month, today.day, this.date.hour, this.date.minute);
    newTask.generatorId = this.id;
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
  Task? generateGhostTask(Task baseTask, Iterable<Task> oldTasks) {
    Task? lastTask;

    oldTasks
        .where((element) => element.taskType is TaskTypeRepeatEveryDay)
        .forEach((element) {
      if (lastTask == null &&
          element.date != null &&
          element.generatorId == this.id) {
        lastTask = element;
      } else if (lastTask != null &&
          element.date != null &&
          lastTask!.date!.isBefore(element.date!) &&
          element.generatorId == this.id) {
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
    newTask.generatorId = this.id;
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
        id: json["id"]);
  }
}

// This is a TaskType that refers to the task that is created as "punishment task"
class TaskTypeFailTask extends TaskType {
  TaskTypeFailTask({
    required double xpPerTask,
    required double xpPerTaskCombo,
    required double moneyPerTask,
    required double moneyPerTaskCombo,
    required double xpLost,
    required double moneyLost,
    required String id,
    required this.daysToComplete,
  }) : super(
            xpPerTask: xpPerTask,
            xpLost: xpLost,
            xpPerTaskCombo: xpPerTaskCombo,
            moneyLost: moneyLost,
            moneyPerTask: moneyPerTask,
            moneyPerTaskCombo: moneyPerTaskCombo,
            id: id);

  int daysToComplete;

  factory TaskTypeFailTask.fromJson(Map<String, dynamic> json) {
    return TaskTypeFailTask(
        moneyLost: json["moneyLost"],
        moneyPerTask: json["moneyPerTask"],
        moneyPerTaskCombo: json["moneyPerTaskCombo"],
        xpLost: json["xpLost"],
        xpPerTask: json["xpPerTask"],
        xpPerTaskCombo: json["xpPerTaskCombo"],
        id: json["id"],
        daysToComplete: json["daysToComplete"]);
  }

  @override
  bool finished() {
    return false;
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
        "id": this.id,
        "daysToComplete": this.daysToComplete,
      }
    };
  }

  @override
  Task? generate(Task _baseTask, Iterable<Task> _oldTasks) {
    return null;
  }

  Task generateFail(Task baseTask) {
    Task newTask = baseTask.clone()..generateIdUUId();
    newTask.generatorId = this.id;
    newTask.taskType = this;
    newTask.xp = this.xpPerTask;
    newTask.money = this.moneyPerTask;
    newTask.xpLost = this.xpLost;
    newTask.moneyLost = this.moneyLost;

    DateTime date = DateTime.now();
    date.add(Duration(days: this.daysToComplete));
    newTask.date = date;

    return newTask;
  }

  @override
  Task? generateGhostTask(Task baseTask, Iterable<Task> oldTasks) {
    return null;
  }
}
