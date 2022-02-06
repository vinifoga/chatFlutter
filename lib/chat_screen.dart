import 'dart:io';

import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googelSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  User? _currentUser;
  bool _isLoading = false;

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googelSignIn.signIn();
      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication?.idToken,
        accessToken: googleSignInAuthentication?.accessToken,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;
      return user;
    } catch (e) {
      return null;
    }
  }

  void _sendMessage({String? text, XFile? image}) async {
    final User? user = await _getUser();

    if (user == null) {
      setState(() {
        _scaffoldKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Não foi possível fazer o login. Tente novamente'),
        ));
      });
    }

    Map<String, dynamic> data = {
      "uid": user?.uid,
      "senderName": user?.displayName,
      "senderPhotoUrl": user?.photoURL,
      "time": Timestamp.now(),
    };

    if (image != null) {
      File file = File(image.path);
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child('images').child(user!.uid.toString())
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(file);
      setState(() {
        _isLoading = true;
      });

      task.whenComplete(() async {
        String url = await task.snapshot.ref.getDownloadURL();
        print(url);
        data['imageUrl'] = url;
        FirebaseFirestore.instance.collection('messages').add(data);

        setState(() {
          _isLoading = false;
        });
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
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser?.displayName}'
            : 'Chat App'),
        elevation: 0,
        centerTitle: true,
        actions: [
          _currentUser != null
              ? IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googelSignIn.signOut();
                    _scaffoldKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text('Saiu com Sucesso!'),
                      ),
                    );
                  },
                )
              : Container(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot?>? documents =
                        snapshot.data?.docs.reversed.toList();
                    return ListView.builder(
                        itemCount: documents?.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          return ChatMessage(
                              documents?[index]?.data() as Map<String, dynamic>,
                              documents?[index]?.get('uid') == _currentUser?.uid);
                        });
                }
              },
            ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(sendMessage: (_sendMessage)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }
}
