import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart'; // NEW
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? "DemoStudent";

  final TextEditingController _controller = TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;
  String _systemPrompt = "";

  @override
  void initState() {
    super.initState();
    _setupAIContext();
  }

  Future<void> _setupAIContext() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final realName = userDoc.data()?['name'] ?? 'Student';

      String promptBuilder =
          "You are ZENnie, a compassionate student wellbeing AI for UNIMAS students. You are talking to $realName. Always reply in English, even if the user uses slang. Keep your answers brief, friendly, and conversational.";

      final snapshot =
          await _firestore
              .collection('mood_logs')
              .where('uid', isEqualTo: _uid)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = a.data()['timestamp'] as Timestamp?;
          final bTime = b.data()['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        final latestData = docs.first.data();
        final moodValue = latestData['moodValue'] as int;
        final note = latestData['note'] as String? ?? 'No note';

        promptBuilder +=
            " The user's mood today is $moodValue/5. Note: '$note'.";
      }

      setState(() {
        _systemPrompt = promptBuilder;
      });
    } catch (e) {
      print("Context fetch failed: $e");
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _saveMessageToFirestore(String role, String text) async {
    try {
      await _firestore.collection('chat_logs').add({
        'uid': _uid,
        'role': role,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving message: $e");
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    _controller.clear();

    setState(() => _isLoading = true);
    await _saveMessageToFirestore('user', userMessage);

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data['choices'][0]['message']['content'];
        await _saveMessageToFirestore('bot', botReply);
      } else {
        print("Groq Error: ${response.body}");
        _useBackupBrain(userMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("AI Connection Error!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      _useBackupBrain(userMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _useBackupBrain(String userText) {
    String reply = "I'm listening. Tell me more.";
    String lowerText = userText.toLowerCase();

    if (lowerText.contains("tired")) {
      reply = "Rest is important. Maybe take a 15-minute nap?";
    } else if (lowerText.contains("sad")) {
      reply = "I'm sorry you feel that way. Be gentle with yourself today.";
    } else if (lowerText.contains("stress")) {
      reply =
          "Deep breaths. You have handled challenges before, you can handle this.";
    } else if (lowerText.contains("happy")) {
      reply = "That's amazing! Hold onto that feeling.";
    }

    _saveMessageToFirestore('bot', "$reply (Offline Mode)");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F4F1), Color(0xFFB5EADF), Color(0xFF8DE4D3)],
          ),
        ),
        child:
            _isInitializing
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
                : Column(
                  children: [
                    // --- HEADER ---
                    Container(
                      padding: const EdgeInsets.only(
                        top: 60,
                        bottom: 20,
                        left: 24,
                        right: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8DE4D3), Color(0xFFB5EADF)],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade700.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.teal,
                                  size: 28,
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ZENnie",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Your AI Wellbeing Companion",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.teal.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- CHAT LIST ---
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            _firestore
                                .collection('chat_logs')
                                .where('uid', isEqualTo: _uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final sortedDocs = docs.toList();
                          sortedDocs.sort((a, b) {
                            final aTime =
                                (a.data() as Map<String, dynamic>)['timestamp']
                                    as Timestamp?;
                            final bTime =
                                (b.data() as Map<String, dynamic>)['timestamp']
                                    as Timestamp?;
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return aTime.compareTo(bTime);
                          });

                          if (sortedDocs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.waving_hand_rounded,
                                    size: 48,
                                    color: Colors.teal.shade700.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Say hello to ZENnie!",
                                    style: TextStyle(
                                      color: Colors.teal.shade900,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "She knows how you're feeling today.",
                                    style: TextStyle(
                                      color: Colors.teal.shade800.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(20),
                            itemCount: sortedDocs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  sortedDocs.reversed.toList()[index].data()
                                      as Map<String, dynamic>;
                              final isUser = data['role'] == 'user';
                              final text = data['text'] ?? '';

                              return Align(
                                alignment:
                                    isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isUser
                                            ? const Color(0xFF52B69A)
                                            : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft:
                                          isUser
                                              ? const Radius.circular(20)
                                              : const Radius.circular(4),
                                      bottomRight:
                                          isUser
                                              ? const Radius.circular(4)
                                              : const Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      if (!isUser)
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  // CHANGED: use MarkdownBody for bot, Text for user
                                  child:
                                      isUser
                                          ? Text(
                                            text,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              height: 1.4,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                          : MarkdownBody(
                                            data: text,
                                            styleSheet: MarkdownStyleSheet(
                                              p: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 15,
                                                height: 1.4,
                                              ),
                                              strong: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              listBullet: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // --- TYPING INDICATOR ---
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "ZENnie is typing...",
                                style: TextStyle(
                                  color: Colors.teal.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // --- INPUT BOX ---
                    Container(
                      padding: const EdgeInsets.only(
                        top: 12,
                        left: 20,
                        right: 20,
                        bottom: 120,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (value) => sendMessage(value),
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => sendMessage(_controller.text),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00796B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
