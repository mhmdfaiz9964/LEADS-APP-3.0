import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:leads_manager/models/label_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:leads_manager/screens/add_label_screen.dart';
import 'package:leads_manager/screens/label_details_screen.dart';

class LabelsScreen extends StatefulWidget {
  final String searchQuery;
  const LabelsScreen({this.searchQuery = "", super.key});

  @override
  State<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends State<LabelsScreen> {
  void _confirmDelete(BuildContext context, LabelModel label) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete Label"),
        content: const Text(
          "Are you sure? This will not delete leads with this label, but they will lose the label reference.",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await DatabaseService().deleteLabel(label.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final isAdmin = user?.role == 'admin';
    final filterEmail = isAdmin ? null : user?.email;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Tap and hold on a record for more options",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<LabelModel>>(
            stream: DatabaseService().getLabels(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(child: Text("No labels found"));

              var labels = snapshot.data!;
              if (widget.searchQuery.isNotEmpty) {
                final query = widget.searchQuery.toLowerCase();
                labels = labels
                    .where((l) => l.name.toLowerCase().contains(query))
                    .toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
                itemCount: labels.length,
                itemBuilder: (context, index) {
                  final label = labels[index];
                  return StreamBuilder<int>(
                    stream: DatabaseService().getLeadsCountByLabel(
                      label.id,
                      filterEmail: filterEmail,
                    ),
                    builder: (context, leadsSnapshot) {
                      final leadsCount = leadsSnapshot.data ?? 0;
                      return StreamBuilder<int>(
                        stream: DatabaseService().getCustomersCountByLabel(
                          label.id,
                          filterEmail: filterEmail,
                        ),
                        builder: (context, customersSnapshot) {
                          final customersCount = customersSnapshot.data ?? 0;
                          return LabelCard(
                            label: label,
                            count: leadsCount + customersCount,
                            onDelete: () => _confirmDelete(context, label),
                            isAdmin: isAdmin,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class LabelCard extends StatefulWidget {
  final LabelModel label;
  final int count;
  final VoidCallback onDelete;
  final bool isAdmin;
  const LabelCard({
    super.key,
    required this.label,
    required this.count,
    required this.onDelete,
    required this.isAdmin,
  });

  @override
  State<LabelCard> createState() => _LabelCardState();
}

class _LabelCardState extends State<LabelCard> {
  bool _isExpanded = false;

  void _showLabelOptions(BuildContext context, LabelModel label) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Label: ${label.name}'),
        message: const Text('Choose an action for this label'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LabelDetailsScreen(label: label),
                ),
              );
            },
            child: const Text('View Records'),
          ),
          if (widget.isAdmin)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddLabelScreen(labelToEdit: label),
                  ),
                );
              },
              child: const Text('Edit Label'),
            ),
          if (widget.isAdmin)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete();
              },
              child: const Text('Delete Label'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LabelDetailsScreen(label: widget.label),
            ),
          );
        },
        onLongPress: () => _showLabelOptions(context, widget.label),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.label.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.label.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${widget.count} Customers",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildInlineAction(
                        Icons.visibility_outlined,
                        "View",
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LabelDetailsScreen(label: widget.label),
                            ),
                          );
                        },
                      ),
                      if (widget.isAdmin)
                        _buildInlineAction(
                          Icons.edit_outlined,
                          "Edit",
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddLabelScreen(labelToEdit: widget.label),
                              ),
                            );
                          },
                        ),
                      if (widget.isAdmin)
                        _buildInlineAction(
                          Icons.delete_outline,
                          "Delete",
                          Colors.red,
                          widget.onDelete,
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
