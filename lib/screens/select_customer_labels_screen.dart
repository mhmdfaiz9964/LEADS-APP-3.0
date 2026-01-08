import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/label_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'add_label_screen.dart';

class SelectCustomerLabelsScreen extends StatefulWidget {
  final Customer customer;
  const SelectCustomerLabelsScreen({super.key, required this.customer});

  @override
  State<SelectCustomerLabelsScreen> createState() =>
      _SelectCustomerLabelsScreenState();
}

class _SelectCustomerLabelsScreenState
    extends State<SelectCustomerLabelsScreen> {
  final Set<String> _selectedLabelIds = {};

  @override
  void initState() {
    super.initState();
    _selectedLabelIds.addAll(widget.customer.labelIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Labels - ${widget.customer.name}"),
        backgroundColor: AppTheme.appBarGreen,
      ),
      body: Builder(
        builder: (context) {
          final auth = Provider.of<AuthService>(context, listen: false);
          final isAdmin = auth.currentUser?.role == 'admin';
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<LabelModel>>(
                  stream: DatabaseService().getLabels(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final labels = snapshot.data!;
                    return ListView.builder(
                      itemCount: labels.length + (isAdmin ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isAdmin && index == labels.length) {
                          return ListTile(
                            leading: const Icon(
                              Icons.add,
                              color: AppTheme.secondaryOrange,
                            ),
                            title: const Text(
                              "NEW LABEL",
                              style: TextStyle(
                                color: AppTheme.secondaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddLabelScreen(),
                                ),
                              );
                            },
                          );
                        }
                        final label = labels[index];
                        bool isSelected = _selectedLabelIds.contains(label.id);
                        return Column(
                          children: [
                            ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedLabelIds.add(label.id);
                                    } else {
                                      _selectedLabelIds.remove(label.id);
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
                                    color: label.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    label.name.toUpperCase(),
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
                                    _selectedLabelIds.remove(label.id);
                                  } else {
                                    _selectedLabelIds.add(label.id);
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
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(widget.customer.id)
                        .update({'labelIds': _selectedLabelIds.toList()});
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
