import 'package:app/Profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Task {
  Task(
      {required this.title,
      required this.id,
      this.generatorId = "",
      this.date,
      this.icon,
      this.done = false,
      this.fail = false,
      this.xp = 0,
      this.money = 0,
      this.moneyLost = 0,
      this.xpLost = 0,
      this.notificationId,
      this.userRemovedFromFail = false,
      this.taskType,
      this.failTasks})
      : this.generatedFailIds = [];

  //Ids
  String id;
  String generatorId;

  List<String> generatedFailIds;
  //Notification
  int? notificationId;

  String title;
  bool done;
  bool fail;
  IconData? icon;
  DateTime? date;
  TaskType? taskType;

  // Fail Actions
  List<String>? failTasks;

  //Control
  bool userRemovedFromFail;

  //Profile Effects
  double xp;
  double money;
  double xpLost;
  double moneyLost;

  static emptyTask() {
    return new Task(title: "", id: "");
  }

  Task clone() {
    return Task(
        id: this.id,
        generatorId: this.generatorId,
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
      "generatorId": this.generatorId,
      "title": this.title,
      "done": this.done,
      "fail": this.fail,
      "icon": icon,
      "date": this.date == null ? null : this.date!.toIso8601String(),
      "taskType": this.taskType == null ? null : this.taskType!.toJson(),
      "xp": this.xp,
      "money": this.money,
      "xpLost": this.xpLost,
      "moneyLost": this.moneyLost,
      "failTasks": this.failTasks,
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
      generatorId: json["generatorId"],
      title: json["title"],
      done: json["done"],
      fail: json["fail"],
      icon: icon,
      date: json["date"] == null ? null : DateTime.tryParse(json["date"]),
      taskType:
          json["taskType"] == null ? null : TaskType.fromJson(json["taskType"]),
      xp: json["xp"],
      money: json["money"],
      xpLost: json["xpLost"],
      moneyLost: json["moneyLost"],
      failTasks: json["failTasks"],
    );
  }

  void generateIdUUId() {
    if (this.id != "") return;
    this.id = Uuid().v1();
  }

  void taskFail(
      TaskGenerators generatorList, TaskManager taskMan, Profile profile) {
    this.done = true;
    this.fail = true;

    if (this.failTasks != null) {
      List<String> generatedIds = [];

      this.failTasks!.forEach((e) {
        TaskGenerator? taskGen = generatorList.get(e);
        if (taskGen != null && taskGen.type is TaskTypeFailTask) {
          TaskTypeFailTask gen = taskGen.type as TaskTypeFailTask;
          Task task = gen.generateFail(taskGen.base);
          taskMan.add(task);
        }
      });
    }

    profile.taskFail(this);
  }

  void toggle(
    TaskGenerators generatorList,
    TaskManager taskMan,
    Profile profile,
  ) {
    if (done)
      deactivate(generatorList, taskMan, profile);
    else {
      done = true;
      userRemovedFromFail = false;
      profile.completeTask(this);
    }
  }

  // This functions removes the done state of a task
  void deactivate(
    TaskGenerators generatorList,
    TaskManager taskMan,
    Profile profile,
  ) {
    done = false;
    if (fail) {
      fail = false;
      userRemovedFromFail = true;
      profile.removeDamages(this);

      generatedFailIds.forEach((element) {
        var t = taskMan.getTaskByIdUUID(element);
        if (t != null) {
          t.deactivate(generatorList, taskMan, profile);
          taskMan.removeTask(t);
        }
      });

      generatedFailIds = [];
    } else
      profile.removeWinnings(this);
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
    return newTask;
  }

  @override
  Task? generateGhostTask(Task baseTask, Iterable<Task> oldTasks) {
    return null;
  }
}

class TaskWidget extends StatelessWidget {
  const TaskWidget(
      {Key? key,
      required this.task,
      this.ghost = false,
      this.setState,
      this.profile,
      this.setLastTask,
      this.man,
      this.gens,
      this.shortClick,
      this.longClick})
      : super(key: key);

  final bool ghost;
  final Task task;

  final Profile? profile;
  final TaskManager? man;
  final TaskGenerators? gens;

  final void Function()? shortClick;
  final void Function()? longClick;
  final void Function(void Function())? setState;
  final void Function(Task)? setLastTask;

  @override
  Widget build(BuildContext context) {
    var onPressed = () {
      var a = task;
      if (shortClick != null) {
        shortClick!();
        return;
      }
      if (ghost) return;
      if (gens == null || man == null || profile == null || setState == null)
        return;
      setState!(() {
        a.toggle(gens!, man!, profile!);
        if (setLastTask != null) setLastTask!(a);
      });
    };

    var onLongPress = () {
      var a = task;
      if (longClick != null) {
        longClick!();
        return;
      }
      if (ghost) return;
      if (gens == null || man == null || profile == null || setState == null)
        return;

      setState!(() {
        if (!a.done) {
          a.taskFail(gens!, man!, profile!);
        } else if (a.fail) {
          a.deactivate(gens!, man!, profile!);
        } else {
          a.deactivate(gens!, man!, profile!);
          a.taskFail(gens!, man!, profile!);
        }
        if (setLastTask != null) setLastTask!(a);
      });
    };

    String date = ghost ? "Available " : '';
    var f = NumberFormat("00");

    var sDate = !ghost;
    if (ghost && task.date == null) {
      date = "";
    } else if (isTheSameDay(task.date!, DateTime.now())) {
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

class TaskGenerators {
  TaskGenerators({required this.tasks});

  Map<String, TaskGenerator> tasks;

  factory TaskGenerators.fromJSON(Map<String, dynamic> json) {
    Map<String, TaskGenerator> gens = {};

    json.keys.forEach((e) {
      try {
        TaskGenerator gen = TaskGenerator.fromJson(json[e]);
        if (gen.type.id == e) {
          gens[e] = gen;
        }
      } catch (e) {
        //TODO: Deal with the error in the future
      }
    });

    return TaskGenerators(tasks: gens);
  }

  Map<String, dynamic> toJson() {
    return this.tasks.map((key, value) => MapEntry(key, value.toJson()));
  }

  TaskGenerator? get(String id) {
    if (id == "") return null;
    if (!tasks.containsKey(id)) return null;
    return tasks[id];
  }

  Iterable<TaskGenerator> get fail {
    return tasks.keys
        .where((a) => tasks[a]!.type is TaskTypeFailTask)
        .map((a) => tasks[a]!);
  }

  void add(TaskGenerator a) {
    tasks.putIfAbsent(a.type.id, () => tasks[a.type.id] = a);
  }

  List<Task> generate(TaskManager manager, Profile profile) {
    List<Task> ghost = [];

    List<String> toRemove = [];

    print(this.tasks.values.length);

    this.tasks.values.forEach((TaskGenerator e) {
      manager.add(e.type.generate(e.base, manager.taskList));
      Task? task = e.type.generateGhostTask(e.base, manager.taskList);
      if (task != null) {
        ghost.add(task);
      }
      if (e.type.finished()) {
        toRemove.add(e.type.id);
      }
    });

    toRemove.forEach((e) => this.tasks.remove(e));

    return ghost;
  }

  Iterable<TaskGenerator> get lists {
    return tasks.values;
  }

  void remove(TaskGenerator e, TaskManager manager) {
    this.tasks.remove(e.type.id);
    manager.removedActiveGenerator(e.type.id);
  }
}

class TaskManager {
  TaskManager(this.tasks, this.oldTasks);

  Map<String, Task> tasks;
  Map<String, Task> oldTasks;

  Iterable<Task> get taskList {
    return this.tasks.values;
  }

  Task? getTaskByIdUUID(String id) {
    if (tasks.containsKey(id)) return tasks[id];
    if (oldTasks.containsKey(id)) return oldTasks[id];
    return null;
  }

  void add(Task? task) {
    if (task == null) return;
    print("here");
    print("id: ${task.id}");
    if (task.id == "") return;
    tasks[task.id] = task;
  }

  void removeTask(Task? task) {
    if (task == null) return;
    if (tasks.containsKey(task.id)) {
      tasks.remove(task.id);
    }
    if (oldTasks.containsKey(task.id)) {
      oldTasks.remove(task.id);
    }
  }

  Map<String, dynamic> toJSON() {
    return {
      "tasks": this.tasks.map((key, value) => MapEntry(key, value.toJSON())),
      "oldTasks":
          this.oldTasks.map((key, value) => MapEntry(key, value.toJSON())),
    };
  }

  Iterable<Task> get active {
    return this
        .tasks
        .keys
        .where((element) => !this.tasks[element]!.done)
        .map((e) => this.tasks[e]!);
  }

  void removedActiveGenerator(String id) {
    List<String> toRemove = [];
    this.active.forEach((element) {
      if (element.generatorId == id) toRemove.add(element.id);
    });

    toRemove.forEach((element) => this.tasks.remove(element));
  }

  //TODO load old tasks
  factory TaskManager.fromJSON(Map<String, dynamic> json) {
    Map<String, Task> map = {};

    json.keys.forEach((e) {
      try {
        Task task = Task.fromJson(json[e]);
        if (e == task.id) {
          map[e] = task;
        }
      } catch (e) {
        //TODO deal with the error
      }
    });

    return TaskManager(map, {});
  }
}
