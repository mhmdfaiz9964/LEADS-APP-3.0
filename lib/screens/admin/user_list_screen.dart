import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/screens/admin/add_user_screen.dart';
import 'package:leads_manager/screens/user_activities_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: AppTheme.appBarGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddUserScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return UserCard(user: users[index]);
            },
          );
        },
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserCard({super.key, required this.user});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final email = widget.user['email'] ?? 'No email';
    final fullName = widget.user['fullName'] ?? 'No name';
    final role = (widget.user['role'] ?? 'user').toString().toUpperCase();
    final uid = widget.user['uid'];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserActivitiesScreen(
                filterEmail: email,
                title: "$fullName's Activities",
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<Lead>>(
                          stream: DatabaseService().getLeads(
                            filterEmail: email,
                          ),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return Row(
                              children: [
                                const Icon(
                                  Icons.track_changes,
                                  color: Colors.red,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$count Leads",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: role == 'ADMIN'
                              ? Colors.red[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 10,
                            color: role == 'ADMIN' ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 52),
                      _buildInlineAction(
                        Icons.edit_outlined,
                        "Edit",
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddUserScreen(userToEdit: widget.user),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.bar_chart,
                        "Activities",
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserActivitiesScreen(
                                filterEmail: email,
                                title: "$fullName's Activities",
                              ),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.delete_outline,
                        "Delete",
                        Colors.red,
                        () async {
                          final confirm = await showCupertinoDialog<bool>(
                            context: context,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: const Text("Delete User"),
                              content: Text(
                                "Are you sure you want to delete $fullName?",
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.pop(ctx, false),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text("Delete"),
                                  onPressed: () => Navigator.pop(ctx, true),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await DatabaseService().deleteUser(uid);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, style: TextStyle(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
