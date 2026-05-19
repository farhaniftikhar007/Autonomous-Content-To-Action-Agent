import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MetricChart extends StatelessWidget {
  final List<double> dataPoints;
  final Color lineColor;

  const MetricChart({
    Key? key,
    required this.dataPoints,
    this.lineColor = Colors.cyanAccent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i]));
    }

    double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    if (minVal == maxVal) {
      minVal = minVal - 5.0;
      maxVal = maxVal + 5.0;
    }
    double padding = (maxVal - minVal) * 0.15;
    minVal = (minVal - padding).clamp(0.0, double.infinity);
    maxVal = maxVal + padding;

    return LineChart(
      LineChartData(
        minY: minVal,
        maxY: maxVal,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dataPoints.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "t-${dataPoints.length - 1 - index}",
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (value >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(1)}k';
                } else {
                  text = value.toStringAsFixed(0);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}
