import 'dart:math';

import 'package:app/TaskTypes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/BoxHolder.dart';
import 'package:app/DatePicker.dart';
import 'package:app/Task.dart';
import 'package:uuid/uuid.dart';

class EditNewItemRoute extends StatelessWidget {
  EditNewItemRoute(
      {Key? key,
      required this.newTaskGenerator,
      required this.failTasksGenerators})
      : super(key: key);

  final GlobalKey<_EditNewItemState> _myEdit = GlobalKey();

  final ValueChanged<TaskGenerator> newTaskGenerator;
  final List<TaskGenerator> failTasksGenerators;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Create new task")),
        body: Padding(
          child: EditNewItem(
            key: _myEdit,
            failTaskGenerators: this.failTasksGenerators,
          ),
          padding: EdgeInsets.only(top: 5),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            TaskGenerator? gen = _myEdit.currentState!.submit();
            if (gen == null) return;
            newTaskGenerator(gen);
          },
          child: Icon(Icons.add),
          tooltip: 'Finish',
        ));
  }
}

class EditNewItem extends StatefulWidget {
  const EditNewItem({Key? key, required this.failTaskGenerators})
      : super(key: key);

  final List<TaskGenerator> failTaskGenerators;

  @override
  State<StatefulWidget> createState() => _EditNewItemState();
}

class _EditNewItemState extends State<EditNewItem> {
  //Main data
  String _name = "";
  int _taskTypeValue = 0;
  DateTime _onceDate = DateTime.now();
  TimeOfDay _onceTime = TimeOfDay.now();
  IconData? icon;

  //Fail task
  int daysToComplete = 0;

  //Profile part
  double xpPerTask = 0;
  double xpPerTaskCombo = 0;
  double moneyPerTask = 0;
  double moneyPerTaskCombo = 0;
  double xpLost = 0;
  double moneyLost = 0;

  //Tasks
  List<TaskGenerator> failTasksIds = [];
  TaskGenerator? selectedTask;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TaskGenerator? submit() {
    if (!_formKey.currentState!.validate()) return null;

    _formKey.currentState!.save();

    Task t = Task.emptyTask();
    t.title = _name;
    t.failTasks = this.failTasksIds.map((a) => a.type.id).toList();
    TaskType? taskType;
    if (_taskTypeValue == 1) {
      taskType = TaskTypeOnce(
          date: DateTime(_onceDate.year, _onceDate.month, _onceDate.day,
              _onceTime.hour, _onceTime.minute, 0, 0, 0),
          id: Uuid().v1(),
          xpPerTaskCombo: this.xpPerTaskCombo,
          xpLost: this.xpLost,
          xpPerTask: this.xpPerTask,
          moneyLost: this.moneyLost,
          moneyPerTask: this.moneyPerTask,
          moneyPerTaskCombo: this.moneyPerTaskCombo);
      t.generatorType = TaskTypeEnum.once;
    } else if (_taskTypeValue == 2) {
      taskType = TaskTypeRepeatEveryDay(
        xpPerTask: this.xpPerTask,
        xpPerTaskCombo: this.xpPerTaskCombo,
        moneyPerTask: this.moneyPerTask,
        moneyPerTaskCombo: this.moneyPerTaskCombo,
        xpLost: this.xpLost,
        moneyLost: this.moneyLost,
        date: DateTime(2020, 1, 1, _onceTime.hour, _onceTime.minute),
        id: Uuid().v1(),
      );
      t.generatorType = TaskTypeEnum.repeat;
    } else if (_taskTypeValue == 3) {
      // Fail Task Case do this if the test fails
      taskType = TaskTypeFailTask(
        daysToComplete: this.daysToComplete,
        xpLost: this.xpLost,
        xpPerTaskCombo: this.xpPerTaskCombo,
        xpPerTask: this.xpPerTask,
        moneyLost: this.moneyLost,
        moneyPerTask: this.moneyPerTask,
        moneyPerTaskCombo: this.moneyPerTaskCombo,
        id: Uuid().v1(),
      );
      t.generatorType = TaskTypeEnum.fail;
    } else
      return null;

    TaskGenerator g = TaskGenerator(type: taskType, base: t);
    return g;
  }

  Widget _iconSelector() {
    return TaskWidgetIcon(
        onPressed: () {}, icon: icon, background: Colors.grey.shade400);
  }

  Widget _buildTitle() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Title'),
      validator: (String? value) {
        if (value == null || value.isEmpty)
          return 'The title filed is required';
      },
      onSaved: (String? value) {
        if (value != null) _name = value;
      },
    );
  }

  Widget _buildTypeSelector() {
    int index = 1;

    List<String> itemsText = ["Do until", "Repeat every day", 'Fail Task'];

    List<DropdownMenuItem<int>> items =
        itemsText.map<DropdownMenuItem<int>>((String title) {
      var a = index++;
      return DropdownMenuItem<int>(child: Text(title), value: a);
    }).toList();

    return DropdownButtonFormField(
      items: items,
      decoration: InputDecoration(labelText: 'Type'),
      onChanged: (int? value) {
        if (value == null) return;
        setState(() {
          _taskTypeValue = value;
        });
      },
      validator: (int? value) {
        if (value == null || value < 1 || value > 1 + itemsText.length) {
          return 'Please select a valid value for the field';
        }
      },
    );
  }

  Widget _buildDateSelector({bool timeonly: false}) {
    return DatePicker(
      labelText: 'Time of the task',
      timeOnly: timeonly,
      selectedDate: _onceDate,
      selectedTime: _onceTime,
      selectDate: (DateTime? time) {
        if (time != null)
          setState(() {
            _onceDate = time;
          });
      },
      selectTime: (TimeOfDay? time) {
        if (time != null)
          setState(() {
            _onceTime = time;
          });
      },
    );
  }

  Widget _buildDayToComplete() {
    return TextFormField(
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: 'Days to complete'),
      validator: (String? value) {
        if (value == null || value.isEmpty) return 'This is a required value';
        try {
          int.parse(value);
        } catch (e) {
          return 'This must have number';
        }
      },
      onSaved: (String? value) {
        if (value != null) daysToComplete = int.parse(value);
      },
    );
  }

  // Points gained or losed when the player completes or fails the task
  Widget _buildPlayerActions() {
    var validator = (String? v) {
      if (v == null || v.isEmpty) return 'This filed must have a value';
      try {
        double.parse(v);
      } catch (_) {
        return 'This filed must be a number';
      }
    };

    return Container(
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 5, spreadRadius: 1)
        ]),
        child: Column(
          children: [
            BoxHolder(
              name: 'Player Effects',
              toggleable: true,
              defaultActive: true,
              children: [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        // XP
                        Row(
                          children: [
                            //Xp per task
                            Expanded(
                                child: TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Xp once done'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: validator,
                              onSaved: (String? v) {
                                if (v == null || v.isEmpty) return;
                                xpPerTask = double.parse(v);
                              },
                            )),
                            SizedBox(
                              width: 5,
                            ),
                            //Xp combo multiplier
                            Expanded(
                                child: TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Xp combo'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: validator,
                              onSaved: (String? v) {
                                if (v == null || v.isEmpty) return;
                                xpPerTaskCombo = double.parse(v);
                              },
                            )),
                          ],
                        ),
                        // Money
                        Row(
                          children: [
                            //Money per task
                            Expanded(
                                child: TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Money once done'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: validator,
                              onSaved: (String? v) {
                                if (v == null || v.isEmpty) return;
                                moneyPerTask = double.parse(v);
                              },
                            )),
                            SizedBox(
                              width: 5,
                            ),
                            //Money combo multiplier
                            Expanded(
                                child: TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Money combo'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: validator,
                              onSaved: (String? v) {
                                if (v == null || v.isEmpty) return;
                                moneyPerTaskCombo = double.parse(v);
                              },
                            )),
                          ],
                        ),
                        //Extra xp lost per task
                        TextFormField(
                          decoration: InputDecoration(
                              labelText: 'Extra xp lost per task'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: validator,
                          onSaved: (String? v) {
                            if (v == null || v.isEmpty) return;
                            xpLost = double.parse(v);
                          },
                        ),
                        //Extra money lost per task
                        TextFormField(
                          decoration: InputDecoration(
                              labelText: 'Extra money lost when faield'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: validator,
                          onSaved: (String? v) {
                            if (v == null || v.isEmpty) return;
                            moneyLost = double.parse(v);
                          },
                        ),
                      ],
                    ))
              ],
            ),
          ],
        ));
  }

  //Task Section
  Widget _buildTaskFailList() {
    //Create the list for the dropdown
    List<DropdownMenuItem<TaskGenerator>> failTaskList = this
        .widget
        .failTaskGenerators
        .where((element) => this.failTasksIds.indexOf(element) == -1)
        .map((e) {
      return DropdownMenuItem(
        value: e,
        child: Text(e.base.title),
      );
    }).toList();

    if (failTaskList.length == 0 && this.failTasksIds.length == 0)
      return Padding(
        padding: EdgeInsets.all(10),
        child: Text("No Fail Task"),
      );

    return Row(
      children: [
        SizedBox(
          width: 0.0,
        ),
        Expanded(
            child: Column(
          children: [
            //1st line with the button to add and the text
            Row(
              children: [
                //Title
                Expanded(
                    child: DropdownButton(
                        value: this.selectedTask,
                        items: failTaskList,
                        onChanged: (TaskGenerator? e) {
                          setState(() {
                            this.selectedTask = e;
                          });
                        })),
                //Add btt
                IconButton(
                  onPressed: () {
                    if (this.selectedTask == null) return;
                    setState(() {
                      this.failTasksIds.add(this.selectedTask!);
                      this.selectedTask = null;
                    });
                  },
                  icon: Icon(Icons.add),
                )
              ],
            ),
            //List
            SizedBox(
                height: min(failTasksIds.length, 4) * 40 + 20,
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: SingleChildScrollView(
                        child: Column(
                      children: this.failTasksIds.map((e) {
                        return SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                // Title
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                      Text(
                                        e.base.title,
                                      )
                                    ])),
                                // Remove Button
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        this.failTasksIds = this
                                            .failTasksIds
                                            .where((element) => element != e)
                                            .toList();
                                      });
                                    },
                                    icon: Icon(Icons.minimize_outlined)),
                              ],
                            ));
                      }).toList(),
                    )))),
          ],
        )),
      ],
    );
  }

  Widget _buildTaskActions() {
    return Container(
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 5, spreadRadius: 1)
        ]),
        child: Column(
          children: [
            BoxHolder(
                name: "On Task Fail",
                toggleable: true,
                defaultActive: true,
                children: [_buildTaskFailList()]),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 0, horizontal: 2),
        child: Form(
            key: _formKey,
            child: SingleChildScrollView(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //Padded Section
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: Column(
                    children: [
                      _iconSelector(),
                      _buildTitle(),
                      _buildTypeSelector(),
                      if (_taskTypeValue == 1) _buildDateSelector(),
                      if (_taskTypeValue == 2)
                        _buildDateSelector(timeonly: true),
                      if (_taskTypeValue == 3) _buildDayToComplete(),
                    ],
                  ),
                ),
                _buildPlayerActions(),
                _buildTaskActions(),
              ],
            ))));
  }
}
