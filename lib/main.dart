import 'dart:math';

import 'package:app/TaskTypes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:uuid/uuid.dart';

import 'package:app/BoxHolder.dart';
import 'package:app/DialogDeletedItems.dart';
import 'package:app/EditNewItem.dart';
import 'package:app/Profile.dart';
import 'package:app/Start.dart';
import 'package:app/Task.dart';
import 'Utils.dart';

void main() async {
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
  //Notification stuff
  FlutterLocalNotificationsPlugin localNotification =
      FlutterLocalNotificationsPlugin();
  NotificationDetails? generalNotificationDetails;

  // Things to be used by the page
  int _selectedIndex = 0;

  //Local Database
  bool loaded = false;
  Database? db;
  StoreRef? store;

  //User Data
  Profile? profile;
  bool isProfileCreated = false;

  //Tasks:
  TaskGenerators? generators;
  TaskManager? manager;
  List<Task> ghostTasks = [];
  Task? lastTaskDone;
  Tuple<TaskGenerator, Offset>? dragTaskGenerator;

  List<Task> deletedTasksNotification = [];
  bool deletedTasksShown = false;

  // Secound Page limit
  int limit = 0;
  ScrollController? _scrollController;

  //Set up Load Database
  Future startDb() async {
    DatabaseFactory dbFactory = databaseFactoryIo;
    //Use the dbFactory to open the database with a path
    // Get app path so we can use store files
    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    var dbPath = join(dir.path, "database.db");
    this.db = await dbFactory.openDatabase(dbPath);
    this.store = StoreRef.main();

    TaskManager? man;
    TaskGenerators? gens;
    Profile profile = Profile(level: 0, money: 0, xp: 0, name: '');
    bool isProfileCreated = false;

    //Load data from database
    //  Loading data for user
    if (await store!.record('profile').exists(db!)) {
      try {
        profile = Profile.fromJson(await store!.record('profile').get(db!));
        isProfileCreated = true;
      } catch (e) {
        //TODO deal with the error
      }
    }

    if (await store!.record("tasks").exists(db!))
      try {
        man = TaskManager.fromJSON(
            await store!.record('tasks').get(db!) as Map<String, dynamic>);
      } catch (e) {
        await store!.record('tasks').delete(db!);
      }

    if (await store!.record('tasksGenerators').exists(db!))
      try {
        gens = TaskGenerators.fromJSON(
            (await store!.record('tasksGenerators').get(db!)));
      } catch (e) {
        await store!.record('tasksGenerators').delete(db!);
      }

    setState(() {
      loaded = true;
      this.manager = man ?? TaskManager({}, {});
      this.generators = gens ?? TaskGenerators(tasks: {});
      this.profile = profile;
      this.isProfileCreated = isProfileCreated;
      generateTasks(null);
    });
  }

  Future saveDb() async {
    //TODO: improve probably add a tost
    if (store == null || db == null) return;
    await store!.record('profile').put(db!, profile!.toJson());
    await store!.record('tasks').put(db!, manager!.toJSON());
    await store!.record('tasksGenerators').put(db!, generators!.toJson());
  }

  @override
  void initState() {
    super.initState();

    //This makes sure that the when the scroll on the second page
    //reaches the end it loads more data
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _scrollController = ScrollController();
      _scrollController!.addListener(() {
        if (_scrollController!.position.atEdge &&
            _scrollController!.position.pixels != 0)
          setState(() {
            limit += 1;
          });
      });
    });

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
    initializeTimeZones();

    //This starts db and loads all the data from it
    startDb();
  }

  //! Note: This function saves the db
  Future checkTasks(BuildContext? context) async {
    tz.Location location =
        tz.getLocation(await FlutterNativeTimezone.getLocalTimezone());

    // Checks all the tasks to if they need to be marked as failed
    manager!.active.forEach((task) {
      //Check the task
      //If the task is already past the time and was not recoverd by the user
      // then marked it as failed
      if (task.date!.isBefore(DateTime.now())) {
        // If the user did not change this to the fail position then
        // change to a failed notification
        if (!task.userRemovedFromFail) {
          //Call the fail function to deal with the points
          task.taskFail(generators!, manager!, profile!);
          setState(() {
            deletedTasksNotification.add(task);
          });
        }
        return;
      }

      // The next part deals with notifications so if they are not initialized correctly then
      // don't run the next part
      if (generalNotificationDetails != null) return;

      if (task.date!.subtract(Duration(minutes: 15)).isBefore(DateTime.now())) {
        // Create a notification
        if (task.notificationId != null)
          localNotification.cancel(task.notificationId!);

        task.notificationId = Uuid().v1().hashCode;

        localNotification.show(
            task.notificationId!,
            "A task needs to be done within 15 minutes",
            "The Task: " + task.title + " needs to be completed.",
            generalNotificationDetails!);
      } else {
        // Create a notification
        if (task.notificationId != null)
          localNotification.cancel(task.notificationId!);

        task.notificationId = Uuid().v1().hashCode;

        var date = tz.TZDateTime.from(
            task.date!.subtract(Duration(minutes: 15)), location);

        //TODO: add time to the notification
        localNotification.zonedSchedule(
            task.notificationId!,
            "A task needs to be done",
            "The task: " + task.title + " needs to be completed.",
            date,
            generalNotificationDetails!,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidAllowWhileIdle: true);
      }
    });

    /*DateTime nowTime = new DateTime.now();

    List<Task> newOldTasks = tasks
        .where((e) =>
            e.date!.month <= nowTime.month && e.date!.year <= nowTime.year)
        .toList();

    tasks = tasks
        .where((element) =>
            element.date!.month >= nowTime.month &&
            element.date!.year >= nowTime.year)
        .toList();

    oldTasks = [...oldTasks, ...newOldTasks];*/

    saveDb();
  }

  void _newItemPage(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditNewItemRoute(
                  failTasksGenerators: this.generators!.fail.toList(),
                  newTaskGenerator: (TaskGenerator task) async {
                    generators!.add(task);
                    await this.saveDb();
                    Navigator.pop(context);
                    generateTasks(context);
                  },
                )));
  }

  //! Note: this function calls the checkTasks function
  void generateTasks(BuildContext? context) {
    setState(() {
      ghostTasks = generators!.generate(manager!, profile!);
    });
    localNotification.cancelAll();
    checkTasks(context);
  }

  void _changePage(int index) {
    if (index == 1) {
      setState(() {
        limit = 1;
      });
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildDoneTask(BuildContext context) {
    //Create Widgets out of it
    List<Task> tasks = manager!.taskList.where((e) => e.done).toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

    DateTime t = DateTime.now();

    List<Widget> taskWidgets = tasks
        //TODO improve this
        //Only take from this month
        .where((e) => e.date!.month >= t.month)
        //Transform to widgets
        .map((task) => TaskWidget(
              task: task,
              profile: profile,
              man: manager,
              gens: generators,
              setState: setState,
              setLastTask: (Task a) {
                setState(() {
                  lastTaskDone = !a.done ? null : a;
                });
                generateTasks(context);
              },
            ))
        .toList();

    // Return content for the page
    return Column(children: [
      SizedBox(height: 40),
      Expanded(
          child: SingleChildScrollView(
        child: Column(
          children: [
            BoxHolder(
              name: 'This month',
              children: [
                SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(children: taskWidgets))
              ],
              toggleable: true,
              defaultActive: true,
            )
          ],
        ),
      )),
      SizedBox(height: 0)
    ]);
  }

  Widget _buildToDoTask(BuildContext context) {
    //Create Widgets out of it
    List<Task> tasks = manager!.active.toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return -1;
        if (b.date == null) return 1;
        return a.date!.compareTo(b.date!);
      });

    List<Widget> taskWidgets = tasks
        .map((t) => TaskWidget(
              task: t,
              man: manager,
              gens: generators,
              profile: profile,
              setState: setState,
              setLastTask: (a) {
                setState(() {
                  lastTaskDone = !a.done ? null : a;
                });
                generateTasks(context);
              },
            ))
        .toList();

    //Create Widgets out of it
    //! Note: not needed to disable it here since it can be disable on the profile page
    ghostTasks.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return -1;
      if (b.date == null) return 1;
      return a.date!.compareTo(b.date!);
    });

    List<Widget> taskGhost = ghostTasks
        .where((var t) => !t.done)
        .map((t) => GestureDetector(
            onHorizontalDragStart: (DragStartDetails e) {
              //TODO
              //dragTaskGenerator = Tuple(k: t, t: e.globalPosition);
            },
            onHorizontalDragUpdate: (DragUpdateDetails e) {
              //TODO
              /*if (dragTaskGenerator != null &&
                  dragTaskGenerator!.k.base.generatorId == t.k.generatorId) {
                //TODO drag animation
              }*/
            },
            onHorizontalDragEnd: (DragEndDetails e) {
              //TODO
              /*if (dragTaskGenerator != null &&
                  dragTaskGenerator!.k.base.generatorId == t.k.generatorId) {
                //TODO drag action
              }*/
            },
            child: TaskWidget(
              ghost: true,
              task: t,
            )))
        .toList();

    // Return content for the page
    return Column(children: [
      SizedBox(height: 40),
      Expanded(
        child: SingleChildScrollView(
          child: Column(children: taskWidgets),
        ),
      ),
      if (taskGhost.length == 0)
        SizedBox(
          height: 0,
        )
      else
        SizedBox(
          height: (92 * min(taskGhost.length, 2)) + 35,
          child: Column(
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
                      child: Text('Next Tasks'),
                      padding: EdgeInsets.symmetric(vertical: 8)
                          .add(EdgeInsets.only(left: 10)),
                    ),
                  )),
                ],
              ),
              Expanded(
                  child: SingleChildScrollView(
                      child: Column(
                children: taskGhost,
              )))
            ],
          ),
        ),

      //Last task Done
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
              task: lastTaskDone!,
              profile: profile,
              man: manager,
              gens: generators,
              setState: setState,
              setLastTask: (Task a) {
                setState(() {
                  lastTaskDone = !a.done ? null : a;
                });
                generateTasks(context);
              },
            )
          ],
        )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Inprove loading page
    //Loading page
    if (!loaded) {
      return Container(
        color: Colors.blue,
      );
    }

    //Return the create user profile page
    if (!isProfileCreated) {
      return CreateAccount(
          profile: this.profile ?? Profile(level: 0, xp: 0, money: 0, name: ''),
          done: (Profile p) {
            setState(() {
              this.profile = p;
              isProfileCreated = true;
              this.store!.record("profile").put(this.db!, p.toJson());
            });
          });
    }

    if (deletedTasksNotification.length > 0 && deletedTasksShown) {
      setState(() {
        deletedTasksShown = true;
      });
      Future.delayed(
          Duration.zero,
          () => showItemsDialog(context, deletedTasksNotification, manager!,
                  generators!, profile!, () {
                setState(() {
                  deletedTasksShown = false;
                  deletedTasksNotification = [];
                });
              }));
    }

    //Return the main app
    return Scaffold(
      body: Center(
        child: _selectedIndex == 0
            ? _buildToDoTask(context)
            : _selectedIndex == 1
                ? _buildDoneTask(context)
                : ProfileWidget(
                    profile: this.profile!,
                    removeTaskGenerator: (TaskGenerator e) {
                      setState(() {
                        generators!.remove(e, manager!);
                      });
                      this.saveDb();
                    },
                    taskGenerators: generators!.lists.toList(),
                    //TODO: Improve this
                    logOut: () {
                      setState(() {
                        this.profile =
                            Profile(level: 0, xp: 0, money: 0, name: '');
                        this.store!.record('profile').delete(this.db!);
                        this.store!.record('taks').delete(this.db!);
                        this.store!.record('taskGenerators').delete(this.db!);
                        isProfileCreated = false;
                        manager = TaskManager({}, {});
                        generators = TaskGenerators(tasks: {});
                        ghostTasks = [];
                        lastTaskDone = null;
                      });
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        //TODO: improve this
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.access_time_filled_sharp),
              label: 'Old Tasks'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _changePage,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newItemPage(context),
        tooltip: 'Add new task',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
    );
  }
}
