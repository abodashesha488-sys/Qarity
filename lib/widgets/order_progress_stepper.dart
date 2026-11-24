import 'package:flutter/material.dart';

/// عنصر خطوة واحدة في مؤشر تتبع حالة الطلب.
@immutable
class OrderProgressStep {
  const OrderProgressStep({
    required this.label,
    required this.isDone,
  });

  final String label;
  final bool isDone;
}

/// مؤشر خطوات أفقي موحّد لتتبع مراحل تنفيذ الطلبات في «إشتريلي» و«إتسوقلي».
class OrderProgressStepper extends StatelessWidget {
  const OrderProgressStepper({
    super.key,
    required this.steps,
    this.activeColor = const Color(0xFF16A34A),
    this.nodeRadius = 11.5,
    this.dividerWidth = 20.0,
    this.fontSize = 9.2,
  });

  final List<OrderProgressStep> steps;
  final Color activeColor;
  final double nodeRadius;
  final double dividerWidth;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      children.add(
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: nodeRadius,
                backgroundColor:
                    step.isDone ? activeColor : Colors.grey.shade300,
                child: Icon(
                  step.isDone ? Icons.check : Icons.circle,
                  color: Colors.white,
                  size: nodeRadius + 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: step.isDone ? FontWeight.bold : FontWeight.normal,
                  color: step.isDone ? activeColor : Colors.grey,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
      if (i != steps.length - 1) {
        final nextDone = steps[i + 1].isDone;
        children.add(
          Container(
            width: dividerWidth,
            height: 2,
            margin: const EdgeInsets.only(bottom: 17),
            color: nextDone ? activeColor : Colors.grey.shade300,
          ),
        );
      }
    }
    return Row(children: children);
  }
}
