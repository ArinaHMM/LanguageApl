import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VideoUploadPage extends StatefulWidget {
  @override
  _VideoUploadPageState createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _videoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    setState(() {
      _videoFile = pickedFile;
    });
  }

  Future<void> _uploadVideo() async {
    if (_videoFile != null && _titleController.text.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      // Загружаем видео в Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('videos/${_videoFile!.name}');
      UploadTask uploadTask = ref.putFile(File(_videoFile!.path));

      // Получаем ссылку на загруженное видео
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем уникальный id для нового документа
      String documentId =
          FirebaseFirestore.instance.collection('videolessons').doc().id;

      // Сохраняем информацию о видео в Firestore с созданным id
      FirebaseFirestore.instance
          .collection('videolessons')
          .doc(documentId)
          .set({
        'id': documentId, // Сохраняем id в Firestore
        'title': _titleController.text,
        'description': _descriptionController.text,
        'videoUrl': downloadUrl,
      });

      setState(() {
        _isUploading = false;
        _videoFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Видео загружено!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Загрузить видеоурок'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(
                context, '/navadmin'); // Возврат на предыдущую страницу
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Название урока'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Описание урока'),
            ),
            SizedBox(height: 20),
            _videoFile == null
                ? Text('Выберите видео')
                : Text('Видео выбрано: ${_videoFile!.name}'),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Выбрать видео'),
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadVideo,
                    child: Text('Загрузить видео'),
                  ),
          ],
        ),
      ),
    );
  }
}
