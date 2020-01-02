import 'package:flutter/material.dart';

class MyInfoDialog extends StatelessWidget {

  final String title;
  final String message;
  final double width;

  MyInfoDialog({
    this.title, 
    this.message,
    this.width = 150,
  });

  display(context){
    showDialog( context: context, builder: (_) => this);
  }

  Widget build(BuildContext context) {
    return SimpleDialog(
      children: <Widget>[
        Container(
        width: width,
        //height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
              child: Text(title, style: TextStyle(fontFamily: 'Titillium', fontSize: 20)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
              child: Text(message, style: TextStyle(fontFamily: 'Titillium')),
            ),
            FlatButton(
              child: Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      ],
    );
  }

}