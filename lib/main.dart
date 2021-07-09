import 'package:app/EditNewItem.dart';
import 'package:app/Task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/browser.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' as tz;

import 'Utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeManager',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Life Manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterLocalNotificationsPlugin localNotification =
      FlutterLocalNotificationsPlugin();
  NotificationDetails? generalNotificationDetails;
  List<TaskGenerator> taskGenerators = [];
  List<Task> tasks = [];
  Tuple<int, Task>? lastTaskDone;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Android default settings takes the icon name if the icon does not exist
    //on the drawable folder an error will be thrown
    var androidInitilize = new AndroidInitializationSettings("ic_launcher");
    //Settings for ios
    var iosInitilize = new IOSInitializationSettings();
    var initializationSettings =
        InitializationSettings(android: androidInitilize, iOS: iosInitilize);
    localNotification.initialize(initializationSettings);
    localNotification.cancelAll();
    var androidDetail = new AndroidNotificationDetails('lifemanagerApp',
        'Lifemanager App', 'Lifemanager app notificaions, probably a task');
    var iosDetails = new IOSNotificationDetails();
    generalNotificationDetails =
        new NotificationDetails(android: androidDetail, iOS: iosDetails);
    checkTasks();
    initializeTimeZones();
  }

  Future checkTasks() async {
    Location location =
        tz.getLocation(await FlutterNativeTimezone.getLocalTimezone());
    for (var task in tasks) {
      if (!task.done) {
        if (task.taskType is TaskTypeOnce &&
            generalNotificationDetails != null) {
          var date = tz.TZDateTime.from(
              task.date!.subtract(Duration(minutes: 15)), location);
          localNotification.zonedSchedule(
              task.id,
              "A task needs to be done",
              "The task: " + task.title + " needs to be completed.",
              date,
              generalNotificationDetails!,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidAllowWhileIdle: true);
        }
      }
    }
  }

  void _newItemPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditNewItemRoute(
                  newTaskGenerator: (TaskGenerator task) {
                    setState(() {
                      taskGenerators.add(task);
                    });
                    Navigator.pop(context);
                    generateTasks();
                  },
                )));
  }

  void generateTasks() {
    List<TaskGenerator> t = [];
    for (var a in taskGenerators) {
      tasks.add(a.type.generate(a.base));
      if (!a.type.finished()) t.add(a);
    }
    setState(() {
      taskGenerators = t;
    });
  }

  Widget _buildDoneTask() {
    //Get rigth taks
    int index = 0;

    var taskChanged = (int index) {
      return (Task task) {
        setState(() {
          tasks[index] = task;
          if (task.done) {
            generateTasks();
            lastTaskDone = Tuple(k: index, t: task);
          } else if (lastTaskDone != null && lastTaskDone!.k == index) {
            lastTaskDone = null;
          }
        });
      };
    };

    //Create Widgets out of it
    List<Widget> taskWidgets = tasks
        .map((Task e) => Tuple(k: index, t: e))
        .where((Tuple t) => !t.t.done)
        .map((t) => TaskWidget(task: t.t, taskChanged: taskChanged(t.k)))
        .toList();

    // Return content for the page
    return Column(children: [
      SizedBox(height: 40),
      Expanded(
          child: Column(
        children: taskWidgets,
      )),
      SizedBox(height: 0)
    ]);
  }

  Widget _buildToDoTask() {
    //Get rigth taks
    int index = 0;

    var taskChanged = (int index) {
      return (Task task) {
        setState(() {
          tasks[index] = task;
          if (task.done) {
            generateTasks();
            lastTaskDone = Tuple(k: index, t: task);
          } else if (lastTaskDone != null && lastTaskDone!.k == index) {
            lastTaskDone = null;
          }
        });
      };
    };

    //Create Widgets out of it
    List<Widget> taskWidgets = tasks
        .map((Task e) => Tuple(k: index, t: e))
        .where((Tuple t) => !t.t.done)
        .map((t) => TaskWidget(task: t.t, taskChanged: taskChanged(t.k)))
        .toList();

    // Return content for the page
    return Column(children: [
      SizedBox(height: 40),
      Expanded(
          child: Column(
        children: taskWidgets,
      )),
      if (lastTaskDone == null)
        SizedBox(height: 0)
      else
        Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Container(
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 10,
                        offset: Offset(0, 3))
                  ]),
                  child: Padding(
                    child: Text('Last task done'),
                    padding: EdgeInsets.symmetric(vertical: 8)
                        .add(EdgeInsets.only(left: 10)),
                  ),
                )),
              ],
            ),
            TaskWidget(
                task: lastTaskDone!.t,
                taskChanged: taskChanged(lastTaskDone!.k))
          ],
        )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _selectedIndex == 1 ? _buildDoneTask() : _buildToDoTask(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.access_time_filled_sharp),
              label: 'Old Tasks'),
        ],
        currentIndex: _selectedIndex,
        onTap: (int value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newItemPage,
        tooltip: 'Add new task',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
    );
  }
}
