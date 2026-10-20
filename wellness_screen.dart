import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';
import 'dart:async';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? "DemoStudent";
  int _latestMood = 3;
  bool _isLoadingMood = true;

  // Add a StreamSubscription variable to avoid memory leaks
  StreamSubscription<QuerySnapshot>? _moodSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLatestMood();
  }

  @override
  void dispose() {
    // Always cancel listeners when the widget is destroyed
    _moodSubscription?.cancel();
    super.dispose();
  }

  void _listenToLatestMood() {
    // Using .snapshots() instead of .get() creates a live, real-time connection
    _moodSubscription = _firestore
        .collection('mood_logs')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final docs = snapshot.docs.toList();

              // Sort by timestamp descending to get the newest mood log
              docs.sort((a, b) {
                final aTime = a.data()['timestamp'] as Timestamp?;
                final bTime = b.data()['timestamp'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              if (mounted) {
                setState(() {
                  _latestMood = docs.first.data()['moodValue'] as int? ?? 3;
                  _isLoadingMood = false;
                });
              }
            } else {
              if (mounted) {
                setState(() => _isLoadingMood = false);
              }
            }
          },
          onError: (error) {
            print("Error listening to mood updates: $error");
            if (mounted) {
              setState(() => _isLoadingMood = false);
            }
          },
        );
  }

  // --- THE SMART ALGORITHM LOGIC ---
  Map<String, dynamic> _getRecommendation() {
    if (_latestMood <= 2) {
      return {
        'title': "Take a breather.",
        'message':
            "You've been feeling overwhelmed. Here is a gentle, low-effort activity to help you reset.",
        'targetEffort': 'low', // Matches your Firebase value exactly!
        'bgColor': const Color(0xFFE3F2FD),
        'iconColor': Colors.blue.shade700,
        'icon': Icons.water_drop_rounded,
      };
    } else if (_latestMood == 3) {
      return {
        'title': "Maintain your balance.",
        'message':
            "You're doing okay! Here is a medium-effort activity to keep you centered and engaged.",
        'targetEffort': 'medium', // Matches your Firebase value exactly!
        'bgColor': const Color(0xFFE8F5E9),
        'iconColor': Colors.teal.shade700,
        'icon': Icons.self_improvement_rounded,
      };
    } else {
      return {
        'title': "Keep the momentum going!",
        'message':
            "You've been feeling great! Use this energy for a high-effort activity.",
        'targetEffort': 'high', // Matches your Firebase value exactly!
        'bgColor': const Color(0xFFFFF3E0),
        'iconColor': Colors.orange.shade700,
        'icon': Icons.wb_sunny_rounded,
      };
    }
  }

  // --- DYNAMIC EFFORT COLORS & ICONS ---
  Map<String, dynamic> _getEffortStyle(String effort) {
    // This strips out the word "effort" just in case you typed it in Firebase
    switch (effort.toLowerCase().replaceAll(' effort', '').trim()) {
      case 'low':
        return {
          'bg': const Color(0xFFE0F2F1),
          'text': Colors.teal.shade800,
          'iconColor': Colors.teal,
          'iconData': Icons.cleaning_services_rounded, // <-- BROOM ICON
        };
      case 'medium':
        return {
          'bg': const Color(0xFFEDE7F6),
          'text': Colors.deepPurple.shade800,
          'iconColor': Colors.deepPurple,
          'iconData': Icons.local_cafe_rounded, // <-- CAFE ICON
        };
      case 'high':
        return {
          'bg': const Color(0xFFFFF8E1),
          'text': Colors.orange.shade800,
          'iconColor': Colors.orange,
          'iconData': Icons.directions_walk_rounded, // <-- WALK ICON
        };
      default:
        return {
          'bg': Colors.grey.shade200,
          'text': Colors.black87,
          'iconColor': Colors.grey.shade700,
          'iconData': Icons.spa_rounded, // Fallback icon
        };
    }
  }

  // Helper widget to build the beautiful STATIC cards
  Widget _buildActivityCard(
    Map<String, dynamic> data,
    String title,
    String location,
    String duration,
    String desc,
    String effort,
    Map<String, dynamic> style,
  ) {
    String displayTag = effort.toUpperCase();
    if (!displayTag.contains('EFFORT')) {
      displayTag = "$displayTag EFFORT";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: style['bg'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.spa_rounded, color: style['icon']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$location • $duration",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: style['bg'],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              displayTag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: style['text'],
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _getRecommendation();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('wellness_activities').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _isLoadingMood) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "Add the UNIMAS activities to Firebase!",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            final targetEffort = recommendation['targetEffort'] as String;

            // Find ONE activity that matches the target effort level
            final matchingDocs =
                docs.where((doc) {
                  // WE NOW SEARCH FOR 'effort' INSTEAD OF 'category'!
                  final eff =
                      (doc.data() as Map<String, dynamic>)['effort']
                          as String? ??
                      '';
                  return eff.toLowerCase().trim() == targetEffort.toLowerCase();
                }).toList();

            final featuredDoc =
                matchingDocs.isNotEmpty ? matchingDocs.first : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- THE SMART FEATURED BANNER ---
                  Container(
                    margin: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: recommendation['bgColor'],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                recommendation['icon'],
                                size: 28,
                                color: recommendation['iconColor'],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recommendation['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: recommendation['iconColor'],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    recommendation['message'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // INJECT THE ACTUAL SUGGESTED ACTIVITY
                        if (featuredDoc != null) ...[
                          const SizedBox(height: 20),
                          _buildActivityCard(
                            featuredDoc.data() as Map<String, dynamic>,
                            featuredDoc['title'] ?? 'Activity',
                            featuredDoc['location'] ?? 'Campus',
                            featuredDoc['duration'] ?? '10 mins',
                            featuredDoc['description'] ?? '',
                            featuredDoc['effort'] ??
                                targetEffort, // Reading effort!
                            _getEffortStyle(targetEffort),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      "All Activities",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // --- LIST ALL OTHER ACTIVITIES ---
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      if (featuredDoc != null &&
                          docs[index].id == featuredDoc.id) {
                        return const SizedBox.shrink();
                      }

                      final data = docs[index].data() as Map<String, dynamic>;
                      // WE NOW READ 'effort' INSTEAD OF 'category'!
                      final effort = data['effort'] ?? 'low';

                      return _buildActivityCard(
                        data,
                        data['title'] ?? 'Activity',
                        data['location'] ?? 'Anywhere',
                        data['duration'] ?? '5 mins',
                        data['description'] ?? '',
                        effort,
                        _getEffortStyle(effort),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
