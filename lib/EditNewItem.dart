import 'dart:math';

import 'package:app/DatePicker.dart';
import 'package:app/Task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EditNewItemRoute extends StatelessWidget {
  EditNewItemRoute({Key? key, required this.newTaskGenerator})
      : super(key: key);

  final GlobalKey<_EditNewItemState> _myEdit = GlobalKey();

  final ValueChanged<TaskGenerator> newTaskGenerator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Create new task")),
        body: Center(
          child: EditNewItem(key: _myEdit),
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
  const EditNewItem({Key? key}) : super(key: key);

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
  //Profile part
  double xpPerTask = 0;
  double xpPerTaskCombo = 0;
  double moneyPerTask = 0;
  double moneyPerTaskCombo = 0;
  double xpLost = 0;
  double moneyLost = 0;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TaskGenerator? submit() {
    if (!_formKey.currentState!.validate()) return null;

    _formKey.currentState!.save();

    Task t = Task(title: _name, id: new Random().nextInt(100000).floor());
    TaskType? taskType;
    if (_taskTypeValue == 1) {
      taskType = TaskTypeOnce(
          date: DateTime(_onceDate.year, _onceDate.month, _onceDate.day,
              _onceTime.hour, _onceTime.minute, 0, 0, 0),
          //TODO: Change id
          id: new Random().nextInt(100000).floor(),
          xpPerTaskCombo: this.xpPerTaskCombo,
          xpLost: this.xpLost,
          xpPerTask: this.xpPerTask,
          moneyLost: this.moneyLost,
          moneyPerTask: this.moneyPerTask,
          moneyPerTaskCombo: this.moneyPerTaskCombo);
    } else if (_taskTypeValue == 2) {
      taskType = TaskTypeRepeatEveryDay(
        xpPerTask: this.xpPerTask,
        xpPerTaskCombo: this.xpPerTaskCombo,
        moneyPerTask: this.moneyPerTask,
        moneyPerTaskCombo: this.moneyPerTaskCombo,
        xpLost: this.xpLost,
        moneyLost: this.moneyLost,
        date: DateTime(2020, 1, 1, _onceTime.hour, _onceTime.minute),
        //TODO: Change id
        id: new Random().nextInt(100000).floor(),
      );
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
        if (value == null || value.isEmpty) {
          return 'The title filed is required';
        }
      },
      onSaved: (String? value) {
        if (value != null) _name = value;
      },
    );
  }

  Widget _buildTypeSelector() {
    int index = 1;

    List<String> itemsText = ["Do until", "Repeat every day"];

    List<DropdownMenuItem<int>> items =
        itemsText.map<DropdownMenuItem<int>>((String title) {
      var a = index++;
      print(a);
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
        print("teste");
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

  Widget _buildPlayerActions() {
    return Container(
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 5, spreadRadius: 1)
        ]),
        child: Column(
          children: [
            //Title
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.grey, blurRadius: 10, offset: Offset(0, 3))
              ]),
              child: Padding(
                child: Text('Player effects'),
                padding: EdgeInsets.symmetric(vertical: 8)
                    .add(EdgeInsets.only(left: 10)),
              ),
            ),
            // The fields are about adding points per task done
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
                          validator: (String? v) {
                            if (v == null || v.isEmpty)
                              return 'This filed must have a value';
                            try {
                              double.parse(v);
                            } catch (_) {
                              return 'This filed must be a number';
                            }
                          },
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
                          decoration: InputDecoration(labelText: 'Xp combo'),
                          validator: (String? v) {
                            if (v == null || v.isEmpty)
                              return 'This filed must have a value';
                            try {
                              double.parse(v);
                            } catch (_) {
                              return 'This filed must be a number';
                            }
                          },
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
                          validator: (String? v) {
                            if (v == null || v.isEmpty)
                              return 'This filed must have a value';
                            try {
                              double.parse(v);
                            } catch (_) {
                              return 'This filed must be a number';
                            }
                          },
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
                          decoration: InputDecoration(labelText: 'Money combo'),
                          validator: (String? v) {
                            if (v == null || v.isEmpty)
                              return 'This filed must have a value';
                            try {
                              double.parse(v);
                            } catch (_) {
                              return 'This filed must be a number';
                            }
                          },
                          onSaved: (String? v) {
                            if (v == null || v.isEmpty) return;
                            moneyPerTaskCombo = double.parse(v);
                          },
                        )),
                      ],
                    ),
                    //Extra xp lost per task
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: 'Extra xp lost per task'),
                      validator: (String? v) {
                        if (v == null || v.isEmpty)
                          return 'This filed must have a value';
                        try {
                          double.parse(v);
                        } catch (_) {
                          return 'This filed must be a number';
                        }
                      },
                      onSaved: (String? v) {
                        if (v == null || v.isEmpty) return;
                        xpLost = double.parse(v);
                      },
                    ),
                    //Extra money lost per task
                    TextFormField(
                      decoration: InputDecoration(
                          labelText: 'Extra money lost when faield'),
                      validator: (String? v) {
                        if (v == null || v.isEmpty)
                          return 'This filed must have a value';
                        try {
                          double.parse(v);
                        } catch (_) {
                          return 'This filed must be a number';
                        }
                      },
                      onSaved: (String? v) {
                        if (v == null || v.isEmpty) return;
                        moneyLost = double.parse(v);
                      },
                    ),
                  ],
                ))
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
                    ],
                  ),
                ),
                _buildPlayerActions(),
              ],
            ))));
  }
}
