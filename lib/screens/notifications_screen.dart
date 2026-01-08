import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final isAdmin = user?.role == 'Admin';
    final filterEmail = isAdmin ? null : user?.email;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBlue,
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () {
              DatabaseService().clearAllNotifications(filterEmail: filterEmail);
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: DatabaseService().getNotifications(filterEmail: filterEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No notifications yet"));

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(context, notifications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification n) {
    final timeStr = DateFormat('MMM dd, hh:mm a').format(n.timestamp);

    return Card(
      elevation: 0,
       margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: () => DatabaseService().markNotificationRead(n.id),
        leading: Icon(
          n.type == 'LEAD' ? Icons.track_changes : (n.type == 'CUSTOMER' ? Icons.person : Icons.notifications),
          color: const Color(0xFF0046FF),
          size: 28,
        ),
        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.message, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: !n.isRead ? const Icon(Icons.circle, color: AppTheme.secondaryOrange, size: 8) : null,
      ),
    );
  }
}
