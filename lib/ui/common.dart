import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../domain/models.dart';

const forest = Color(0xFF174E43);
const ink = Color(0xFF193730);
const muted = Color(0xFF789087);
const cream = Color(0xFFF7F8F4);
const peach = Color(0xFFE9855F);
const paleGreen = Color(0xFFE9F2EB);

Color statusColor(PointStatus value) => switch (value) {
  PointStatus.supplied => const Color(0xFF3E9B6D),
  PointStatus.needsWater => const Color(0xFF478FBD),
  PointStatus.needsFood => const Color(0xFFE78555),
  PointStatus.attention => const Color(0xFFD19B34),
  PointStatus.inactive => Colors.grey,
};
IconData resourceIcon(Resource value) => switch (value) {
  Resource.water => Icons.water_drop_rounded,
  Resource.food => Icons.restaurant_rounded,
  Resource.shelter => Icons.home_rounded,
  Resource.other => Icons.more_horiz_rounded,
};
String relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 2) return 'agora';
  if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'há ${diff.inHours} h';
  return 'há ${diff.inDays} d';
}

String distanceLabel(LatLng from, LatLng to) {
  final km = const Distance().as(LengthUnit.Kilometer, from, to);
  return km < 1
      ? '${(km * 1000).round()} m'
      : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

Widget photo({
  String? url,
  Uint8List? bytes,
  double? width,
  double? height,
  BorderRadius? radius,
  IconData fallback = Icons.pets_rounded,
}) {
  Widget child;
  if (bytes != null) {
    child = Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: width,
      height: height,
    );
  } else if (url != null) {
    child = Image.network(
      url,
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) =>
          _photoFallback(width, height, fallback),
    );
  } else {
    child = _photoFallback(width, height, fallback);
  }
  return ClipRRect(
    borderRadius: radius ?? BorderRadius.circular(16),
    child: child,
  );
}

Widget _photoFallback(double? width, double? height, IconData icon) =>
    Container(
      width: width,
      height: height,
      color: paleGreen,
      child: Icon(icon, color: forest, size: 34),
    );

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.compact = false});
  final PointStatus status;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
