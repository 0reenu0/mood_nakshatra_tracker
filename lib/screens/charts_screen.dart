import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/hive_init.dart';
import '../models/mood_entry.dart';

enum ChartPeriod { weekly, monthly, yearly }

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChartPeriod _selectedPeriod = ChartPeriod.weekly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedPeriod = ChartPeriod.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getStartDate(ChartPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ChartPeriod.weekly:
        return now.subtract(const Duration(days: 7));
      case ChartPeriod.monthly:
        return DateTime(now.year, now.month - 1, now.day);
      case ChartPeriod.yearly:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  List<MoodEntry> _getFilteredEntries() {
    final startDate = _getStartDate(_selectedPeriod);
    final allEntries = HiveInit.moodBox.values.toList();
    
    return allEntries
        .where((entry) => entry.date.isAfter(startDate) || 
                         entry.date.isAtSameMomentAs(startDate))
        .toList();
  }

  Map<String, Map<String, int>> _groupDataByNakshatraAndMood(
      List<MoodEntry> entries) {
    final Map<String, Map<String, int>> grouped = {};

    for (final entry in entries) {
      if (!grouped.containsKey(entry.nakshatra)) {
        grouped[entry.nakshatra] = {
          'angry': 0,
          'sad': 0,
          'happy': 0,
          'productive': 0,
        };
      }
      final moodCounts = grouped[entry.nakshatra]!;
      if (moodCounts.containsKey(entry.mood)) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
    }

    return grouped;
  }

  List<MapEntry<String, Map<String, int>>> _getTopNakshatras(
      Map<String, Map<String, int>> grouped, int n) {
    // Sort by total count (sum of all moods) and take top N
    final sorted = grouped.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value.values.reduce((sum, count) => sum + count);
        final bTotal = b.value.values.reduce((sum, count) => sum + count);
        return bTotal.compareTo(aTotal);
      });

    return sorted.take(n).toList();
  }


  Widget _buildChart() {
    final entries = _getFilteredEntries();
    
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No mood data available for this period',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupDataByNakshatraAndMood(entries);
    final topNakshatras = _getTopNakshatras(grouped, 9);

    if (topNakshatras.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    // Prepare data for fl_chart
    final barGroups = <BarChartGroupData>[];
    final nakshatraNames = <String>[];

    for (int i = 0; i < topNakshatras.length; i++) {
      final entry = topNakshatras[i];
      final nakshatra = entry.key;
      final counts = entry.value;

      nakshatraNames.add(nakshatra);

      // Create bars for each mood type (grouped side by side)
      final bars = <BarChartRodData>[
        BarChartRodData(
          toY: counts['angry']?.toDouble() ?? 0,
          color: Colors.red,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: counts['sad']?.toDouble() ?? 0,
          color: Colors.blue,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: counts['happy']?.toDouble() ?? 0,
          color: Colors.green,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: counts['productive']?.toDouble() ?? 0,
          color: Colors.purple,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: bars,
          groupVertically: false, // Group bars side by side
        ),
      );
    }

    // Calculate max Y value
    final maxY = grouped.values
        .expand((moods) => moods.values)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxYValue = (maxY * 1.2).ceil().toDouble(); // Add 20% padding

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: (topNakshatras.length * 60.0).clamp(400.0, double.infinity),
        height: 400,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxYValue > 0 ? maxYValue : 10,
            minY: 0,
            groupsSpace: 12,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.grey[800]!,
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final moods = ['angry', 'sad', 'happy', 'productive'];
                  final mood = moods[rodIndex];
                  final count = rod.toY.toInt();
                  return BarTooltipItem(
                    '$mood: $count',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < nakshatraNames.length) {
                      final name = nakshatraNames[value.toInt()];
                      // Truncate long names
                      final displayName = name.length > 8
                          ? '${name.substring(0, 8)}...'
                          : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() == value && value >= 0) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxYValue > 0 ? (maxYValue / 5) : 2,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey[300]!),
            ),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.red, 'Angry'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.blue, 'Sad'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.green, 'Happy'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.purple, 'Productive'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Charts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildLegend(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChart(),
                _buildChart(),
                _buildChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

