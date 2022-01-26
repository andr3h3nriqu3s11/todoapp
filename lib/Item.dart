class ItemTemplate {}

class Item {
  //uuid
  String templateUUID;
  int amount;

  Item({required this.templateUUID, required this.amount});

  Map<String, dynamic> toJson() {
    return {
      "templateUUID": this.templateUUID,
      "amount": this.amount,
    };
  }

  factory Item.fromJSON(Map<String, dynamic> map) {
    return Item(
      templateUUID: map["templateUUID"],
      amount: map["amount"],
    );
  }
}

//TODO consiger invetory space
class Invetory {
  List<Item> items;
  Invetory() : this.items = [];

  addItem(Item item) {
    for (var i in items) {
      if (i.templateUUID == item.templateUUID) {
        i.amount += item.amount;
        // Update the current item
        return;
      }
    }
  }
}
