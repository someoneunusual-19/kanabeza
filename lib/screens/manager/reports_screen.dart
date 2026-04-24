// lib/screens/manager/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Business Intelligence")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Revenue Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildRevenueChart(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildCategoryDistribution()),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickStats()),
            ],
          ),
        ],
      ),
    );
  }

  // --- Line Chart: Weekly Revenue ---
  Widget _buildRevenueChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 3),
                const FlSpot(2, 5),
                const FlSpot(4, 4),
                const FlSpot(6, 8),
              ],
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pie Chart: Sales by Category ---
  Widget _buildCategoryDistribution() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(color: Colors.indigoAccent, value: 40, title: '40%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            PieChartSectionData(color: Colors.blueGrey, value: 30, title: '30%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            PieChartSectionData(color: Colors.amberAccent, value: 30, title: '30%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        _miniCard("Profit", "+12%", Colors.blueAccent),
        const SizedBox(height: 12),
        _miniCard("Loss", "-2%", Colors.redAccent),
      ],
    );
  }

  Widget _miniCard(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}