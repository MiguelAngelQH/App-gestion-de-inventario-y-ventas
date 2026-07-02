import 'package:flutter/material.dart';
import 'package:smart_ventas/services/connectivity_service.dart';

class ConnectivityIndicator extends StatefulWidget {
  final ConnectivityService service;

  const ConnectivityIndicator({super.key, required this.service});

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.service.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.service.isOnline;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        avatar: Icon(
          online ? Icons.cloud_done : Icons.cloud_off,
          size: 14,
          color: online ? const Color(0xFF43A047) : const Color(0xFFE53935),
        ),
        label: Text(
          online ? 'En línea' : 'Sin conexión',
          style: TextStyle(
            fontSize: 11,
            color: online ? const Color(0xFF43A047) : const Color(0xFFE53935),
          ),
        ),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: online
            ? const Color(0xFF43A047).withValues(alpha: 0.1)
            : const Color(0xFFE53935).withValues(alpha: 0.1),
        side: BorderSide.none,
      ),
    );
  }
}
