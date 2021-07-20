import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

//TODO: Improve a lot
class ProfileWidget extends StatelessWidget {
  const ProfileWidget({Key? key, required this.profile, required this.logOut})
      : super(key: key);

  final Profile profile;
  final void Function() logOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
        ),
        Row(
          children: [
            Expanded(child: Text(profile.name)),
            Text("Lv:" + profile.level.toString())
          ],
        ),
        Text('XP: ${profile.xp}'),
        LinearProgressIndicator(
          value: profile.xp / profile.getLevelXp(),
        ),
        ElevatedButton(onPressed: logOut, child: Text('Logout'))
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
    return 100 + this.level * 200;
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
      return;
    }
    this.level--;
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
