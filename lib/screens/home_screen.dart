import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:multi_message/models/chat_screen_model.dart';
import 'package:multi_message/services/authentication.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // thiết lập push notification request
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    FirebaseMessaging.instance.getToken().then((token) {
      Logger().i("Thiết bị nhận FCM token: $token");
      // Bạn cần lưu token này vào database để gửi tin nhắn cho đúng người

      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'fcm_token': token})
          .then((_) {
            Logger().i("Token đã được lưu vào Firestore");
          });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger().i(
        'Nhận được message khi đang mở app: ${message.notification?.title}',
      );
      // Hiển thị thông báo hoặc cập nhật UI
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await Authentication.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
        backgroundColor: Theme.of(context).primaryColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              'Messenger',
              style: GoogleFonts.poppins(
                fontSize: 24.0,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ".",
              style: GoogleFonts.poppins(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Something went wrong',
                  style: GoogleFonts.poppins(
                    fontSize: 18.0,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              );
            }
            return Scrollbar(
              child: ListView(
                children: snapshot.data!.docs
                    .where(
                      (doc) =>
                          doc['email'] !=
                          FirebaseAuth.instance.currentUser!.email,
                    )
                    .map<Widget>(
                      (doc) => ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: ChatScreenModel(
                            userId: doc['uid'],
                            email: doc['email'],
                            userName: doc['name'],
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Text(doc['name'].toString()),
                        ),
                        title: Text(
                          doc['name'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16.0,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          doc['email'],
                          style: GoogleFonts.poppins(
                            fontSize: 14.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
