//This file will have the classes and login for the startup of the app

import 'package:app/Profile.dart';
import 'package:flutter/material.dart';

class CreateAccount extends StatefulWidget {
  CreateAccount({Key? key, required this.profile, required this.done})
      : super(key: key);

  final Profile profile;
  final Function(Profile) done;

  @override
  State<StatefulWidget> createState() => _CreateAccount(profile: profile);
}

class _CreateAccount extends State<CreateAccount> {
  _CreateAccount({required this.profile});
  Profile profile;

  int state = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    //State 0
    var state0 = Container(
        color: Colors.blue,
        child: Center(
          child: Text(
            "Ready to Start?",
            style: TextStyle(color: Colors.white, fontSize: 40),
          ),
        ));
    //State 1
    var state1 = Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Your name'),
                validator: (String? v) {
                  if (v == null || v == '') {
                    return 'Please enter a name';
                  }
                },
                onSaved: (String? v) {
                  if (v != null)
                    setState(() {
                      profile.name = v;
                    });
                },
              )
            ],
          )),
    );

    return Scaffold(
      body: state == 0
          ? state0
          : state == 1
              ? state1
              : null,
      appBar: state == 0 ? null : AppBar(title: Text('Create Account')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.arrow_right_alt),
        tooltip: 'Next',
        onPressed: () {
          setState(() {
            if (state == 0) {
              //Deal with the start page
              state++;
            } else if (state == 1) {
              //If not valid return
              if (!_formKey.currentState!.validate()) return;

              _formKey.currentState!.save();

              widget.done(profile);
              //If there is a need for more pages
              //state++;
            }
          });
        },
      ),
    );
  }
}
