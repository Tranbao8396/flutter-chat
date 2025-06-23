import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:logger/web.dart';
import 'package:multi_message/models/message_model.dart';

class MessageService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String message,
    required String email,
  }) async {
    final Timestamp timestamp = Timestamp.now();
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email!;
    final String currentUserName = await _fireStore
        .collection('users')
        .doc(currentUserId)
        .get()
        .then((doc) => doc.data()?['name'] ?? '');

    List<String> chatId = [currentUserId, email];
    chatId.sort();
    await _fireStore
        .collection('chat')
        .doc(chatId.join("*"))
        .collection('messages')
        .add(
          MessageModel(
            message: message,
            receiverId: email,
            timestamp: timestamp,
            senderId: currentUserId,
            senderEmail: currentUserEmail,
          ).toMap(),
        );

    // Gửi thông báo đến người nhận
    final receiverUserToken = await _fireStore
      .collection('users')
      .doc(email)
      .get()
      .then((doc) => doc.data()?['fcm_token'] ?? '');

    Logger().i('Bắt Đầu gửi thông báo đến người dùng: $email');
    final push = await post(
      Uri.parse('http://10.0.2.2:3000/send-notification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': receiverUserToken,
        'title': 'Tin nhắn mới từ $currentUserName',
        'body': message,
      }),
    );

    Logger().i('Đã gửi thông báo đến người dùng: $email');
    Logger().i(push);
  }

  Stream<QuerySnapshot> getMessages({
    required String currentUserId,
    required String receiverUserId,
  }) {
    List<String> chatId = [currentUserId, receiverUserId];
    chatId.sort();

    return _fireStore
        .collection('chat')
        .doc(chatId.join("*"))
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendImage({
    required String imageUrl,
    required String email,
    String? message,
  }) async {
    final Timestamp timestamp = Timestamp.now();
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email!;

    List<String> chatId = [currentUserId, email];
    chatId.sort();
    await _fireStore
        .collection('chat')
        .doc(chatId.join("*"))
        .collection('messages')
        .add(
          MessageModel(
            message: message ?? '',
            receiverId: email,
            timestamp: timestamp,
            senderId: currentUserId,
            senderEmail: currentUserEmail,
            imageUrl: imageUrl,
          ).toMap(),
        );
  }
}
