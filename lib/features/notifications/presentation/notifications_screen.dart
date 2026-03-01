// lib/features/notifications/presentation/notifications_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import 'create_notification_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String businessId;
  const NotificationsScreen({super.key, required this.businessId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final _notifService = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _typeColor(NotificationType t) {
    switch (t) {
      case NotificationType.bookingNew:       return Colors.blue;
      case NotificationType.bookingConfirmed: return Colors.green;
      case NotificationType.bookingCancelled: return Colors.red;
      case NotificationType.paymentReceived:  return Colors.green;
      case NotificationType.invoiceDue:       return Colors.orange;
      case NotificationType.invoiceOverdue:   return Colors.red;
      case NotificationType.payrollReady:     return Colors.purple;
      case NotificationType.attendanceAlert:  return Colors.orange;
      case NotificationType.employeeAdded:    return Colors.teal;
      case NotificationType.general:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(children: [
          const Text('Notifications'),
          const SizedBox(width: 8),
          StreamBuilder<int>(
            stream: _notifService.streamUnreadCount(widget.businessId),
            builder: (_, snap) {
              final count = snap.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              );
            },
          ),
        ]),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'mark_all') {
                await _notifService.markAllAsRead(widget.businessId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('All marked as read'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))));
                }
              } else if (val == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Clear All?'),
                    content: const Text('Delete all notifications?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _notifService.clearAll(widget.businessId);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'mark_all',
                  child: Row(children: [
                    Icon(Icons.done_all, size: 18),
                    SizedBox(width: 10),
                    Text('Mark all as read'),
                  ])),
              const PopupMenuItem(value: 'clear_all',
                  child: Row(children: [
                    Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Clear all', style: TextStyle(color: Colors.red)),
                  ])),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.notifications_outlined, size: 18)),
            Tab(text: 'Unread', icon: Icon(Icons.mark_email_unread_outlined, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateNotificationScreen(businessId: widget.businessId),
          ),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('New Alert', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(unreadOnly: false),
          _buildList(unreadOnly: true),
        ],
      ),
    );
  }

  Widget _buildList({required bool unreadOnly}) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notifService.streamNotifications(
        businessId: widget.businessId,
        unreadOnly: unreadOnly,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snap.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  unreadOnly
                      ? Icons.mark_email_read_outlined
                      : Icons.notifications_off_outlined,
                  size: 72,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  unreadOnly ? 'All caught up!' : 'No notifications yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  unreadOnly
                      ? 'No unread notifications'
                      : 'Notifications will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: notifications.length,
          itemBuilder: (_, i) => _notifCard(notifications[i]),
        );
      },
    );
  }

  Widget _notifCard(NotificationModel notif) {
    final color = _typeColor(notif.type);
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) =>
          _notifService.deleteNotification(widget.businessId, notif.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: notif.isRead ? 0 : 2,
        color: notif.isRead ? Colors.white : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (!notif.isRead) {
              _notifService.markAsRead(widget.businessId, notif.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(notif.typeIcon,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(notif.title,
                                style: TextStyle(
                                    fontWeight: notif.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                    fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: Colors.orange[700],
                                  shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(notif.body,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeName(notif.type),
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(notif.timeAgo,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeName(NotificationType t) {
    switch (t) {
      case NotificationType.bookingNew:       return 'Booking';
      case NotificationType.bookingConfirmed: return 'Booking';
      case NotificationType.bookingCancelled: return 'Booking';
      case NotificationType.paymentReceived:  return 'Payment';
      case NotificationType.invoiceDue:       return 'Invoice';
      case NotificationType.invoiceOverdue:   return 'Invoice';
      case NotificationType.payrollReady:     return 'Payroll';
      case NotificationType.attendanceAlert:  return 'Attendance';
      case NotificationType.employeeAdded:    return 'Employee';
      case NotificationType.general:          return 'General';
    }
  }
}
