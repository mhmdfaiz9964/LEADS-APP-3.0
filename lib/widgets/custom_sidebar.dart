import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../screens/admin/user_list_screen.dart';
import '../screens/admin/add_user_screen.dart';

class CustomSidebar extends StatelessWidget {
  final Function(int index, {String? statusFilter})? onIndexChanged;

  const CustomSidebar({this.onIndexChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isAdmin = user?.role == 'Admin';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Profile Details Header
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(4); // Switch to Business/Profile index
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: AppTheme.primaryBlue,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.email.split('@')[0].toUpperCase() ?? "User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? "",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          (user?.role ?? 'User').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 16),

                // Navigation Items for ALL roles
                _buildSidebarItem(context, 'Leads', Icons.track_changes, () {
                  if (onIndexChanged != null) {
                    Navigator.pop(context);
                    onIndexChanged!(0);
                  }
                }),
                _buildSidebarItem(
                  context,
                  'Customers',
                  Icons.person_pin_circle,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(1);
                    }
                  },
                ),
                _buildSidebarItem(
                  context,
                  'Services',
                  Icons.miscellaneous_services,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(2);
                    }
                  },
                ),
                _buildSidebarItem(
                  context,
                  'Reminders',
                  Icons.notifications_none,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(3);
                    }
                  },
                ),

                const Divider(),

                // Customer Status Filters
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text(
                    'CUSTOMER STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                _buildStatusFilterItem(
                  context,
                  'All Orders',
                  Icons.apps,
                  Colors.grey[700]!,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(4, statusFilter: "ALL");
                    }
                  },
                ),
                _buildStatusFilterItem(
                  context,
                  'New',
                  Icons.shopping_cart,
                  Colors.blue,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(4, statusFilter: "NEW");
                    }
                  },
                ),
                _buildStatusFilterItem(
                  context,
                  'Process',
                  Icons.check_circle,
                  Colors.green,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(4, statusFilter: "PROCESS");
                    }
                  },
                ),
                _buildStatusFilterItem(
                  context,
                  'Approved',
                  Icons.inventory,
                  Colors.orange,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(4, statusFilter: "APPROVED");
                    }
                  },
                ),
                _buildStatusFilterItem(
                  context,
                  'Refused',
                  Icons.local_shipping,
                  Colors.purple,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(4, statusFilter: "REFUSED");
                    }
                  },
                ),

                if (isAdmin) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'ADMIN MANAGEMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  _buildSidebarItem(context, 'Users', Icons.people_outline, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserListScreen()),
                    );
                  }),
                  _buildSidebarItem(
                    context,
                    'Create User',
                    Icons.person_add_outlined,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddUserScreen(),
                        ),
                      );
                    },
                  ),
                ],

                const Divider(),

                // Profile & Account
                _buildSidebarItem(
                  context,
                  'Manage Profile',
                  Icons.account_circle_outlined,
                  () {
                    if (onIndexChanged != null) {
                      Navigator.pop(context);
                      onIndexChanged!(4);
                    }
                  },
                ),

                _buildSidebarItem(
                  context,
                  'Logout',
                  Icons.logout,
                  () => _showLogoutDialog(context, authService),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          // Version info at bottom
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Version 1.0.1',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.iconGrey, size: 24),
      title: Text(
        title,
        style: AppTheme.textStyle.copyWith(
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatusFilterItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of Booking App?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              authService.signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
