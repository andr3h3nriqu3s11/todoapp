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
  String _name = "";
  int _taskTypeValue = 0;
  DateTime _onceDate = DateTime.now();
  TimeOfDay _onceTime = TimeOfDay.now();
  IconData? icon;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TaskGenerator? submit() {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    _formKey.currentState!.save();

    Task t = Task(title: _name, id: new Random().nextInt(100000).floor());
    TaskType? taskType;
    if (_taskTypeValue == 1) {
      //TODO: Change id
      taskType = TaskTypeOnce(
          date: DateTime(_onceDate.year, _onceDate.month, _onceDate.day,
              _onceTime.hour, _onceTime.minute, 0, 0, 0),
          id: new Random().nextInt(100000).floor());
    } else {
      return null;
    }

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

    List<String> itemsText = ["Do until"];

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

  Widget _buildDateSelector() {
    return DatePicker(
      labelText: 'Time of the task',
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

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _iconSelector(),
                _buildTitle(),
                _buildTypeSelector(),
                if (_taskTypeValue == 1) _buildDateSelector(),
              ],
            )));
  }
}
