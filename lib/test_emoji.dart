import 'package:flutter/material.dart';
import './extensions/extensions.dart';

class TestWidget extends StatefulWidget {
  TestWidget({Key? key}) : super(key: key);

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  String text = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VM SDK TEST"),
      ),
      body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(onChanged: (value) {
            setState(() {
              text = value;
            });
          }),
          SizedBox(height: 20),
          Text(text),
          SizedBox(height: 20),
          Text("hasEmoji : ${text.hasEmoji()}"),
        ],
      )),
      // floatingActionButton: FloatingActionButton(onPressed: _run, tooltip: 'Run', child: const Icon(Icons.play_arrow)),
    );
  }
}
