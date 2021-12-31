import 'package:app/Profile.dart';
import 'package:app/Task.dart';
import 'package:flutter/material.dart';

void showItemsDialog(BuildContext context, List<Task> list, TaskManager man,
    TaskGenerators gens, Profile profile, Function onClose) {
  // Only takes from this month
  list.sort((a, b) {
    if (a.date == null && b.date == null) return 0;
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    return b.date!.compareTo(a.date!);
  });

  List<Widget> taskWidgets = list
      .map((t) => TaskWidget(
            task: t,
            man: man,
            gens: gens,
            profile: profile,
          ))
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
