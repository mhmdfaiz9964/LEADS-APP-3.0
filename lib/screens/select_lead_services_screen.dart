import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lead_model.dart';
import '../models/service_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'add_service_screen.dart';

class SelectLeadServicesScreen extends StatefulWidget {
  final Lead lead;
  const SelectLeadServicesScreen({super.key, required this.lead});

  @override
  State<SelectLeadServicesScreen> createState() =>
      _SelectLeadServicesScreenState();
}

class _SelectLeadServicesScreenState extends State<SelectLeadServicesScreen> {
  final Set<String> _selectedServiceIds = {};

  @override
  void initState() {
    super.initState();
    _selectedServiceIds.addAll(widget.lead.serviceIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Services - ${widget.lead.name}"),
        backgroundColor: AppTheme.appBarBlue,
      ),
      body: Builder(
        builder: (context) {
          final auth = Provider.of<AuthService>(context, listen: false);
          final isAdmin = auth.currentUser?.role == 'Admin';
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ServiceModel>>(
                  stream: DatabaseService().getServices(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final services = snapshot.data!;
                    return ListView.builder(
                      itemCount: services.length + (isAdmin ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isAdmin && index == services.length) {
                          return ListTile(
                            leading: const Icon(
                              Icons.add,
                              color: AppTheme.secondaryOrange,
                            ),
                            title: const Text(
                              "NEW SERVICE",
                              style: TextStyle(
                                color: AppTheme.secondaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddServiceScreen(),
                                ),
                              );
                            },
                          );
                        }
                        final service = services[index];
                        bool isSelected = _selectedServiceIds.contains(
                          service.id,
                        );
                        return Column(
                          children: [
                            ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedServiceIds.add(service.id);
                                    } else {
                                      _selectedServiceIds.remove(service.id);
                                    }
                                  });
                                },
                              ),
                              title: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: service.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    service.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedServiceIds.remove(service.id);
                                  } else {
                                    _selectedServiceIds.add(service.id);
                                  }
                                });
                              },
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 30,
                    top: 8,
                  ),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('booking_leads')
                          .doc(widget.lead.id)
                          .update({
                            'serviceIds': _selectedServiceIds.toList(),
                            'labelIds': _selectedServiceIds.toList(),
                          });
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
