import 'package:flutter/material.dart';

import 'chat_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(
          primarySwatch: Colors.blue,
          iconTheme: const IconThemeData(
              color: Colors.blue
          )
      ),
      home: const ChatScreen(),
    );
  }
}
