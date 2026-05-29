import 'package:flutter/material.dart';

class AssetCard extends StatelessWidget {
  final String name;
  final double originalPrice;
  final int daysUsed;
  final double dailyCost;
  final double progressPercent; // 0.0 - 100.0
  final int? remainingDays;
  final bool hasGoal;
  final String status; // "服役中" / "已退役" / "已出售"
  final bool isActive;
  final Widget imageWidget;

  const AssetCard({
    super.key,
    required this.name,
    required this.originalPrice,
    required this.daysUsed,
    required this.dailyCost,
    required this.progressPercent,
    required this.remainingDays,
    this.hasGoal = true,
    required this.status,
    required this.isActive,
    required this.imageWidget,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withAlpha(
              colors.brightness == Brightness.dark ? 70 : 10,
            ),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Top: image + status badge ----
          _TopSection(context),
          const SizedBox(height: 12),
          // ---- Middle: name + meta ----
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${_fmtInt(originalPrice)}  |  已使用 $daysUsed 天',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          // ---- Bottom: daily cost + progress ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥${dailyCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '/天',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(percent: progressPercent, remainingDays: remainingDays, hasGoal: hasGoal),
        ],
      ),
    );
  }

  Widget _TopSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageWidget,
        ),
        _StatusBadge(isActive: isActive, label: status),
      ],
    );
  }

  String _fmtInt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

// ============================================================
// Status Badge
// ============================================================

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final String label;
  const _StatusBadge({required this.isActive, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFBCE038).withAlpha(30)
            : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFBCE038) : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? (colors.brightness == Brightness.dark
                        ? const Color(0xFFDDFB78)
                        : const Color(0xFF4A5A00))
                  : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Custom Progress Bar with Triangle Indicator
// ============================================================

class _ProgressBar extends StatelessWidget {
  final double percent; // 0-100
  final int? remainingDays;
  final bool hasGoal;
  const _ProgressBar({required this.percent, this.remainingDays, this.hasGoal = true});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clamped = percent.clamp(0.0, 100.0) / 100.0;
    final noGoal = !hasGoal;
    final isGoal = hasGoal && (remainingDays == null || remainingDays! <= 0);

    return Column(
      children: [
        if (hasGoal) SizedBox(
          height: 20, // 给三角留空间（三角高度 ~6px + 间距）
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth;
              final barH = 6.0;
              final triX = (barW * clamped).clamp(4.0, barW - 4.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track
                  Positioned(
                    top: 8.0, // 三角在上方 8px，bar 在下方
                    left: 0,
                    right: 0,
                    child: Container(
                      height: barH,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(barH / 2),
                      ),
                    ),
                  ),
                  // Filled
                  Positioned(
                    top: 8.0,
                    left: 0,
                    child: Container(
                      height: barH,
                      width: triX + 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBCE038),
                        borderRadius: BorderRadius.circular(barH / 2),
                      ),
                    ),
                  ),
                  // Triangle indicator (▼) — 随主题色
                  Positioned(
                    left: triX - 5,
                    top: 0,
                    child: CustomPaint(
                      size: const Size(10, 7),
                      painter: _TrianglePainter(color: colors.onSurface),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Align(
          child: Text(
            noGoal
                ? '无目标'
                : (isGoal ? '已达成目标' : '还剩 $remainingDays 天'),
            style: TextStyle(
              fontSize: 11,
              color: noGoal
                  ? colors.onSurfaceVariant
                  : (isGoal ? const Color(0xFFBCE038) : colors.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

/// 绘制向下的三角指示器 ▼ — 跟随主题色
class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // bottom center
      ..lineTo(0, 0) // top-left
      ..lineTo(size.width, 0) // top-right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
