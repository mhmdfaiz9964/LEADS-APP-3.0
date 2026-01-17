import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/models/service_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:leads_manager/screens/lead_details_screen.dart';
import 'package:leads_manager/screens/add_lead_screen.dart';
import 'package:leads_manager/screens/service_details_screen.dart';
import 'package:provider/provider.dart';

class LeadsScreen extends StatefulWidget {
  final String searchQuery;
  const LeadsScreen({this.searchQuery = "", super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String _selectedFilter = "ALL";

  void _confirmMoveToCustomer(BuildContext context, Lead lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: AppTheme.secondaryOrange, size: 48),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Move 1 leads to customers list?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: AppTheme.secondaryOrange),
            ),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().moveLeadToCustomer(lead);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Moved to Customers")),
                );
              }
            },
            child: const Text(
              "MOVE TO CUSTOMERS LIST",
              style: TextStyle(color: AppTheme.secondaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Lead lead) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete Lead"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await DatabaseService().deleteLead(lead.id);
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
    final isAdmin = user?.role == 'Admin';
    final filterEmail = isAdmin ? null : user?.email;

    return Column(
      children: [
        // Service Filter Row
        Container(
          color: AppTheme.appBarBlue,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: StreamBuilder<List<ServiceModel>>(
            stream: DatabaseService().getServices(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final services = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildFilterChip("ALL", "ALL", AppTheme.secondaryOrange),
                    ...services.map(
                      (s) => _buildFilterChip(
                        s.name.toUpperCase(),
                        s.id,
                        Color(s.colorValue),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
          child: StreamBuilder<List<Lead>>(
            stream: DatabaseService().getLeads(filterEmail: filterEmail),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(child: Text("No leads found"));

              var leads = snapshot.data!;

              // Apply Service Filter
              if (_selectedFilter != "ALL") {
                leads = leads
                    .where((l) => l.serviceIds.contains(_selectedFilter))
                    .toList();
              }

              if (widget.searchQuery.isNotEmpty) {
                final query = widget.searchQuery.toLowerCase();
                leads = leads
                    .where(
                      (l) =>
                          l.name.toLowerCase().contains(query) ||
                          l.agentName.toLowerCase().contains(query),
                    )
                    .toList();
              }

              leads.sort((a, b) {
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                return b.createdAt.compareTo(a.createdAt);
              });

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
                itemCount: leads.length,
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  final now = DateTime.now();
                  final diff = now.difference(lead.createdAt);
                  String timeStr = "";
                  if (diff.inMinutes < 60) {
                    timeStr =
                        "+ ${diff.inMinutes} min. ago, ${DateFormat('h:mm a').format(lead.createdAt)}";
                  } else {
                    timeStr =
                        "${DateFormat('MMM d').format(lead.createdAt)}, ${DateFormat('h:mm a').format(lead.createdAt)}";
                  }
                  return LeadCard(
                    lead: lead,
                    timeStr: timeStr,
                    onMove: () => _confirmMoveToCustomer(context, lead),
                    onDelete: () => _confirmDelete(context, lead),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String id, Color color) {
    bool isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = isSelected ? "ALL" : id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class LeadCard extends StatefulWidget {
  final Lead lead;
  final String timeStr;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const LeadCard({
    super.key,
    required this.lead,
    required this.timeStr,
    required this.onDelete,
    required this.onMove,
  });

  @override
  State<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  bool _isExpanded = false;

  void _showLeadOptions(BuildContext context, Lead lead) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(lead.name),
        message: Text(lead.agentName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadDetailsScreen(lead: lead),
                ),
              );
            },
            child: const Text('View Details'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddLeadScreen(leadToEdit: lead),
                ),
              );
            },
            child: const Text('Edit Lead'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onMove();
            },
            child: const Text('Move to Customer'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Delete Lead'),
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
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeadDetailsScreen(lead: widget.lead),
          ),
        ),
        onLongPress: () => _showLeadOptions(context, widget.lead),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.track_changes,
                    color: AppTheme.primaryBlue,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.lead.name} (${widget.lead.agentName})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildServiceBadge(widget.lead.serviceIds),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.secondaryOrange.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: AppTheme.secondaryOrange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              await DatabaseService().toggleLeadPin(
                                widget.lead.id,
                                widget.lead.isPinned,
                              );
                            },
                            child: Icon(
                              widget.lead.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: widget.lead.isPinned
                                  ? AppTheme.secondaryOrange
                                  : Colors.grey[300],
                              size: 20,
                            ),
                          ),
                        ],
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
                      const SizedBox(width: 48),
                      _buildInlineAction(
                        Icons.edit_outlined,
                        "Edit",
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddLeadScreen(leadToEdit: widget.lead),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.add_circle_outline,
                        "Customer",
                        Colors.green,
                        widget.onMove,
                      ),
                      _buildInlineAction(
                        Icons.visibility_off_outlined,
                        "Hide",
                        AppTheme.secondaryOrange,
                        () {},
                      ),
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

  Widget _buildServiceBadge(List<String> labelIds) {
    if (labelIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<ServiceModel>>(
      future: DatabaseService().getServices().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final selectedServices = snapshot.data!
            .where((l) => labelIds.contains(l.id))
            .toList();
        if (selectedServices.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: selectedServices
              .map(
                (service) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailsScreen(service: service),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: service.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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
