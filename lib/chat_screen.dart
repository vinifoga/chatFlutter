import 'dart:io';

import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {



  void _sendMessage({String? text, XFile? image}) async {
    Map<String, dynamic> data = {};
    await Firebase.initializeApp();

    if (image != null) {
      File file = File(image.path);
      UploadTask task = FirebaseStorage.instance.ref().child('images').child(
          DateTime
              .now()
              .millisecondsSinceEpoch
              .toString()).putFile(file);

      task.whenComplete(() async {
        String url = await task.snapshot.ref.getDownloadURL();
        print(url);
        data['imageUrl'] = url;
        FirebaseFirestore.instance.collection('messages').add(data);
      });
    }
    if (text != null) {
      data['text'] = text;
      FirebaseFirestore.instance.collection('messages').add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('messages').snapshots(),
            builder: (context, snapshot){
              switch (snapshot.connectionState){
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                default:
                  List<DocumentSnapshot?>? documents = snapshot.data?.docs.reversed.toList();
                  return ListView.builder(
                      itemCount: documents?.length,
                      reverse: true,
                      itemBuilder: (context, index){
                        return ListTile(
                          title: Text(documents![index]?.get('text')),
                        );
                      });
              }
            },
          )),
          TextComposer(sendMessage: (_sendMessage)),
        ],
      ),
    );
  }

  @override
  void initState() {
    Firebase.initializeApp();
  }
}
