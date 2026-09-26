import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/qurity_app_bar.dart';

/// 🎨 لوحة التلوين الحرة — رسم باللمس بألوان وسماكات متعددة مع تراجع ومسح.
class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _Stroke {
  _Stroke({required this.color, required this.width});
  final Color color;
  final double width;
  final List<Offset> points = [];
}

class _ColoringScreenState extends State<ColoringScreen> {
  static const List<Color> _palette = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFF9A825),
    Color(0xFF43A047),
    Color(0xFF00897B),
    Color(0xFF1E88E5),
    Color(0xFF5E35B1),
    Color(0xFFD81B60),
    Color(0xFF6F4E37),
    Color(0xFF212121),
  ];
  static const List<double> _sizes = [6, 14, 26];

  final List<_Stroke> _strokes = [];
  _Stroke? _current;
  Color _color = _palette[5];
  double _size = _sizes[1];

  void _onPanStart(Offset p) {
    setState(() {
      _current = _Stroke(color: _color, width: _size)..points.add(p);
    });
  }

  void _onPanUpdate(Offset p) {
    setState(() => _current?.points.add(p));
  }

  void _onPanEnd() {
    setState(() {
      if (_current != null) _strokes.add(_current!);
      _current = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: QurityAppBar(
        title: 'لوحة التلوين',
        color: const Color(0xFFD81B60),
        actions: [
          IconButton(
            tooltip: 'تراجع',
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(() => _strokes.removeLast()),
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'مسح اللوحة',
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(() {
                      _strokes.clear();
                      _current = null;
                    }),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                for (final size in _sizes)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _SizeDot(
                      size: size,
                      color: _color,
                      selected: _size == size,
                      onTap: () => setState(() => _size = size),
                    ),
                  ),
                const Spacer(),
                Text('ارسم بإصبعك ✏️',
                    style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.brown.shade400)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD7CCC8)),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  key: const ValueKey('coloring-canvas'),
                  onPanStart: (d) => _onPanStart(d.localPosition),
                  onPanUpdate: (d) => _onPanUpdate(d.localPosition),
                  onPanEnd: (_) => _onPanEnd(),
                  child: CustomPaint(
                    painter: _StrokePainter(
                        strokes: _strokes, current: _current),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
              itemCount: _palette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _ColorDot(
                color: _palette[i],
                selected: _color == _palette[i],
                onTap: () => setState(() => _color = _palette[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({required this.strokes, this.current});
  final List<_Stroke> strokes;
  final _Stroke? current;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [...strokes, if (current != null) current!]) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2,
            paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(
      {required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 44 : 36,
        height: selected ? 44 : 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? Colors.white : Colors.transparent, width: 3),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: selected ? 10 : 4,
                offset: const Offset(0, 3)),
          ],
        ),
      ),
    );
  }
}

class _SizeDot extends StatelessWidget {
  const _SizeDot(
      {required this.size,
      required this.color,
      required this.selected,
      required this.onTap});
  final double size;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? color : const Color(0xFFD7CCC8), width: 2),
        ),
        child: Center(
          child: Container(
            width: size.clamp(6.0, 26.0),
            height: size.clamp(6.0, 26.0),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
