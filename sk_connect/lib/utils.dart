import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sk_connect/client_class.dart';

Client curClient = Client.empty();

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width <   MediaQuery.of(context).size.height;
}

double maxWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool password;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.password = false,
    this.errorText,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 40,
      margin: const EdgeInsets.all(15),
      child: TextFormField(
        style: const TextStyle(color: Color(0xFF388E3C)),
        controller: widget.controller,
        obscureText: widget.password && _obscureText,
        decoration: InputDecoration(
          label: Text(
            widget.labelText,
            style: const TextStyle(color: Color(0xFF388E3C)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF81C784)), 
            borderRadius: BorderRadius.circular(0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xFF388E3C),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          errorText: widget.errorText,
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF388E3C),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}


class CheckboxRow extends StatefulWidget {
  final String labelText;
  final Function onCheckboxChanged;

  const CheckboxRow({
    super.key,
    required this.labelText,
    required this.onCheckboxChanged,
  });
  @override
  _CheckboxRowState createState() => _CheckboxRowState();
}

class _CheckboxRowState extends State<CheckboxRow> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Checkbox(
            fillColor: MaterialStateProperty.all(const Color(0xFF388E3C)), // Dark green
            value: isChecked,
            onChanged: (bool? value) {
              setState(() {
                isChecked = value ?? false;
                widget.onCheckboxChanged(value ?? false);
              });
            },
          ),
          Text(
            widget.labelText,
            style: const TextStyle(fontSize: 20, color: Color(0xFF388E3C)), // Dark green text
          ),
        ],
      ),
    );
  }
}

class AlertDialogHelper {
  static void showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE8F5E9), 
          title: const Text(
            'Alert',
            style: TextStyle(color: Color(0xFF388E3C)),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Color(0xFF388E3C)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF388E3C)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class HighlightText extends StatelessWidget {
  final String text;
  final String wordToHighlight;
  final TextStyle defaultStyle;
  final TextStyle highlightStyle;

  const HighlightText({
    Key? key,
    required this.text,
    required this.wordToHighlight,
    this.defaultStyle = const TextStyle(color: Colors.black, fontSize: 16),
    this.highlightStyle = const TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> parts = text.split(wordToHighlight);

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              TextSpan(
                text: wordToHighlight,
                style: highlightStyle,
              ),
          ],
        ],
      ),
    );
  }
}

String formatTimeDifference(DateTime timestamp) {
  Duration difference = DateTime.now().difference(timestamp);

  if (difference.inSeconds < 60) {
    return "${difference.inSeconds}s ago";
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes}m ago";
  } else if (difference.inHours < 24) {
    return "${difference.inHours}h ago";
  } else if (difference.inDays < 7) {
    return "${difference.inDays}d ago";
  } else {
    return "${timestamp.month}/${timestamp.day}/${timestamp.year}";
  }
}

const kSendButtonTextStyle = TextStyle(
  color: Colors.lightBlueAccent,
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
);

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Type your message here...',
  hintStyle: TextStyle(fontFamily: 'Poppins',fontSize: 14),
  border: InputBorder.none,
);

const kMessageContainerDecoration = BoxDecoration(
  // border: Border(
  //   top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
  // ),
  
);

int levenshteinDistance(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  List<List<int>> matrix = List.generate(
    s.length + 1,
    (_) => List.filled(t.length + 1, 0),
  );

  for (int i = 0; i <= s.length; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= t.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= s.length; i++) {
    for (int j = 1; j <= t.length; j++) {
      int cost = s[i - 1] == t[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,     // deletion
        matrix[i][j - 1] + 1,     // insertion
        matrix[i - 1][j - 1] + cost // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return matrix[s.length][t.length];
}

double stringSimilarity(String s, String t) {
  int distance = levenshteinDistance(s, t);
  int maxLength = s.length > t.length ? s.length : t.length;
  if (maxLength == 0) return 1.0; // Both strings are empty
  return (1 - distance / maxLength);
}

bool isOneOrTwoDigit(String input) {
  RegExp regex = RegExp(r'^\d{1,2}$');
  return regex.hasMatch(input);
}
bool isFourDigits(String input) {
  RegExp regex = RegExp(r'^\d{4}$');
  return regex.hasMatch(input);
}

DateTime containsDate(String text) {
  DateTime dateTime;
  List<String> textList = text.split(RegExp(r'\s+')).toList();

  int? year;
  int? month;
  int? day;

  for (var i in textList) {
    // Check for dash-separated date formats
    if (RegExp(r'^\d{1,4}-\d{1,2}-\d{1,4}$').hasMatch(i)) {
      List<String> parts = i.split('-');
      List<int> nums = parts.map(int.parse).toList();

      if (nums.length == 3) {
        // Heuristics to determine order
        if (nums[0] > 31) {
          // Assume year-month-day
          year = nums[0];
          month = nums[1];
          day = nums[2];
        } else if (nums[2] > 31) {
          // Assume day-month-year or month-day-year
          if (nums[1] <= 12) {
            // Assume day-month-year
            day = nums[0];
            month = nums[1];
            year = nums[2];
          } else {
            // Assume month-day-year
            month = nums[0];
            day = nums[1];
            year = nums[2];
          }
        } else {
          // Fallback (assume year-month-day)
          year = nums[0];
          month = nums[1];
          day = nums[2];
        }
        continue;
      }
    }

    // Check for month name
    if (lowercaseMonths.contains(i.toLowerCase())) {
      month = lowercaseMonths.indexOf(i.toLowerCase()) + 1;
    }

    // Check for 1-2 digit day
    if (isOneOrTwoDigit(i)) {
      int val = int.parse(i);
      if (val >= 1 && val <= 31) {
        day ??= val;
      }
    }

    // Check for 4-digit year
    if (isFourDigits(i)) {
      int val = int.parse(i);
      if (val > 999) {
        year = val;
      }
    }
  }

  // Fallback to current year/month/day if missing
  final now = DateTime.now();
  return DateTime(
    year ?? now.year,
    month ?? now.month,
    day ?? now.day,
    0, 0, 0, 0, 0,
  );
}


List<String> months = [
    "January", "February", "March", "April", "May", "June", 
    "July", "August", "September", "October", "November", "December"
  ];

  // Convert all month names to lowercase
List<String> lowercaseMonths = months.map((month) => month.toLowerCase()).toList();