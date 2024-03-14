import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class FamilyChatScreen extends StatefulWidget {
  final String familyId;

  FamilyChatScreen({required this.familyId});

  @override
  _FamilyChatScreenState createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isEditing = false;
  TextEditingController _editingController = TextEditingController();
  String editingMessageId = "";
  Future<void>? _imageLoadingFuture;
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _editMessage(String messageId, String currentText) {
    setState(() {
      isEditing = true;
      _editingController.text = currentText;
      editingMessageId = messageId;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Редактирование сообщения"),
          content: TextField(
            controller: _editingController,
            decoration: InputDecoration(
              hintText: 'Отредактируйте ваше сообщение',
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                _saveEditedMessage();
                Navigator.of(context).pop(); 
              },
              child: Text('Сохранить'),
            ),
            TextButton(
              onPressed: () {
                _cancelEditing();
                Navigator.of(context).pop(); 
              },
              child: Text('Отменить'),
            ),
          ],
        );
      },
    );
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      _editingController.clear();
      editingMessageId = "";
    });
  }

  Future<void> _saveEditedMessage() async {
    if (_editingController.text.isNotEmpty) {
      await _firestore
          .collection('familyChats')
          .doc(widget.familyId)
          .collection('messages')
          .doc(editingMessageId)
          .update({
        'text': _editingController.text,
        // 'timestamp': FieldValue.serverTimestamp(),
      });

      _cancelEditing();
    }
  }

  void _copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message));
    _showSnackBar('Сообщение скопировано');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _deleteMessage(String messageId) async {
  await _firestore
      .collection('familyChats')
      .doc(widget.familyId)
      .collection('messages')
      .doc(messageId)
      .delete();
}

  Future<void> _sendPhoto() async {
  User? user = _auth.currentUser;

  if (user != null) {
    final picker = ImagePicker();
    final XFile? pickedFile = await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('Сделать фото'),
                onTap: () async {
                  Navigator.pop(context, await picker.pickImage(source: ImageSource.camera));
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Выбрать из галереи'),
                onTap: () async {
                  Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery));
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      setState(() {
        _imageLoadingFuture = _uploadImage(pickedFile.path);
      });

      String imageUrl = await _uploadImage(pickedFile.path);
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      String senderName = userSnapshot['firstName'];
      String senderSurname = userSnapshot['lastName'];
      await _firestore
          .collection('familyChats')
          .doc(widget.familyId)
          .collection('messages')
          .add({
        'senderName': senderName,
        'senderSurname': senderSurname,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'senderUid': _auth.currentUser?.uid,
        'isPhoto': true,
      });
    }
  }
}


Future<String> _uploadImage(String filePath) async {
  try {
    firebase_storage.Reference storageReference =
        firebase_storage.FirebaseStorage.instance.ref().child(
              'familyChats/${widget.familyId}/${DateTime.now().millisecondsSinceEpoch.toString()}',
            );

    firebase_storage.UploadTask uploadTask =
        storageReference.putFile(File(filePath));

    await uploadTask;

    return await storageReference.getDownloadURL();
  } catch (e) {
    print('Error uploading image: $e');
    return ''; 
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor:Color.fromARGB(255, 10, 114, 1), 
        title: Text('Семейный чат'),
      ),
      body: Column(
        children: [
          Expanded(
            child:StreamBuilder(
  stream: _firestore
      .collection('familyChats')
      .doc(widget.familyId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return Center(child: Image.asset('assets/loading.gif',
                        height: 200),);
    }

    var messages = snapshot.data?.docs;

    List<Widget> messageWidgets = [];
    for (var message in messages!) {
      if (message['isPhoto']) {
      var editingMessageId = message.id;
      var messageSenderName = message['senderName'];
      var messageSenderSurname = message['senderSurname'];
      var messageSenderUid = message['senderUid'];
      var imageUrl = message['imageUrl'] ?? ''; 
      var isCurrentUser = messageSenderUid == _auth.currentUser?.uid;

      var messageWidget = MessageWidget(
        imageLoadingFuture:_imageLoadingFuture,
        senderName: messageSenderName,
        senderSurname: messageSenderSurname,
        senderUid: messageSenderUid,
        text: '',
        imageUrl: imageUrl,
        isCurrentUser: isCurrentUser,
        isEditing: isEditing,
        messageId: editingMessageId,
        editMessage: _editMessage,
        cancelEditing: _cancelEditing,
        deleteMessage: _deleteMessage,
        saveEditedMessage: _saveEditedMessage,
        copyMessage: _copyMessage,
      );

      messageWidgets.add(messageWidget);
      } else {
      var editingMessageId = message.id;
      var messageText = message['text'] ?? ''; 
      var messageSenderUid = message['senderUid'];
      var messageSenderName = message['senderName'];
      var messageSenderSurname = message['senderSurname']; 
      var isCurrentUser = messageSenderUid == _auth.currentUser?.uid;

      var messageWidget = MessageWidget(
         imageLoadingFuture:_imageLoadingFuture,
        senderName: messageSenderName,
        senderSurname: messageSenderSurname,
        senderUid: messageSenderUid,
        text: messageText,
        imageUrl: '',
        isCurrentUser: isCurrentUser,
        isEditing: isEditing,
        messageId: editingMessageId,
        editMessage: _editMessage,
        cancelEditing: _cancelEditing,
        deleteMessage: _deleteMessage,
        saveEditedMessage: _saveEditedMessage,
        copyMessage: _copyMessage,
      );

      messageWidgets.add(messageWidget);
      }
    }

    return ListView(
      reverse: true,
      children: messageWidgets,
    );
  },
),

          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                 IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: () {
                    _sendPhoto();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
  User? user = _auth.currentUser;

  if (user != null) {
    String messageText = _messageController.text.trim();

    if (messageText.isNotEmpty || _messageController.text.isNotEmpty) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      String senderName = userSnapshot['firstName'];
      String senderSurname = userSnapshot['lastName'];

      if (_messageController.text.isNotEmpty) {
        await _firestore
            .collection('familyChats')
            .doc(widget.familyId)
            .collection('messages')
            .add({
          'text': messageText,
          'senderName': senderName,
          'senderSurname': senderSurname,
          'timestamp': FieldValue.serverTimestamp(),
          'senderUid': user.uid,
          'isPhoto': false,
        });

        _messageController.clear();
      } else {
        _sendPhoto();
      }
    }
  }
}
}

class MessageWidget extends StatelessWidget {
  final String senderName;
  final String senderSurname;
  final String senderUid;
  final String text;
  final String imageUrl;
  final String messageId;
  final bool isEditing;
  final bool isCurrentUser;
  final Function(String, String) editMessage;
  final Function deleteMessage;
  final Function cancelEditing;
  final Function saveEditedMessage;
  final Function(String) copyMessage;
    final Future<void>? imageLoadingFuture;

  MessageWidget({
    required this.senderName,
    required this.senderSurname,
    required this.senderUid,
    required this.text,
    required this.imageUrl,
    required this.messageId,
    required this.isEditing,
    required this.isCurrentUser,
    required this.editMessage,
    required this.cancelEditing,
    required this.saveEditedMessage,
    required this.copyMessage,
    required this.imageLoadingFuture, 
    required this.deleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable(
      hapticFeedbackOnStart: true,
      feedback: Material(
        child: Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 150, 
                  fit: BoxFit.cover,
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black,
                  ),
                ),
        ),
      ),
      data: messageId,
      childWhenDragging: Container(),
      child: InkWell(
        onLongPress: () {
          if (isCurrentUser) {
            _showMessageOptions(context);
          } else if (imageUrl.isNotEmpty) {
            _showImageDialog(context, imageUrl);
          } else {
            copyMessage(text);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isCurrentUser)
                Text(
                  '$senderName $senderSurname',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isCurrentUser ? 12.0 : 2.0),
                    topRight: Radius.circular(isCurrentUser ? 2.0 : 12.0),
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                padding: EdgeInsets.all(8.0),
                child: imageUrl.isNotEmpty
                    ? FutureBuilder(
                        future: imageLoadingFuture, // Добавлен Future для отслеживания загрузки изображения
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Image.asset('assets/loading.gif',
                        height: 200),
                            );
                          } else if (snapshot.hasError) {
                            // Обработка ошибки загрузки
                            return Text('Ошибка загрузки изображения');
                          } else {
                            // Отображение изображения
                            return Image.network(
                              imageUrl,
                              height: 150,
                              fit: BoxFit.contain,
                            );
                          }
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: TextStyle(
                              color:
                                  isCurrentUser ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 1),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  void _showMessageOptionsStrang(BuildContext context) {
  //  showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: Icon(Icons.copy),
  //             title: Text('Скопировать сообщение'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               copyMessage(text);
  //             },
  //           ),
  //           if (imageUrl.isNotEmpty)
  //             ListTile(
  //               leading: Icon(Icons.photo),
  //               title: Text('Открыть фотографию'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _showImageDialog(context, imageUrl);
  //               },
  //             ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showMessageOptions(BuildContext context) {
   showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             if (!imageUrl.isNotEmpty) 
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Редактировать сообщение'),
              onTap: () {
                Navigator.pop(context);
                editMessage(messageId, text);
              },
            ),
            if (!imageUrl.isNotEmpty) 
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Скопировать сообщение'),
              onTap: () {
                Navigator.pop(context);
                copyMessage(text);
              },
            ),
            if (imageUrl.isNotEmpty)
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Открыть фотографию'),
                onTap: () {
                  Navigator.pop(context);
                  _showImageDialog(context, imageUrl);
                },
              ),
               if (isCurrentUser) 
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Удалить сообщение'),
              onTap: () {
                Navigator.pop(context);
                deleteMessage(messageId);
              },
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // Закрываем диалог при нажатии в любом месте
          },
          child: Container(
            width: double.infinity,
            height: 400,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain, 
            ),
          ),
        ),
      );
    },
  );
}
}
