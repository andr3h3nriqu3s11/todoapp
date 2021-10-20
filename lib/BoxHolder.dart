import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BoxHolder extends StatefulWidget {
  const BoxHolder(
      {Key? key,
      required this.name,
      required this.children,
      required this.toggleable,
      this.defaultActive = false})
      : super(key: key);

  final String name;
  final List<Widget> children;
  final bool toggleable;
  final bool defaultActive;

  @override
  State<StatefulWidget> createState() => _BoxHolderState(active: defaultActive);
}

class _BoxHolderState extends State<BoxHolder> {
  _BoxHolderState({required this.active});
  bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Container(
                    //Title Container decoration
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(0, 3))
                    ]),
                    // Title container decoration end
                    child: GestureDetector(
                        onTap: () {
                          if (widget.toggleable)
                            setState(() {
                              active = !active;
                            });
                        },
                        child: Padding(
                          //TODO: Improve change for an icon at the end of the row
                          child: Text(widget.name +
                              (!widget.toggleable
                                  ? ""
                                  : active
                                      ? "/\\"
                                      : "\\/")),
                          padding: EdgeInsets.symmetric(vertical: 8)
                              .add(EdgeInsets.only(left: 10)),
                        )))),
            Expanded(
                child: SingleChildScrollView(
                    child: Column(
              children: !widget.toggleable || active
                  // Children that appear
                  ? widget.children
                  : [
                      SizedBox(
                        width: 0,
                      )
                    ],
            )))
          ],
        )
      ],
    );
  }
}
