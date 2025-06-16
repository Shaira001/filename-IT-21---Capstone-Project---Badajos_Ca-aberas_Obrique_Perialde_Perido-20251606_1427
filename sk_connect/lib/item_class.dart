import 'dart:convert'; // Import for base64Decode/Encode if used directly within the class (though typically in UI)

class Item {
  String key;
  String name;
  String image;
  int totalQuantity;
  int borrowed;
  String details;
  String status;
  
  /// NEW: rollNumber field
  String rollNumber;

  /// List of control numbers for this item
  List<String> controlNumbers;

  /// NEW: Map of control number to its specific image (Base64 string)
  Map<String, String> controlNumberImages;

  /// NEW: Map of control number to its specific brand title
  Map<String, String> controlNumberBrands;

  Item({
    required this.key,
    required this.name,
    required this.image,
    required this.totalQuantity,
    this.borrowed = 0,
    this.details = '',
    this.status = '',
    this.rollNumber = '',  // Add rollNumber with a default value
    this.controlNumbers = const <String>[],
    this.controlNumberImages = const <String, String>{},
    this.controlNumberBrands = const <String, String>{}, // Initialize the new field
  });

  int get available => totalQuantity - borrowed;
  bool get isAvailable => available > 0;

  /// Convert to JSON for Firebase (Firestore or Realtime DB)
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'image': image,
      'totalQuantity': totalQuantity,
      'borrowed': borrowed,
      'details': details,
      'status': status,
      'rollNumber': rollNumber, // Include rollNumber in the JSON output
      'controlNumbers': controlNumbers,
      'controlNumberImages': controlNumberImages,
      'controlNumberBrands': controlNumberBrands, // Include the new field in JSON
    };
  }

  /// Create from a Firebase document (Map<String,dynamic>)
  factory Item.fromJson(Map<String, dynamic> json) {
    List<String> parsedCNs = [];
    if (json.containsKey('controlNumbers')) {
      final raw = json['controlNumbers'];
      if (raw is List) {
        parsedCNs = raw.map((e) => e.toString()).toList();
      }
    }

    Map<String, String> parsedCNImages = {};
    if (json.containsKey('controlNumberImages')) {
      final rawImages = json['controlNumberImages'];
      if (rawImages is Map) {
        parsedCNImages = rawImages.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }

    Map<String, String> parsedCNBrands = {}; // Parse the new field
    if (json.containsKey('controlNumberBrands')) {
      final rawBrands = json['controlNumberBrands'];
      if (rawBrands is Map) {
        parsedCNBrands = rawBrands.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }

    return Item(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      borrowed: (json['borrowed'] as num?)?.toInt() ?? 0,
      details: json['details'] ?? '',
      status: json['status'] ?? '',
      rollNumber: json['rollNumber'] ?? '',  // Parse rollNumber
      controlNumbers: parsedCNs,
      controlNumberImages: parsedCNImages, // Assign the parsed map
      controlNumberBrands: parsedCNBrands, // Assign the parsed map
    );
  }

  /// If you’re also using a convenience constructor that takes a documentId...
  factory Item.fromJsonWithDates(Map<String, dynamic>? json, String documentId) {
    final data = json ?? <String, dynamic>{};

    List<String> parsedCNs = [];
    if (data.containsKey('controlNumbers')) {
      final raw = data['controlNumbers'];
      if (raw is List) {
        parsedCNs = raw.map((e) => e.toString()).toList();
      }
    }

    Map<String, String> parsedCNImages = {};
    if (data.containsKey('controlNumberImages')) {
      final rawImages = data['controlNumberImages'];
      if (rawImages is Map) {
        parsedCNImages = rawImages.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }
    
    Map<String, String> parsedCNBrands = {}; // Parse the new field
    if (data.containsKey('controlNumberBrands')) {
      final rawBrands = data['controlNumberBrands'];
      if (rawBrands is Map) {
        parsedCNBrands = rawBrands.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }

    return Item(
      key: documentId,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      totalQuantity: (data['totalQuantity'] as num?)?.toInt() ?? 0,
      borrowed: (data['borrowed'] as num?)?.toInt() ?? 0,
      details: data['details'] ?? '',
      status: data['status'] ?? '',
      rollNumber: data['rollNumber'] ?? '',  // Parse rollNumber
      controlNumbers: parsedCNs,
      controlNumberImages: parsedCNImages, // Assign the parsed map
      controlNumberBrands: parsedCNBrands, // Assign the parsed map
    );
  }

  /// If you need a separate “withDates” serialization:
  Map<String, dynamic> toJsonWithDates() {
    return {
      'key': key,
      'name': name,
      'image': image,
      'totalQuantity': totalQuantity,
      'borrowed': borrowed,
      'details': details,
      'status': status,
      'rollNumber': rollNumber, // Include rollNumber
      'controlNumbers': controlNumbers,
      'controlNumberImages': controlNumberImages,
      'controlNumberBrands': controlNumberBrands, // Include the new field
    };
  }

  /// Add a copyWith method to Item class for easier updates (if not already present)
  Item copyWith({
    String? key,
    String? name,
    String? image,
    int? totalQuantity,
    int? borrowed,
    String? details,
    String? status,
    String? rollNumber,  // Add rollNumber to copyWith method
    List<String>? controlNumbers,
    Map<String, String>? controlNumberImages,
    Map<String, String>? controlNumberBrands, // Add to copyWith
  }) {
    return Item(
      key: key ?? this.key,
      name: name ?? this.name,
      image: image ?? this.image,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      borrowed: borrowed ?? this.borrowed,
      details: details ?? this.details,
      status: status ?? this.status,
      rollNumber: rollNumber ?? this.rollNumber,  // Use rollNumber if provided
      controlNumbers: controlNumbers ?? this.controlNumbers,
      controlNumberImages: controlNumberImages ?? this.controlNumberImages,
      controlNumberBrands: controlNumberBrands ?? this.controlNumberBrands, // Use if provided
    );
  }
}
