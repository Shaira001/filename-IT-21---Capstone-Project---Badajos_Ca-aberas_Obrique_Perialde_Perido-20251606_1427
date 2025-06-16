import 'package:flutter/material.dart';

class Official {
  // Fields
  late String name;
  late String image;
  late String position;
  late String key;

  // Constructors
  Official({
    this.name = '',
    this.image = '',
    this.position = '',
    this.key = '', required ,
  });


  Official.empty()
      : name = '',
        image = '',
        position = '',
        key = '';


  factory Official.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic>? data = json;
    return Official(
      name: data?['Name'] ?? '',
      image: data?['image'] ?? '',
      position: data?['Position'] ?? '',
      key: data?['key'] ?? '',

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'image': image,
      'Position': position,
      'key': key,

    };
  }
}
