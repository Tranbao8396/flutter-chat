import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_message/services/message_service.dart';
import 'package:multi_message/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String receiverEmail;
  final String receiverUserId;
  final String receiveruserName;

  const ChatScreen({
    super.key,
    required this.receiverEmail,
    required this.receiverUserId,
    required this.receiveruserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final picker = ImagePicker();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _messageService.sendMessage(
        email: widget.receiverUserId,
        message: _messageController.text,
      );
      _messageController.clear();
    }
  }

  Future imagePick() async {
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 160,
      imageQuality: 100,
    );

    // Send the image to the message service
    setState(() {});

    if (pickedImage != null) {
      await _messageService.sendImage(
        imageUrl: pickedImage.path,
        email: widget.receiverUserId,
        message: _messageController.text.isNotEmpty
            ? _messageController.text
            : null,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(
            'No image selected',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          onPressed: () async => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              widget.receiveruserName,
              style: GoogleFonts.poppins(
                fontSize: 20.0,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: _messageService.getMessages(
                  receiverUserId: widget.receiverUserId,
                  currentUserId: _firebaseAuth.currentUser!.uid,
                ),
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

                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );

                  return Padding(
                    padding: const EdgeInsets.all(10.0),

                    child: ListView(
                      controller: _scrollController,
                      children: snapshot.data!.docs.map((document) {
                        final Map<String, dynamic> data =
                            document.data() as Map<String, dynamic>;
                        return MessageBubble(
                          message: data['message'],
                          imageUrl: data['imageUrl'] ?? '',
                          timestamp: data['timestamp'],
                          userName: data['senderEmail'].toString().split(
                            "@",
                          )[0],
                          alignment:
                              data['senderId'] == _firebaseAuth.currentUser!.uid
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _messageController,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Type a message...',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelStyle: const TextStyle(color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 2.0,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 2.0,
                          ),
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 1.0),
                    child: IconButton(
                      onPressed: () async => imagePick(),
                      icon: Icon(Icons.image, color: Colors.white, size: 40.0),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 1.0),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: IconButton(
                        onPressed: () async => sendMessage(),
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
