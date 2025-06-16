import 'package:flutter/material.dart';
import 'package:sk_connect/database_helper.dart';
import 'package:sk_connect/Feedback_class.dart' as FeedbackClass;
import 'package:sk_connect/utils.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // Theme colors
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _errorColor = const Color(0xFFD62839);

  double _rating = 3.0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);

    try {
      final rating = _rating.toInt();
      final comment = _feedbackController.text.trim();

      // Optional validation
      if (comment.isEmpty && rating < 2) {
        _showMessage('Please provide a comment or a rating above 1',
            isError: true);
        return;
      }

      await addFeedback(FeedbackClass.Feedback(
        key: '', // Will be generated in DB
        rating: rating,
        comment: comment,
        clientUid: curClient.uid,
      ));

      _showMessage('Thank you for your feedback!', isError: false);
      _feedbackController.clear();
      setState(() => _rating = 3.0);
    } catch (e) {
      _showMessage('Failed to submit feedback: ${_getUserFriendlyError(e)}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 36,
        );
      }),
    );
  }

  Future<String> _getClientName(String clientUid) async {
    final client = await getClient(clientUid);
    return '${client?.firstname} ${client?.lastname}' ?? 'Anonymous';
  }

  String _getUserFriendlyError(dynamic error) {
    return 'An error occurred. Please try again.';
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _errorColor : _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          secondary: _accentColor,
          error: _errorColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text('Feedback'),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.feedback_outlined,
                              size: 48, color: Colors.amber),
                          const SizedBox(height: 16),
                          const Text(
                            'How would you rate your experience?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          _buildRatingStars(_rating),
                          Slider(
                            value: _rating,
                            onChanged: (value) =>
                                setState(() => _rating = value),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _rating.toStringAsFixed(1),
                            activeColor: Colors.amber,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Additional comments (optional)',
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.amber, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitFeedback,
                              icon: const Icon(Icons.send),
                              label: Text(_isSubmitting
                                  ? 'SUBMITTING...'
                                  : 'SUBMIT FEEDBACK'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Previous Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<FeedbackClass.Feedback>>(
                    stream: streamAllFeedbacks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'No feedback yet',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final feedbacks = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: feedbacks.length,
                        itemBuilder: (context, index) {
                          final fb = feedbacks[index];
                          return FutureBuilder<String>(
                            future: _getClientName(fb.clientUid),
                            builder: (context, nameSnapshot) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.star, color: Colors.amber),
                                      Text(
                                        fb.rating.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    (fb.comment != null &&
                                            fb.comment!.isNotEmpty)
                                        ? fb.comment!
                                        : '[No comment]',
                                    style: TextStyle(
                                      fontStyle: (fb.comment == null ||
                                              fb.comment!.isEmpty)
                                          ? FontStyle.italic
                                          : null,
                                    ),
                                  ),
                                  subtitle: nameSnapshot.hasData
                                      ? Text(nameSnapshot.data!)
                                      : const Text('Loading...'),
                                  trailing: const Icon(Icons.person_outline),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
