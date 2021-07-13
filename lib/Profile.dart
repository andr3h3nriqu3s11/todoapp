import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({Key? key, required this.profile}) : super(key: key);

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(profile.name)),
            Text("Lv:" + profile.level.toString())
          ],
        ),
        Text('XP:'),
        LinearProgressIndicator(
          value: profile.xp / profile.getLevelXp(),
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

  getLevelXp() {
    return 100 + (this.level - 1) * 200;
  }

  addXp(double xp) {
    if (this.xp + xp == getLevelXp()) {
      this.xp = 0;
      this.level = this.level++;
    } else if (this.xp + xp > getLevelXp()) {
      this.level = this.level++;
      this.addXp(xp - (getLevelXp() - this.xp));
    } else {
      this.xp += xp;
    }
  }
}
