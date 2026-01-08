import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_sidebar.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'leads_screen.dart';
import 'customers_screen.dart';
import 'services_screen.dart';
import 'reminders_screen.dart';
import 'cart_screen.dart';
import 'add_lead_screen.dart';
import 'add_customer_screen.dart';
import 'add_service_screen.dart';
import 'add_reminder_screen.dart';
import 'notifications_screen.dart';
import 'business_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '../models/reminder_model.dart';
import '../widgets/user_list_modal.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({this.initialIndex = 0, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  StreamSubscription? _notifSubscription;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _customerStatusFilter = "ALL"; // For filtering customers by status

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Schedule notification listener start and check for upcoming reminders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNotificationListener();
      _checkUpcomingReminders();
    });
  }

  Future<void> _checkUpcomingReminders() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userEmail = auth.currentUser?.email;
    if (userEmail == null) return;

    // Get all reminders
    final reminders = await DatabaseService()
        .getReminders(filterEmail: userEmail)
        .first;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final upcomingReminders = reminders.where((r) {
      if (r.isCompleted) return false;
      final rDate = DateTime(r.date.year, r.date.month, r.date.day);
      return rDate.isAtSameMomentAs(today) || rDate.isAtSameMomentAs(tomorrow);
    }).toList();

    if (upcomingReminders.isNotEmpty && mounted) {
      List<Map<String, dynamic>> enrichedReminders = [];
      for (var r in upcomingReminders) {
        String targetName = "";
        if (r.targetId != null && r.targetType != null) {
          targetName = await DatabaseService().getTargetName(
            r.targetId!,
            r.targetType!,
          );
        }
        enrichedReminders.add({'reminder': r, 'targetName': targetName});
      }
      if (mounted) {
        _showUpcomingRemindersDialog(enrichedReminders);
      }
    }
  }

  void _showUpcomingRemindersDialog(List<Map<String, dynamic>> enriched) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("Upcoming Reminders (${enriched.length})"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ...enriched.take(5).map((data) {
                final r = data['reminder'] as Reminder;
                final name = data['targetName'] as String;
                final dateStr = DateFormat('MMM dd, hh:mm a').format(r.date);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        r.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (name.isNotEmpty && name != "Unknown")
                        Text(
                          "For: $name",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    ],
                  ),
                );
              }),
              if (enriched.length > 5)
                const Text(
                  "\nAnd others...",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("View All"),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentIndex = 3);
            },
          ),
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _startNotificationListener() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userEmail = auth.currentUser?.email;
    if (userEmail == null) return;

    _notifSubscription = DatabaseService()
        .getNotifications(filterEmail: userEmail)
        .listen((notifs) {
          if (notifs.isNotEmpty) {
            final latest = notifs.first;
            final now = DateTime.now();
            final diff = now.difference(latest.timestamp);

            // Only show "Push" if it happened in the last 10 seconds AND is a REMINDER
            if (diff.inSeconds < 10 &&
                !latest.isRead &&
                latest.type == 'REMINDER') {
              NotificationService().showImmediateNotification(
                id: latest.id.hashCode,
                title: latest.title,
                body: latest.message,
              );
            }
          }
        });
  }

  void _onNavTap(int index, {String? statusFilter}) {
    setState(() {
      _currentIndex = index;
      if (statusFilter != null) {
        _customerStatusFilter = statusFilter;
      } else {
        _customerStatusFilter = "ALL"; // Reset filter when changing tabs
      }
    });
  }

  void _onFabTap() {
    Widget page;
    switch (_currentIndex) {
      case 0:
        page = const AddLeadScreen();
        break;
      case 1:
        page = const AddCustomerScreen();
        break;
      case 2:
        page = const AddServiceScreen(); // Will rename screen later
        break;
      case 3:
        page = const AddReminderScreen();
        break;
      default:
        page = const AddLeadScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userEmail = auth.currentUser?.email;

    String fabLabel = "";
    switch (_currentIndex) {
      case 0:
        fabLabel = "Lead";
        break;
      case 1:
        fabLabel = "Customer";
        break;
      case 2:
        fabLabel = "Service";
        break;
      case 3:
        fabLabel = "Reminder";
        break;
      default:
        fabLabel = "";
    }

    final List<String> titles = [
      "Leads",
      "Customers",
      "Services",
      "Reminders",
      "Cart",
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          titles[_currentIndex],
          style: AppTheme.theme.textTheme.titleLarge,
        ),
        actions: [
          // Team/User List Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => UserListModal(),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          // Notifications
          StreamBuilder<List<AppNotification>>(
            stream: DatabaseService().getNotifications(filterEmail: userEmail),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.where((n) => !n.isRead).length;
                NotificationService().updateBadgeCount(unreadCount);
              }
              return Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                  top: 8,
                  bottom: 8,
                  left: 4,
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          unreadCount > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryOrange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.appBarBlue,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                unreadCount > 9 ? "9+" : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // My Business Profile Icon
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BusinessScreen()),
              );
              if (result == 'open_cart') {
                setState(() {
                  _currentIndex = 4;
                  _customerStatusFilter = "ALL";
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: CustomSidebar(onIndexChanged: _onNavTap),
      body: _buildCurrentScreen(),
      floatingActionButton:
          (_currentIndex == 4 ||
              (_currentIndex == 2 && auth.currentUser?.role != 'Admin'))
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    onPressed: _onFabTap,
                    backgroundColor: AppTheme.secondaryOrange,
                    child: const Icon(Icons.add, size: 30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fabLabel,
                  style: const TextStyle(
                    color: AppTheme.secondaryOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
      bottomNavigationBar: StreamBuilder<List<Reminder>>(
        stream: DatabaseService().getReminders(filterEmail: userEmail),
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final limit = today.add(
              const Duration(days: 2),
            ); // Within 2 days (today & tomorrow)

            count = snapshot.data!.where((r) {
              if (r.isCompleted) return false;
              return r.date.isBefore(limit);
            }).length;
          }
          return CustomBottomNav(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            remindersBadgeCount: count,
          );
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const LeadsScreen();
      case 1:
        return const CustomersScreen();
      case 2:
        return const ServicesScreen();
      case 3:
        return const RemindersScreen();
      case 4:
        return CartScreen(initialStatusFilter: _customerStatusFilter);
      default:
        return const LeadsScreen();
    }
  }
}
