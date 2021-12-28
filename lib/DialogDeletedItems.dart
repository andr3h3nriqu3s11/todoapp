import 'package:app/Task.dart';
import 'package:app/Utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void showItemsDialog(BuildContext context, List<Tuple<int, Task>> list,
    Function taskChanged, Function onClose) {
  // Only takes from this month
  list.sort((a, b) {
    if (a.t.date == null && b.t.date == null) return 0;
    if (a.t.date == null) return 1;
    if (b.t.date == null) return -1;
    return b.t.date!.compareTo(a.t.date!);
  });

  List<Widget> taskWidgets = list
      .map((t) => TaskWidget(task: t.t, taskChanged: taskChanged(t.k, context)))
      .toList();

  Widget okBtt = TextButton(
      onPressed: () {
        Navigator.of(context).pop();
        onClose();
      },
      child: Text("Yes"));

  AlertDialog dialog = AlertDialog(
    title: Text("Failed Notifications"),
    content: Column(children: [
      SizedBox(height: 40),
      Expanded(
          child: SingleChildScrollView(
        child: Column(
          children: [
            SingleChildScrollView(child: Column(children: taskWidgets))
          ],
        ),
      )),
      SizedBox(height: 0)
    ]),
    actions: [okBtt],
  );

  showDialog(
      context: context,
      builder: (b) {
        return dialog;
      }).then((_) => onClose());
}
