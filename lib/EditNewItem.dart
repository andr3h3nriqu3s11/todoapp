import 'package:app/DatePicker.dart';
import 'package:app/Task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EditNewItemRoute extends StatelessWidget {
  EditNewItemRoute({Key? key}) : super(key: key);

  final GlobalKey<_EditNewItemState> _myEdit = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Create new task")),
        body: Center(
          child: EditNewItem(key: _myEdit),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _myEdit.currentState!.submit();
          },
          child: Icon(Icons.add),
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
  DateTime? _onceDate;
  TimeOfDay? _onceTime;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TaskGenerator? submit() {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    _formKey.currentState!.save();

    print('\n\nTeste\n\n');
    print('Title: $_name\n');
    Task t = Task(title: _name);
    TaskType? taskType;
    if (_taskTypeValue == 0) {
      if (_onceTime == null || _onceTime == null) return null;
      taskType = TaskTypeOnce(date: _onceDate!, time: _onceTime!);
    } else {
      return null;
    }

    TaskGenerator g = TaskGenerator(type: taskType, base: t);
    return g;
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

    List<String> itemsText = ["Once"];

    List<DropdownMenuItem<int>> items =
        itemsText.map<DropdownMenuItem<int>>((String title) {
      return DropdownMenuItem<int>(
        child: Text(title),
        value: index++,
      );
    }).toList();

    return DropdownButtonFormField(
      items: items,
      onChanged: (int? value) {
        if (value == null) return;
        _taskTypeValue = value;
      },
      decoration: InputDecoration(labelText: 'Type'),
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
      selectedDate: _onceDate ?? DateTime.now(),
      selectedTime: _onceTime ?? TimeOfDay.now(),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTitle(),
                _buildTypeSelector(),
                _buildDateSelector(),
              ],
            )));
  }
}
