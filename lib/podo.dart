class Profile {
  String name;
  int level;
  int xp;
  int money;

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
}
