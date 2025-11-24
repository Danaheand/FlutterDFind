import 'package:flutter/material.dart';
import '../services/web_notification_service.dart';
import '../theme/app_theme.dart';

/// Widget que maneja notificaciones visuales en web
class WebNotificationOverlay extends StatefulWidget {
  final Widget child;

  const WebNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<WebNotificationOverlay> createState() => _WebNotificationOverlayState();
}

class _WebNotificationOverlayState extends State<WebNotificationOverlay>
    with TickerProviderStateMixin {
  late WebNotificationService _notificationService;
  OverlayEntry? _currentNotificationEntry;
  AnimationController? _controller;
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();
    _notificationService = WebNotificationService();

    // Inicializar el servicio de notificaciones web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize(
        onNotification: _showNotification,
      );
    });
  }

  @override
  void dispose() {
    _notificationService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _showNotification(String title, String body) {
    if (!mounted) return;

    // Cancelar notificación anterior si existe
    _currentNotificationEntry?.remove();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 80,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _animation!,
            child: GestureDetector(
              onTap: () {
                _dismissNotification(entry);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withOpacity(0.6),
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentNotificationEntry = entry;
    Overlay.of(context).insert(entry);

    _controller!.forward();

    // Auto-dismissar después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _currentNotificationEntry == entry) {
        _dismissNotification(entry);
      }
    });
  }

  void _dismissNotification(OverlayEntry entry) {
    if (_controller != null && mounted) {
      _controller!.reverse().then((_) {
        if (mounted && _currentNotificationEntry == entry) {
          entry.remove();
          _currentNotificationEntry = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
