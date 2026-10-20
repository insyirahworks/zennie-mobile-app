import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'mood_sheet.dart';

// Custom painter that draws a filled circle with a thin face — seamless mood dot
class MoodDotPainter extends FlDotPainter {
  final int moodValue;
  static const double _radius = 14.0;

  MoodDotPainter(this.moodValue);

  Color get _fillColor {
    switch (moodValue) {
      case 1:
        return const Color(0xFF9E9E9E);
      case 2:
        return const Color(0xFF9575CD);
      case 3:
        return const Color(0xFF64B5F6);
      case 4:
        return const Color(0xFF4DB6AC);
      case 5:
        return const Color(0xFF81C784);
      default:
        return const Color(0xFFB0BEC5);
    }
  }

  void _drawFace(Canvas canvas, Offset center) {
    final r = _radius;
    final facePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;

    // Left eye
    canvas.drawCircle(
      Offset(center.dx - r * 0.3, center.dy - r * 0.2),
      r * 0.1,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );
    // Right eye
    canvas.drawCircle(
      Offset(center.dx + r * 0.3, center.dy - r * 0.2),
      r * 0.1,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    switch (moodValue) {
      case 5:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + r * 0.05),
            width: r * 1.0,
            height: r * 0.7,
          ),
          0.3,
          2.5,
          false,
          facePaint,
        );
        break;
      case 4:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + r * 0.1),
            width: r * 0.9,
            height: r * 0.5,
          ),
          0.3,
          2.5,
          false,
          facePaint,
        );
        break;
      case 3:
        canvas.drawLine(
          Offset(center.dx - r * 0.3, center.dy + r * 0.25),
          Offset(center.dx + r * 0.3, center.dy + r * 0.25),
          facePaint,
        );
        break;
      case 2:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + r * 0.55),
            width: r * 0.9,
            height: r * 0.5,
          ),
          3.45,
          2.5,
          false,
          facePaint,
        );
        break;
      case 1:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + r * 0.65),
            width: r * 1.0,
            height: r * 0.7,
          ),
          3.45,
          2.5,
          false,
          facePaint,
        );
        break;
    }
  }

  @override
  void draw(Canvas canvas, FlSpot spot, Offset center) {
    final paint =
        Paint()
          ..color = _fillColor
          ..style = PaintingStyle.fill;

    // CHANGED 1: Border ring matches the specific mood's fill color
    final borderPaint =
        Paint()
          ..color = _fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

    canvas.drawCircle(center, _radius, paint);
    canvas.drawCircle(center, _radius, borderPaint);
    _drawFace(canvas, center);
  }

  @override
  Size getSize(FlSpot spot) => const Size(_radius * 2, _radius * 2);

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => b;

  @override
  Color get mainColor => _fillColor;

  @override
  List<Object?> get props => [moodValue];
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool isWeekly = true;
  DateTime _selectedDate = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser?.uid ?? "";

  String _dateKey(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  void _changePeriod(int direction) {
    setState(() {
      if (isWeekly) {
        _selectedDate = _selectedDate.add(Duration(days: direction * 7));
      } else {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + direction,
          1,
        );
      }
    });
  }

  String get _dateRangeText {
    if (isWeekly) {
      final startOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return "${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}";
    } else {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  IconData _getMoodIcon(int value) {
    switch (value) {
      case 1:
        return Icons.sentiment_very_dissatisfied_rounded;
      case 2:
        return Icons.sentiment_dissatisfied_rounded;
      case 3:
        return Icons.sentiment_neutral_rounded;
      case 4:
        return Icons.sentiment_satisfied_rounded;
      case 5:
        return Icons.sentiment_very_satisfied_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getMoodColor(int value) {
    switch (value) {
      case 1:
        return const Color(0xFF9E9E9E); // pastel grey
      case 2:
        return const Color(0xFFB39DDB); // pastel purple
      case 3:
        return const Color(0xFF90CAF9); // pastel blue
      case 4:
        return const Color(0xFF80CBC4); // pastel teal
      case 5:
        return const Color(0xFFA5D6A7); // pastel green
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _getMoodCardColor(int value) {
    switch (value) {
      case 1:
        return const Color(0xFFF5F5F5);
      case 2:
        return const Color(0xFFEDE7F6);
      case 3:
        return const Color(0xFFE3F2FD);
      case 4:
        return const Color(0xFFE0F2F1);
      case 5:
        return const Color(0xFFE8F5E9);
      default:
        return Colors.white;
    }
  }

  Future<void> _confirmDelete(BuildContext context, String documentId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Delete Log?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Are you sure you want to delete this mood log? This cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _firestore.collection('mood_logs').doc(documentId).delete();
    }
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (value.toInt() >= 0 && value.toInt() < days.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 8,
        child: Text(
          days[value.toInt()],
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container();
  }

  List<FlSpot> _processDataForWeek(List<QueryDocumentSnapshot> docs) {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = start.add(const Duration(days: 7));

    Map<int, Map<String, dynamic>> latestMoodPerDay = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['timestamp'] == null) continue;
      DateTime date = (data['timestamp'] as Timestamp).toDate();

      if (date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end)) {
        int dayIndex = date.weekday - 1;
        if (!latestMoodPerDay.containsKey(dayIndex) ||
            date.isAfter(
              (latestMoodPerDay[dayIndex]!['timestamp'] as Timestamp).toDate(),
            )) {
          latestMoodPerDay[dayIndex] = data;
        }
      }
    }

    List<FlSpot> spots = [];
    latestMoodPerDay.forEach((dayIndex, data) {
      spots.add(
        FlSpot(dayIndex.toDouble(), (data['moodValue'] as int).toDouble()),
      );
    });
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  Widget _buildWeeklyChartWithEmoji(List<FlSpot> spots) {
    // CHANGED 2: Generate dynamic gradient colors and stops based on spots
    List<Color> lineColors = [];
    List<double> lineStops = [];

    if (spots.isEmpty) {
      lineColors = [Colors.teal, Colors.teal];
      lineStops = [0.0, 1.0];
    } else if (spots.length == 1) {
      lineColors = [
        _getMoodColor(spots.first.y.toInt()),
        _getMoodColor(spots.first.y.toInt()),
      ];
      lineStops = [0.0, 1.0];
    } else {
      for (var spot in spots) {
        lineColors.add(_getMoodColor(spot.y.toInt()));
        // Map X value (0 to 6) to a percentage (0.0 to 1.0) for smooth gradient flow
        lineStops.add(spot.x / 6.0);
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine:
              (value) => FlLine(
                color: Colors.teal.withValues(alpha: 0.06),
                strokeWidth: 1,
              ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: bottomTitleWidgets,
              reservedSize: 30,
              interval: 1,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0.5,
        maxY: 5.5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: lineColors, stops: lineStops),
            barWidth: 4,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return MoodDotPainter(spot.y.toInt());
              },
              checkToShowDot: (spot, barData) => true,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF8DE4D3).withValues(alpha: 0.25),
                  const Color(0xFF8DE4D3).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(enabled: false),
      ),
    );
  }

  Widget _buildWeeklyChartFull(List<FlSpot> spots) {
    return SizedBox(height: 280, child: _buildWeeklyChartWithEmoji(spots));
  }

  Widget _buildMonthlyHeatmap(List<QueryDocumentSnapshot> docs) {
    Map<String, int> dailyMoods = {};
    Map<String, DateTime> latestTimes = {};

    for (var d in docs) {
      if (d['timestamp'] != null) {
        final data = d.data() as Map<String, dynamic>;
        DateTime date = (data['timestamp'] as Timestamp).toDate();
        String key = _dateKey(date);
        if (!latestTimes.containsKey(key) || date.isAfter(latestTimes[key]!)) {
          latestTimes[key] = date;
          dailyMoods[key] = data['moodValue'];
        }
      }
    }

    int daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    int paddingDays =
        DateTime(_selectedDate.year, _selectedDate.month, 1).weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map(
                    (d) => Text(
                      d,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: daysInMonth + paddingDays,
          itemBuilder: (context, index) {
            if (index < paddingDays) return const SizedBox.shrink();
            int day = index - paddingDays + 1;
            String key = _dateKey(
              DateTime(_selectedDate.year, _selectedDate.month, day),
            );
            int? mood = dailyMoods[key];
            return Container(
              decoration: BoxDecoration(
                color:
                    mood != null
                        ? _getMoodColor(mood).withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child:
                    mood != null
                        ? Icon(
                          _getMoodIcon(mood),
                          color: _getMoodColor(mood),
                          size: 18,
                        )
                        : Text(
                          day.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black38,
                          ),
                        ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Insights",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4F1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _buildTab("Weekly", isWeekly),
                    _buildTab("Monthly", !isWeekly),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changePeriod(-1),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    _dateRangeText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changePeriod(1),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('mood_logs')
                          .where('uid', isEqualTo: _uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    final spots = _processDataForWeek(docs);

                    if (isWeekly) {
                      return _buildWeeklyChartFull(spots);
                    } else {
                      return _buildMonthlyHeatmap(docs);
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                "Recent Logs",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 16),

              StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('mood_logs')
                        .where('uid', isEqualTo: _uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text("No recent logs found. 🍃"),
                    );
                  }

                  final allDocs = snapshot.data!.docs.toList();
                  List<QueryDocumentSnapshot> filteredDocs = [];

                  // CHANGED 3: Filter recent logs based on the current chart view bounds
                  if (isWeekly) {
                    final startOfWeek = _selectedDate.subtract(
                      Duration(days: _selectedDate.weekday - 1),
                    );
                    final start = DateTime(
                      startOfWeek.year,
                      startOfWeek.month,
                      startOfWeek.day,
                    );
                    final end = start.add(const Duration(days: 7));

                    filteredDocs =
                        allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['timestamp'] == null) return false;
                          DateTime date =
                              (data['timestamp'] as Timestamp).toDate();
                          return date.isAfter(
                                start.subtract(const Duration(seconds: 1)),
                              ) &&
                              date.isBefore(end);
                        }).toList();
                  } else {
                    final startOfMonth = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      1,
                    );
                    final endOfMonth = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      1,
                    );

                    filteredDocs =
                        allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['timestamp'] == null) return false;
                          DateTime date =
                              (data['timestamp'] as Timestamp).toDate();
                          return date.isAfter(
                                startOfMonth.subtract(
                                  const Duration(seconds: 1),
                                ),
                              ) &&
                              date.isBefore(endOfMonth);
                        }).toList();
                  }

                  if (filteredDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text("No logs recorded during this period. 🍃"),
                    );
                  }

                  // Sort the filtered logs sequentially by newest first
                  filteredDocs.sort((a, b) {
                    Timestamp? t1 =
                        (a.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    Timestamp? t2 =
                        (b.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    if (t1 == null || t2 == null) return 0;
                    return t2.compareTo(t1);
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        filteredDocs.length > 10 ? 10 : filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      final mood = data['moodValue'] ?? 3;
                      final note = data['note'] ?? "";
                      final docId = filteredDocs[index].id;
                      final ts = data['timestamp'] as Timestamp?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _getMoodCardColor(mood),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getMoodColor(
                                mood,
                              ).withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _getMoodColor(
                              mood,
                            ).withValues(alpha: 0.15),
                            child: Icon(
                              _getMoodIcon(mood),
                              color: _getMoodColor(mood),
                            ),
                          ),
                          title: Text(
                            note.toString().trim().isEmpty ? "No Note" : note,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  note.toString().trim().isEmpty
                                      ? Colors.grey
                                      : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            ts != null
                                ? DateFormat(
                                  'MMM d, h:mm a',
                                ).format(ts.toDate())
                                : "Just now",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.teal,
                                  size: 20,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (context) => MoodSheet(
                                          docId: docId,
                                          initialMood: mood,
                                          initialNote: note,
                                        ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _confirmDelete(context, docId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isWeekly = text == "Weekly"),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isActive
                        ? const Color(0xFF004D40)
                        : Colors.teal.shade700.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
