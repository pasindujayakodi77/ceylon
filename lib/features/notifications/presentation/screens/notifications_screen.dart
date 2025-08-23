import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/design_system/widgets/ceylon_app_bar.dart';
import 'package:ceylon/features/notifications/data/notifications_provider.dart';
import 'package:ceylon/features/notifications/data/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsProvider _notificationsProvider = NotificationsProvider();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    // No demo notifications are created
  }

  Future<void> _markAllAsRead() async {
    await _notificationsProvider.markAllAsRead();
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (!notification.isRead) {
      await _notificationsProvider.markAsRead(notification.id);
    }
  }

  Future<void> _deleteNotification(NotificationItem notification) async {
    await _notificationsProvider.deleteNotification(notification.id);
  }

  Future<void> _deleteAllNotifications() async {
    if (!mounted) return;

    // Show confirmation dialog
    final confirmDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Clear All Notifications'),
            content: const Text(
              'Are you sure you want to delete all notifications?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('DELETE ALL'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      await _notificationsProvider.deleteAllNotifications();

      // Check mounted again after async operation before using context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollListener(ScrollController scrollController) {
    // Show the FAB when scrolled down
    if (scrollController.offset > 100 && !_showFab) {
      setState(() {
        _showFab = true;
      });
    } else if (scrollController.offset < 100 && _showFab) {
      setState(() {
        _showFab = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ScrollController scrollController = ScrollController();

    // Add scroll listener
    scrollController.addListener(() => _scrollListener(scrollController));

    return StreamBuilder<List<NotificationItem>>(
      stream: _notificationsProvider.getNotifications(),
      builder: (context, snapshot) {
        // Show loading indicator while connecting
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: CeylonAppBar(title: 'Notifications'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Get the notifications
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: CeylonAppBar(
            title: 'Notifications',
            actions: [
              if (notifications.isNotEmpty)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    if (unreadCount > 0)
                      PopupMenuItem(
                        onTap: _markAllAsRead,
                        child: const Text('Mark all as read'),
                      ),
                    PopupMenuItem(
                      onTap: () => _deleteAllNotifications(),
                      child: const Text('Clear all notifications'),
                    ),
                  ],
                ),
            ],
          ),
          body: notifications.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: CeylonTokens.spacing16,
                  ),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(
                      context,
                      notification,
                      colorScheme,
                      textTheme,
                    );
                  },
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
          floatingActionButton: _showFab
              ? FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuad,
                    );
                  },
                  child: const Icon(Icons.arrow_upward),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Color.fromRGBO(
              (colorScheme.onSurfaceVariant.r * 255.0).round() & 0xff,
              (colorScheme.onSurfaceVariant.g * 255.0).round() & 0xff,
              (colorScheme.onSurfaceVariant.b * 255.0).round() & 0xff,
              0.5,
            ),
          ),
          const SizedBox(height: CeylonTokens.spacing16),
          Text(
            'No Notifications',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: CeylonTokens.spacing8),
          Text(
            'You\'re all caught up!',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationItem notification,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification),
      child: InkWell(
        onTap: () {
          _markAsRead(notification);
          _navigateBasedOnNotificationType(context, notification);
        },
        child: Container(
          color: notification.isRead
              ? null
              : Color.fromRGBO(
                  (colorScheme.primaryContainer.r * 255.0).round() & 0xff,
                  (colorScheme.primaryContainer.g * 255.0).round() & 0xff,
                  (colorScheme.primaryContainer.b * 255.0).round() & 0xff,
                  0.1,
                ),
          padding: const EdgeInsets.symmetric(
            horizontal: CeylonTokens.spacing16,
            vertical: CeylonTokens.spacing12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification, colorScheme),
              const SizedBox(width: CeylonTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: CeylonTokens.spacing4),
                    Text(
                      notification.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: CeylonTokens.spacing4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: textTheme.bodySmall?.copyWith(
                            color: Color.fromRGBO(
                              (colorScheme.onSurfaceVariant.r * 255.0).round() &
                                  0xff,
                              (colorScheme.onSurfaceVariant.g * 255.0).round() &
                                  0xff,
                              (colorScheme.onSurfaceVariant.b * 255.0).round() &
                                  0xff,
                              0.7,
                            ),
                          ),
                        ),
                        if (notification.relatedId != null)
                          Text(
                            'Tap to view',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateBasedOnNotificationType(
    BuildContext context,
    NotificationItem notification,
  ) {
    // This would be implemented based on app requirements
    // For example, navigating to an attraction details screen for a recommendation
    if (notification.relatedType == 'attraction' &&
        notification.relatedId != null) {
      // Navigator.push(...) to attraction details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to ${notification.relatedId} details'),
        ),
      );
    }
  }

  Widget _buildNotificationIcon(
    NotificationItem notification,
    ColorScheme colorScheme,
  ) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.info:
        iconData = Icons.info_outline;
        iconColor = Colors.blue;
        break;
      case NotificationType.alert:
        iconData = Icons.warning_amber;
        iconColor = Colors.orange;
        break;
      case NotificationType.social:
        iconData = Icons.chat_bubble_outline;
        iconColor = Colors.purple;
        break;
      case NotificationType.recommendation:
        iconData = Icons.lightbulb_outline;
        iconColor = Colors.amber;
        break;
      case NotificationType.reminder:
        iconData = Icons.event_note;
        iconColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(CeylonTokens.spacing8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          (iconColor.r * 255.0).round() & 0xff,
          (iconColor.g * 255.0).round() & 0xff,
          (iconColor.b * 255.0).round() & 0xff,
          0.1,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
