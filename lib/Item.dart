class ItemTemplate {
  String id;

  ItemTemplate({required this.id}) : super();

  Map<String, dynamic> toJSON() {
    return {
      "id": this.id,
    };
  }

  factory ItemTemplate.fromJSON(Map<String, dynamic> json) {
    return ItemTemplate(id: json['id']);
  }
}

enum ItemType { normal }

class Item {
  //uuid
  String templateUUID;
  String id;
  int amount;
  ItemType type;

  Item(
      {required this.templateUUID,
      required this.amount,
      required this.id,
      required this.type});

  Map<String, dynamic> toJson() {
    return {
      "templateUUID": this.templateUUID,
      "amount": this.amount,
      "id": this.id,
      "type": this.type.index,
    };
  }

  factory Item.fromJSON(Map<String, dynamic> map) {
    return Item(
      templateUUID: map["templateUUID"],
      amount: map["amount"],
      id: map["id"],
      type: ItemType.values[map["type"]],
    );
  }
}

//TODO consider invetory space
class Invetory {
  Map<String, Item> items;
  Map<String, ItemTemplate> itemTemplates;

  Invetory({required this.items, required this.itemTemplates});

  void addItem(Item item) {
    if (item.type == ItemType.normal) {
      for (var i in this.items.keys) {
        var a = this.items[i]!;
        if (item.templateUUID == a.templateUUID) {
          a.amount = item.amount;
          break;
        }
      }
    } else {
      throw Error();
    }
  }

  Map<String, dynamic> toJSON() {
    return {
      "items": this.items.map((key, item) => MapEntry(key, item.toJson())),
      "templates":
          this.itemTemplates.map((key, item) => MapEntry(key, item.toJSON())),
    };
  }

  factory Invetory.fromJSON(Map<String, dynamic> json) {
    Map<String, Item> items = {};
    Map<String, ItemTemplate> itemsTemplates = {};

    json["items"].keys.forEach((e) {
      try {
        Item item = Item.fromJSON(json['items'][e]);
        if (e == item.id) items[e] = item;
      } catch (e) {
        //TODO deal with the error
        print(e);
      }
    });

    json["templates"].keys.forEach((e) {
      try {
        ItemTemplate item = ItemTemplate.fromJSON(json['items'][e]);
        if (e == item.id) itemsTemplates[e] = item;
      } catch (e) {
        //TODO deal with the error
        print(e);
      }
    });
    return Invetory(items: items, itemTemplates: itemsTemplates);
  }
}
