import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MoodSheet extends StatefulWidget {
  final String? docId; // The ID of the log we are editing
  final int? initialMood; // The mood they picked before
  final String? initialNote; // The note they wrote before

  const MoodSheet({super.key, this.docId, this.initialMood, this.initialNote});

  @override
  State<MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends State<MoodSheet> {
  int _selectedIndex = 2; // Default to 'Okay'
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _moods = [
    {
      'label': 'Awful',
      'icon': Icons.sentiment_very_dissatisfied_rounded,
      'color': const Color(0xFF757575),
      'bgColor': const Color(0xFFF0F0F0),
      'value': 1,
    },
    {
      'label': 'Bad',
      'icon': Icons.sentiment_dissatisfied_rounded,
      'color': const Color(0xFF7E57C2),
      'bgColor': const Color(0xFFEDE7F6),
      'value': 2,
    },
    {
      'label': 'Okay',
      'icon': Icons.sentiment_neutral_rounded,
      'color': const Color(0xFF42A5F5),
      'bgColor': const Color(0xFFE3F2FD),
      'value': 3,
    },
    {
      'label': 'Good',
      'icon': Icons.sentiment_satisfied_rounded,
      'color': const Color(0xFF26A69A),
      'bgColor': const Color(0xFFE0F2F1),
      'value': 4,
    },
    {
      'label': 'Great',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': const Color(0xFF66BB6A),
      'bgColor': const Color(0xFFE8F5E9),
      'value': 5,
    },
  ];

  @override
  void initState() {
    super.initState();
    // --- THE EDIT FIX: Load existing data if editing ---
    if (widget.initialMood != null) {
      _selectedIndex = _moods.indexWhere(
        (m) => m['value'] == widget.initialMood,
      );
      if (_selectedIndex == -1) _selectedIndex = 2; // Fallback
      _noteController.text = widget.initialNote ?? "";
    }
  }

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final moodVal = _moods[_selectedIndex]['value'];
      final noteVal = _noteController.text.trim();

      // --- THE FIX: UPDATE vs ADD ---
      if (widget.docId != null) {
        // 1. We are EDITING an existing log
        await FirebaseFirestore.instance
            .collection('mood_logs')
            .doc(widget.docId) // Use the specific ID passed from Analytics
            .update({
              'moodValue': moodVal,
              'note': noteVal,
              'last_edited':
                  FieldValue.serverTimestamp(), // Track when it was changed
            });
      } else {
        // 2. We are ADDING a new log (Your original code)
        await FirebaseFirestore.instance.collection('mood_logs').add({
          'uid': user.uid,
          'moodValue': moodVal,
          'note': noteVal,
          'timestamp': FieldValue.serverTimestamp(),
          'date': today,
        });

        // 3. Handle Streak (Only runs for NEW logs, not edits!)
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final userDoc = await userRef.get();

        if (!userDoc.exists) {
          await userRef.set({
            'streak': 1,
            'last_logged_date': today,
            'email': user.email,
          });
        } else {
          final data = userDoc.data() as Map<String, dynamic>;
          String lastDate = data['last_logged_date'] ?? "";

          if (lastDate != today) {
            DateTime lastDateTime =
                lastDate.isEmpty
                    ? DateTime.now().subtract(const Duration(days: 2))
                    : DateFormat('yyyy-MM-dd').parse(lastDate);
            int diff = DateTime.now().difference(lastDateTime).inDays;

            if (diff == 1) {
              await userRef.update({
                'streak': FieldValue.increment(1),
                'last_logged_date': today,
              });
            } else {
              await userRef.update({'streak': 1, 'last_logged_date': today});
            }
          }
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              "Mood updated successfully!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E5646),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 180,
          left: 24,
          right: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBgColor = _moods[_selectedIndex]['bgColor'] as Color;
    final currentIconColor = _moods[_selectedIndex]['color'] as Color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: currentBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.docId == null ? "Today I feel" : "Editing Entry",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Icon(
            _moods[_selectedIndex]['icon'],
            color: currentIconColor,
            size: 85,
          ),
          const SizedBox(height: 12),
          Text(
            _moods[_selectedIndex]['label'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // MOOD SLIDER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_moods.length, (index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Icon(
                    _moods[index]['icon'],
                    color:
                        isSelected
                            ? _moods[index]['color']
                            : Colors.black.withOpacity(0.2),
                    size: isSelected ? 32 : 26,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: "Add details...",
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveMood,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5646),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child:
                  _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        widget.docId == null ? "Save Entry" : "Update Entry",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
