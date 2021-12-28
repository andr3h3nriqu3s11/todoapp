import 'package:flutter/material.dart';

class Tuple<K, T> {
  Tuple({required this.k, required this.t});
  K k;
  T t;
}

void showAlertDialog(BuildContext conx, String text, String title,
    Function onYesPress, Function onNoPress) {
  Widget okBtt = TextButton(
      onPressed: () {
        Navigator.of(conx).pop();
        onYesPress();
      },
      child: Text("Yes"));
  Widget noBtt = TextButton(
      onPressed: () {
        Navigator.of(conx).pop();
        onNoPress();
      },
      child: Text("No"));
  AlertDialog dialog = AlertDialog(
    title: Text(title),
    content: Text(text),
    actions: [okBtt, noBtt],
  );
  showDialog(
      context: conx,
      builder: (b) {
        return dialog;
      });
}
