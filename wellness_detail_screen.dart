import 'package:flutter/material.dart';

class WellnessDetailScreen extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const WellnessDetailScreen({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Pulling the data passed from the Firebase card
    final desc = data['description'] ?? 'A quick activity to reset your mind.';
    final steps =
        data['steps'] ??
        'Take your time and follow the exercise at your own pace.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.teal.shade50,
                child: const Icon(
                  Icons.directions_walk,
                  size: 45,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Why do this?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "How to do it:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                steps,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            const Spacer(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
