// lib/client_class.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp if you ever decide to use it in toJson

class Client {
  String uid;
  String firstname;
  String lastname;
  String email;
  String key;
  String profilePicture;
  String address;
  String gender;
  DateTime birthday; // Correctly defined as DateTime
  bool isResident;

  // Constructor
  Client({
    required this.uid,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.key,
    required this.profilePicture,
    required this.address,
    required this.gender,
    required this.birthday,
    required this.isResident,
  });

  // Named constructor for an empty Client
  Client.empty()
      : uid = '',
        firstname = '',
        lastname = '',
        email = '',
        profilePicture = '',
        key = '',
        address = '',
        gender = '',
        birthday = DateTime(2000, 1, 1), // Default DateTime
        isResident = false;

  // Factory constructor for creating a Client from JSON (e.g., from Firestore)
  factory Client.fromJson(Map<String, dynamic> json) {
    // Handle birthday: parse from String or default if null/invalid
    DateTime parsedBirthday;
    if (json['birthday'] is String) {
      parsedBirthday = DateTime.parse(json['birthday'] as String);
    } else if (json['birthday'] is Timestamp) {
      // In case Firestore stores it as a Timestamp for some reason
      parsedBirthday = (json['birthday'] as Timestamp).toDate();
    } else {
      // Fallback for null or unexpected type
      parsedBirthday = DateTime(2000, 1, 1);
    }

    return Client(
      uid: json['uid'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      key: json['key'] ?? '',
      address: json['address'] ?? '',
      gender: json['gender'] ?? '',
      birthday: parsedBirthday, // Use the parsed DateTime
      isResident: json['isResident'] == true, // Correctly parse boolean
    );
  }

  // Convert Client instance to JSON (for saving to Firestore, etc.)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstname': firstname,
      'lastname': lastname,
      'profilePicture': profilePicture,
      'email': email,
      'key': key,
      'address': address,
      'gender': gender,
      'birthday': birthday.toIso8601String(), // Convert DateTime to ISO 8601 String
      'isResident': isResident,
    };
  }

  // Get full name
  String get fullName => '$firstname $lastname';

  // Setters (if Client object needs to be mutable)
  void setUid(String uid) {
    this.uid = uid;
  }

  void setFirstname(String firstname) {
    this.firstname = firstname;
  }

  void setLastname(String lastname) {
    this.lastname = lastname;
  }

  void setEmail(String email) {
    this.email = email;
  }

  void setKey(String key) {
    this.key = key;
  }

  void setProfilePicture(String profilePicture) {
    this.profilePicture = profilePicture;
  }

  void setAddress(String address) {
    this.address = address;
  }

  void setGender(String gender) {
    this.gender = gender;
  }

  void setBirthday(DateTime birthday) {
    this.birthday = birthday;
  }

  void setIsResident(bool isResident) {
    this.isResident = isResident;
  }
}