import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../models/models.dart';

class ActionTimeline extends StatelessWidget {
  final List<ActionStep> steps;

  const ActionTimeline({Key? key, required this.steps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        connectorTheme: ConnectorThemeData(
          thickness: 3.0,
          color: Colors.cyanAccent.withOpacity(0.2),
        ),
        indicatorTheme: const IndicatorThemeData(
          size: 20.0,
        ),
      ),
      builder: TimelineTileBuilder.connected(
        indicatorBuilder: (context, index) {
          final step = steps[index];
          return DotIndicator(
            color: _getStatusColor(step.status),
            child: _getStatusIcon(step.status),
          );
        },
        connectorBuilder: (context, index, type) {
          return SolidLineConnector(color: _getStatusColor(steps[index].status).withOpacity(0.5));
        },
        contentsBuilder: (context, index) {
          final step = steps[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(step.status),
                  ),
                ),
                if (step.description != null)
                  Text(
                    step.description!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          );
        },
        itemCount: steps.length,
      ),
    );
  }

  Color _getStatusColor(ActionStatus status) {
    switch (status) {
      case ActionStatus.completed: return Colors.greenAccent;
      case ActionStatus.executing: return Colors.cyanAccent;
      case ActionStatus.retrying: return Colors.orangeAccent;
      case ActionStatus.recovered: return Colors.blueAccent;
      case ActionStatus.failed: return Colors.redAccent;
      case ActionStatus.rollback: return Colors.deepOrangeAccent;
      case ActionStatus.pending: return Colors.white24;
    }
  }

  Widget? _getStatusIcon(ActionStatus status) {
    if (status == ActionStatus.completed) return const Icon(Icons.check, size: 12, color: Colors.black);
    if (status == ActionStatus.executing) return const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black));
    if (status == ActionStatus.rollback) return const Icon(Icons.history, size: 12, color: Colors.black);
    return null;
  }
}
