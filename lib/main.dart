import 'package:app/EditNewItem.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeManager',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Life Manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _newItemPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => EditNewItemRoute()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TodoItem(data: TodoItemData("normal", "teste", DateTime.now())),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newItemPage,
        tooltip: 'Add new item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

//TO DELETE

class TodoItem extends StatefulWidget {
  const TodoItem({Key? key, required this.data}) : super(key: key);
  final TodoItemData data;

  @override
  State<StatefulWidget> createState() => _TodoItem();
}

class _TodoItem extends State<TodoItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.blueGrey,
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.data.type),
                    Text(widget.data.date.toString())
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /*IconButton(
                        icon: Icon(widget.data.done
                              ? Icons.face
                              : Icons.ballot_rounded),
                          color: Colors.white,
                          onPressed: () {
                            setState(() {
                              widget.data.done = !widget.data.done;
                            });
                            }), */
                      Container(
                          child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            widget.data.done = !widget.data.done;
                          });
                        },
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<CircleBorder>(
                              CircleBorder()),
                          backgroundColor: MaterialStateProperty.all<Color>(
                              widget.data.done ? Colors.blue : Colors.grey),
                        ),
                        child: const Padding(
                          padding: const EdgeInsets.all(1.0),
                        ),
                      )),
                      Text(widget.data.title),
                    ],
                  ),
                )
              ],
            )));
  }
}

class TodoItemData {
  TodoItemData(this.type, this.title, this.date);
  bool done = false;
  String title;
  String type;
  DateTime date;
}
