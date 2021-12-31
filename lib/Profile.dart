import 'dart:math';

import 'package:app/Task.dart';
import 'package:app/Utils.dart';
import 'package:flutter/material.dart';

//TODO: Improve a lot
class ProfileWidget extends StatelessWidget {
  const ProfileWidget(
      {Key? key,
      required this.profile,
      required this.logOut,
      required this.taskGenerators,
      required this.removeTaskGenerator})
      : super(key: key);

  final Profile profile;
  final List<TaskGenerator> taskGenerators;

  final void Function() logOut;
  final void Function(TaskGenerator e) removeTaskGenerator;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
        ),
        Row(
          children: [
            Expanded(
                child: Text(
              profile.name,
              style: TextStyle(fontSize: 30),
            )),
            Text("Lv:" + profile.level.toString())
          ],
        ),
        Text('XP: ${profile.xp}'),
        LinearProgressIndicator(
          value: profile.xp / profile.getLevelXp(),
          color: profile.level > 0 ? null : Colors.red,
        ),
        Text('Money: ${profile.money}'),
        ElevatedButton(onPressed: logOut, child: Text('Logout')),

        //Tasks Generator
        //TODO change this
        if (taskGenerators.length > 0) Text('Task Generators'),
        if (taskGenerators.length > 0)
          SizedBox(
            height: min(5, this.taskGenerators.length) * 92,
            child: SingleChildScrollView(
              child: Column(
                children: this.taskGenerators.map((e) {
                  return TaskWidget(
                    task: e.base,
                    shortClick: () {
                      showAlertDialog(
                          context,
                          'Are you sure you want to remove this task!',
                          'Remove task', () {
                        this.removeTaskGenerator(e);
                      }, () {});
                    },
                    ghost: true,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class Profile {
  String name;
  int level;
  double xp;
  double money;

  Profile(
      {required this.name,
      required this.level,
      required this.xp,
      required this.money});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json["name"],
      level: json["level"],
      xp: json["xp"],
      money: json["money"],
    );
  }

  int getLevelXp() {
    //TODO: Analize because level starts at 0 and maybe it should start at 1
    return 100 + this.level.abs() * 200;
  }

  completeTask(Task t) {
    addXp(t.xp);
    money += t.money;
  }

  removeWinnings(Task t) {
    removeXP(t.xp);
    money -= t.money;
  }

  taskFail(Task t) {
    removeXP(t.xp + t.xpLost);
    money -= (t.money + t.moneyLost);
  }

  removeDamages(Task t) {
    addXp(t.xp + t.xpLost);
    money += (t.money + t.moneyLost);
  }

  addXp(double xp) {
    if (this.xp + xp == getLevelXp()) {
      this.xp = 0;
      this.level++;
    } else if (this.xp + xp > getLevelXp()) {
      this.level++;
      this.addXp(xp - (getLevelXp() - this.xp));
    } else {
      this.xp += xp;
    }
  }

  removeXP(double xp) {
    if (this.xp - xp >= 0) {
      this.xp = this.xp - xp;
    } else {
      this.level--;
      xp = xp - this.xp;
      this.xp = this.getLevelXp().toDouble();
      removeXP(xp);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "name": this.name,
      "level": this.level,
      "xp": this.xp,
      "money": this.money
    };
  }
}
