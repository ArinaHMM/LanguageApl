import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String? id;
  String? selectedLanguage;

  UserModel.fromFirebase(User user) {
    id = user.uid;
  }

  UserModel.fromData(String id, String selectedLanguage) {
    this.id = id;
    this.selectedLanguage = selectedLanguage;
  }
}
