import 'package:app/EditNewItem.dart';
import 'package:app/Profile.dart';
import 'package:app/Start.dart';
import 'package:app/Task.dart';
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
  bool loaded = false;

  //Local Database
  Database? db;
  StoreRef? store;

  //User Data
  Profile? profile;
  bool isProfileCreated = false;
  //  Tasks:
  List<TaskGenerator> taskGenerators = [];
  List<Task> tasks = [];
  List<Task> ghostTasks = [];
  Tuple<int, Task>? lastTaskDone;

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

    //Load data from database
    //  Loading data for user
    if (await store!.record('profile').exists(db!)) {
      var tempProfile =
          Profile.fromJson(await store!.record('profile').get(db!));
      setState(() {
        profile = tempProfile;
        isProfileCreated = true;
      });
    } else {
      setState(() {
        profile = Profile(level: 0, money: 0, xp: 0, name: '');
      });
    }

    if (await store!.record('tasks').exists(db!)) {
      try {
        List<Task> tempTasks =
            (((await store!.record('tasks').get(db!)) as List<dynamic>)
                .map((e) => Task.fromJson(e))
                .toList());
        setState(() {
          tasks = tempTasks;
        });
      } catch (e) {
        print("Failed to process tasks: " + e.toString());
        //TODO: Deal with error waring
        await store!.record('tasks').delete(db!);
        //TODO: improve
        startDb();
        return;
      }
    } else {
      setState(() {
        tasks = [];
      });
    }

    if (await store!.record('tasksGenerators').exists(db!)) {
      try {
        List<TaskGenerator> tempTaskGenerators = (((await store!
                .record('tasksGenerators')
                .get(db!)) as List<dynamic>)
            .map((e) => TaskGenerator.fromJson(e))
            .toList());
        setState(() {
          taskGenerators = tempTaskGenerators;
        });
      } catch (e) {
        print("Failed to process tasks generators: " + e.toString());
        //TODO: Deal with error waring
        await store!.record('tasksGenerators').delete(db!);
        //TODO: improve
        startDb();
        return;
      }
    } else {
      setState(() {
        taskGenerators = [];
      });
    }

    setState(() {
      loaded = true;
      generateTasks();
      checkTasks();
    });
  }

  Future saveDb() async {
    //TODO: improve
    // probably add a tost
    if (store == null || db == null) return;
    await store!.record('profile').put(db!, profile!.toJson());
    await store!
        .record('tasks')
        .put(db!, tasks.map((e) => e.toJSON()).toList());
    await store!
        .record('tasksGenerators')
        .put(db!, taskGenerators.map((e) => e.toJson()).toList());
  }

  @override
  void initState() {
    super.initState();
    //Start db
    startDb();
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
  }

  //! Note: This function saves the db
  Future checkTasks() async {
    tz.Location location =
        tz.getLocation(await FlutterNativeTimezone.getLocalTimezone());
    int index = 0;
    for (var task in tasks) {
      index++;
      if (!task.done) {
        if (task.taskType is TaskTypeOnce &&
            generalNotificationDetails != null) {
          //Check the task
          //If the task is already past the time and was not recoverd by the user
          // then marked it as failed
          if (task.date!.isBefore(DateTime.now())) {
            if (!task.userRemovedFromFail) {
              task.done = true;
              task.fail = true;
              task.directToFail = true;
              //Call the task changed function to deal with the points
              taskChanged(index)(task);
            }
          } else if (task.date!
              .subtract(Duration(minutes: 15))
              .isBefore(DateTime.now())) {
            localNotification.show(
                task.id,
                "A task needs to be done",
                "The Task: " + task.title + " needs to be completed.",
                generalNotificationDetails!);
          } else {
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
    saveDb();
  }

  void _newItemPage(BuildContext context) {
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

  //! Note: this function calls a function that saves the db
  void generateTasks() {
    List<TaskGenerator> t = [];
    List<Task> ghostTasksNew = [];
    for (var a in taskGenerators) {
      var generated = a.type.generate(a.base, tasks);
      if (generated != null) tasks.add(generated);
      var generatedGhost = a.type.generateGhostTask(a.base, tasks);
      if (generatedGhost != null) ghostTasksNew.add(generatedGhost);

      if (!a.type.finished()) t.add(a);
    }
    setState(() {
      taskGenerators = t;
      ghostTasks = ghostTasksNew;
    });
    localNotification.cancelAll();
    checkTasks();
  }

  //! Note: When removing from fail only change to task.done to false
  //! Note: This function saves the db
  taskChanged(int index) {
    return (Task task) {
      // something -> Fail -> not done
      // The xp points and the money need to be restored
      // something is defined by the directToFail if its true
      //  then the task was failed without completing it first
      if (task.fail && !task.done) {
        task.userRemovedFromFail = true;
        task.fail = false;
        setState(() {
          //Restore the money and xp that is lost when a quest is failed
          this.profile!.addXp(task.xpLost);
          this.profile!.money += task.moneyLost;
        });
        //This needs to be done after the removal because this is needed by the process of removal
        task.directToFail = false;
        setState(() {
          tasks[index] = task;
          if (lastTaskDone != null && lastTaskDone!.k == index) {
            lastTaskDone = null;
          }
        });
        generateTasks();
        return;
      }

      setState(() {
        //Task faild
        if (task.done && task.fail) {
          //If the task is directToFail then you only remove the fail xp/money
          // If not the you remove the fail xp/money and the gain xp
          this.profile!.removeXP(task.xpLost);
          this.profile!.money -= task.moneyLost;
          if (!task.directToFail) {
            this.profile!.removeXP(task.xp);
            this.profile!.money -= task.money;
          }
          lastTaskDone = Tuple(k: index, t: task);
          task.taskAddedPoints = false;
        } else if (task.done) {
          localNotification.cancel(task.id);
          generateTasks();
          this.profile!.addXp(task.xp);
          this.profile!.money += task.money;
          lastTaskDone = Tuple(k: index, t: task);
          task.taskAddedPoints = true;
        }
        if (lastTaskDone != null && lastTaskDone!.k == index && !task.done) {
          lastTaskDone = null;
        }

        // done -> not done
        if (!task.done && task.taskAddedPoints && !task.fail) {
          task.taskAddedPoints = false;
          this.profile!.removeXP(task.xp);
          this.profile!.money -= task.money;
        }
        tasks[index] = task;
      });
      generateTasks();
    };
  }

  Widget _buildDoneTask() {
    //Get rigth taks
    int index = 0;

    //Create Widgets out of it
    List<Tuple<int, Task>> taskTuples = tasks
        .map((Task e) => Tuple(k: index++, t: e))
        .where((Tuple t) => t.t.done)
        .toList();
    taskTuples.sort((a, b) {
      if (a.t.date == null && b.t.date == null) return 0;
      if (a.t.date == null) return 1;
      if (b.t.date == null) return -1;
      return b.t.date!.compareTo(a.t.date!);
    });
    List<Widget> taskWidgets = taskTuples
        .map((t) => TaskWidget(task: t.t, taskChanged: taskChanged(t.k)))
        .toList();

    // Return content for the page
    return Column(children: [
      SizedBox(height: 40),
      Expanded(
          child: SingleChildScrollView(
        child: Column(
          children: taskWidgets,
        ),
      )),
      SizedBox(height: 0)
    ]);
  }

  Widget _buildToDoTask() {
    //Get rigth taks
    int index = 0;

    //Create Widgets out of it
    List<Tuple<int, Task>> taskTuples = tasks
        .map((Task e) => Tuple(k: index++, t: e))
        .where((Tuple t) => !t.t.done)
        .toList();
    taskTuples.sort((a, b) {
      if (a.t.date == null && b.t.date == null) return 0;
      if (a.t.date == null) return -1;
      if (b.t.date == null) return 1;
      return a.t.date!.compareTo(b.t.date!);
    });
    List<Widget> taskWidgets = taskTuples
        .map((t) => TaskWidget(task: t.t, taskChanged: taskChanged(t.k)))
        .toList();

    //Create Widgets out of it
    //TODO: improve
    //TODO: Add the rigth function with taskChanged to disable the task generator
    ghostTasks.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return -1;
      if (b.date == null) return 1;
      return a.date!.compareTo(b.date!);
    });
    List<Widget> taskGhost = ghostTasks
        .where((Task t) => !t.done)
        .map((t) => TaskWidget(
              ghost: true,
              task: t,
              taskChanged: (Task _) {},
            ))
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
          height: (92 * (taskGhost.length > 3 ? 3 : taskGhost.length)) + 35,
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
                task: lastTaskDone!.t,
                taskChanged: taskChanged(lastTaskDone!.k))
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
    //Return the create page
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
    //Return the main app
    return Scaffold(
      body: Center(
        child: _selectedIndex == 0
            ? _buildToDoTask()
            : _selectedIndex == 1
                ? _buildDoneTask()
                : ProfileWidget(
                    profile: this.profile!,
                    //TODO: Inprove this
                    logOut: () {
                      setState(() {
                        this.profile =
                            Profile(level: 0, xp: 0, money: 0, name: '');
                        this.store!.record('profile').delete(this.db!);
                        this.store!.record('taks').delete(this.db!);
                        this.store!.record('taskGenerators').delete(this.db!);
                        isProfileCreated = false;
                        tasks = [];
                        taskGenerators = [];
                        ghostTasks = [];
                        lastTaskDone = null;
                      });
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        //TODO: inprove this
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.access_time_filled_sharp),
              label: 'Old Tasks'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: (int value) {
          setState(() {
            _selectedIndex = value;
          });
        },
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
