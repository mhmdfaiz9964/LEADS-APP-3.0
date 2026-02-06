import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lead_model.dart';
import '../models/customer_model.dart';
import '../models/service_model.dart';
import '../models/reminder_model.dart';
import '../models/notification_model.dart';
import '../models/note_model.dart';
import '../models/business_profile_model.dart';
import '../models/order_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> getTargetName(String id, String type) async {
    try {
      final doc = await _db
          .collection(type == 'LEAD' ? 'booking_leads' : 'booking_customers')
          .doc(id)
          .get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'Unknown';
      }
    } catch (e) {
      debugPrint("Error fetching target name: $e");
    }
    return 'Unknown';
  }

  // --- LEADS ---
  Stream<List<Lead>> getLeads({String? filterEmail}) {
    Query query = _db.collection('booking_leads');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addLead(Lead lead) async {
    await _db.collection('booking_leads').add(lead.toMap());
    // await addNotification(
    //   AppNotification(
    //     id: '',
    //     title: 'New Lead Added',
    //     message: 'New lead "${lead.name}" from "${lead.company}"',
    //     timestamp: DateTime.now(),
    //     type: 'LEAD',
    //     creatorEmail: lead.creatorEmail,
    //   ),
    // );
  }

  Future<void> updateLead(Lead lead) async {
    await _db.collection('booking_leads').doc(lead.id).update(lead.toMap());
    // await addNotification(
    //   AppNotification(
    //     id: '',
    //     title: 'Lead Updated',
    //     message: 'Lead "${lead.name}" details were updated.',
    //     timestamp: DateTime.now(),
    //     type: 'LEAD',
    //     creatorEmail: lead.creatorEmail,
    //   ),
    // );
  }

  Future<void> deleteLead(String id) {
    return _db.collection('booking_leads').doc(id).delete();
  }

  Future<void> toggleLeadPin(String id, bool currentStatus) {
    return _db.collection('booking_leads').doc(id).update({
      'isPinned': !currentStatus,
    });
  }

  Future<void> moveLeadToCustomer(Lead lead) async {
    final batch = _db.batch();

    // 1. Create customer document
    final customerRef = _db.collection('booking_customers').doc();
    batch.set(customerRef, {
      'name': lead.name,
      'agentName': lead.agentName,
      'company': lead.agentName,
      'phone': lead.phone,
      'email': lead.email,
      'address': lead.address,
      'notes': lead.notes,
      'plan': 'Standard',
      'serviceIds': lead.serviceIds,
      'createdAt': Timestamp.now(),
      'creatorEmail': lead.creatorEmail,
    });

    // 2. Delete lead document
    final leadRef = _db.collection('booking_leads').doc(lead.id);
    batch.delete(leadRef);

    // 3. Update associated reminders (if any)
    final reminders = await _db
        .collection('booking_reminders')
        .where('targetId', isEqualTo: lead.id)
        .where('targetType', isEqualTo: 'LEAD')
        .get();

    for (var doc in reminders.docs) {
      batch.update(doc.reference, {
        'targetId': customerRef.id,
        'targetType': 'CUSTOMER',
      });
    }

    // 4. Update associated notes (if any)
    final notes = await _db
        .collection('booking_notes')
        .where('targetId', isEqualTo: lead.id)
        .where('targetType', isEqualTo: 'LEAD')
        .get();

    for (var doc in notes.docs) {
      batch.update(doc.reference, {
        'targetId': customerRef.id,
        'targetType': 'CUSTOMER',
      });
    }

    return batch.commit();
  }

  Stream<int> getLeadsCountByService(String serviceId, {String? filterEmail}) {
    Query query = _db.collection('booking_leads');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map((s) {
      final docs = s.docs.map((doc) => Lead.fromFirestore(doc)).toList();
      return docs.where((l) => l.serviceIds.contains(serviceId)).length;
    });
  }

  // --- CUSTOMERS ---
  Stream<List<Customer>> getCustomers({String? filterEmail}) {
    Query query = _db.collection('booking_customers');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addCustomer(Customer customer) async {
    await _db.collection('booking_customers').add(customer.toMap());
    // await addNotification(
    //   AppNotification(
    //     id: '',
    //     title: 'New Customer Added',
    //     message: 'New customer "${customer.name}" joined.',
    //     timestamp: DateTime.now(),
    //     type: 'CUSTOMER',
    //     creatorEmail: customer.creatorEmail,
    //   ),
    // );
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db
        .collection('booking_customers')
        .doc(customer.id)
        .update(customer.toMap());
    // await addNotification(
    //   AppNotification(
    //     id: '',
    //     title: 'Customer Updated',
    //     message: 'Customer "${customer.name}" details updated.',
    //     timestamp: DateTime.now(),
    //     type: 'CUSTOMER',
    //     creatorEmail: customer.creatorEmail,
    //   ),
    // );
  }

  Future<void> deleteCustomer(String id) {
    return _db.collection('booking_customers').doc(id).delete();
  }

  Future<void> toggleCustomerPin(String id, bool currentStatus) {
    return _db.collection('booking_customers').doc(id).update({
      'isPinned': !currentStatus,
    });
  }

  Stream<List<Customer>> getCustomersByService(
    String serviceId, {
    String? filterEmail,
  }) {
    Query query = _db.collection('booking_customers');
    
    // First apply user filter if exists to narrow scope
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    
    // Then apply service filter
    // Note: This requires a composite index: creatorEmail ASC + serviceIds ASC
    return query
        .where('serviceIds', arrayContains: serviceId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
        );
  }

  Stream<int> getCustomersCountByService(
    String serviceId, {
    String? filterEmail,
  }) {
    Query query = _db.collection('booking_customers');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map((s) {
      final docs = s.docs.map((doc) => Customer.fromFirestore(doc)).toList();
      return docs.where((l) => l.serviceIds.contains(serviceId)).length;
    });
  }

  // --- SERVICES ---
  Stream<List<ServiceModel>> getServices({String? filterEmail}) {
    Query query = _db.collection('booking_services').orderBy('order');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList(),
    );
  }

  Future<void> addService(ServiceModel service) {
    return _db.collection('booking_services').add(service.toMap());
  }

  Future<void> updateService(ServiceModel service) {
    return _db
        .collection('booking_services')
        .doc(service.id)
        .update(service.toMap());
  }

  Future<void> deleteService(String id) {
    return _db.collection('booking_services').doc(id).delete();
  }

  Future<void> updateServiceOrder(List<ServiceModel> services) async {
    final batch = _db.batch();
    for (int i = 0; i < services.length; i++) {
      final docRef = _db.collection('booking_services').doc(services[i].id);
      batch.update(docRef, {'order': i});
    }
    return batch.commit();
  }

  // --- REMINDERS ---
  Stream<List<Reminder>> getReminders({String? filterEmail}) {
    Query query = _db.collection('booking_reminders');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Reminder.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  Stream<List<Reminder>> getRemindersByTarget(
    String targetId,
    String targetType,
  ) {
    return _db
        .collection('booking_reminders')
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Reminder.fromFirestore(doc))
              .toList();
          list.sort((a, b) => a.date.compareTo(b.date));
          return list;
        });
  }

  Future<DocumentReference> addReminder(Reminder reminder) async {
    final docRef = await _db
        .collection('booking_reminders')
        .add(reminder.toMap());
    await addNotification(
      AppNotification(
        id: '',
        title: 'Reminder Set',
        message: 'Task: "${reminder.title}"',
        timestamp: DateTime.now(),
        type: 'REMINDER',
        creatorEmail: reminder.creatorEmail,
      ),
    );
    return docRef;
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _db
        .collection('booking_reminders')
        .doc(reminder.id)
        .update(reminder.toMap());
  }

  Future<void> deleteReminder(String id) {
    return _db.collection('booking_reminders').doc(id).delete();
  }

  Future<void> toggleReminderPin(String id, bool currentStatus) {
    return _db.collection('booking_reminders').doc(id).update({
      'isPinned': !currentStatus,
    });
  }

  Future<void> toggleReminderStatus(String id, bool currentStatus) async {
    await _db.collection('booking_reminders').doc(id).update({
      'isCompleted': !currentStatus,
    });
    if (!currentStatus) {
      // It was incomplete, now complete
      final doc = await _db.collection('booking_reminders').doc(id).get();
      final r = Reminder.fromFirestore(doc);
      await addNotification(
        AppNotification(
          id: '',
          title: 'Task Completed',
          message: 'Finished task: "${r.title}"',
          timestamp: DateTime.now(),
          type: 'REMINDER',
          creatorEmail: r.creatorEmail,
        ),
      );
    }
  }

  // --- NOTES ---
  Stream<List<Note>> getNotesByTarget(String targetId, String targetType) {
    return _db
        .collection('booking_notes')
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Note.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addNote(Note note) {
    return _db.collection('booking_notes').add(note.toMap());
  }

  Future<void> deleteNote(String id) {
    return _db.collection('booking_notes').doc(id).delete();
  }

  // --- NOTIFICATIONS ---
  Stream<List<AppNotification>> getNotifications({String? filterEmail}) {
    Query query = _db
        .collection('booking_notifications')
        .orderBy('timestamp', descending: true);
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList(),
    );
  }

  Future<void> addNotification(AppNotification notification) {
    return _db.collection('booking_notifications').add(notification.toMap());
  }

  Future<void> broadcastNotification(String title, String message) async {
    final usersSnapshot = await _db.collection('booking_users').get();
    final batch = _db.batch();
    for (var userDoc in usersSnapshot.docs) {
      final userEmail = userDoc.data()['email'];
      if (userEmail == null) continue;

      final notifRef = _db.collection('booking_notifications').doc();
      batch.set(notifRef, {
        'title': title,
        'message': message,
        'timestamp': Timestamp.now(),
        'type': 'SYSTEM',
        'isRead': false,
        'creatorEmail': userEmail,
      });
    }
    return batch.commit();
  }

  Future<void> markNotificationRead(String id) {
    return _db.collection('booking_notifications').doc(id).update({
      'isRead': true,
    });
  }

  Future<void> clearAllNotifications({String? filterEmail}) async {
    Query query = _db.collection('booking_notifications');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    final snapshot = await query.get();
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    return batch.commit();
  }

  // --- USER ROLES & MANAGEMENT ---
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'uid': doc.id})
              .toList(),
        );
  }

  Future<Map<String, int>> getUserStats(String email) async {
    final leads = await _db
        .collection('booking_leads')
        .where('creatorEmail', isEqualTo: email)
        .get();
    final customers = await _db
        .collection('booking_customers')
        .where('creatorEmail', isEqualTo: email)
        .get();
    final orders = await _db
        .collection('booking_orders')
        .where('creatorEmail', isEqualTo: email)
        .get();
    final reminders = await _db
        .collection('booking_reminders')
        .where('creatorEmail', isEqualTo: email)
        .get();

    return {
      'leads': leads.size,
      'customers': customers.size,
      'orders': orders.size,
      'reminders': reminders.size,
    };
  }

  Future<void> deleteUser(String uid) {
    return _db.collection('booking_users').doc(uid).delete();
  }

  Future<void> updateUserProfile(
    String uid,
    String email,
    String role,
    String fullName,
  ) {
    return _db.collection('booking_users').doc(uid).update({
      'email': email,
      'role': role,
      'fullName': fullName,
    });
  }

  Future<void> createUserProfile(
    String uid,
    String email,
    String role, {
    String? fullName,
  }) {
    return _db.collection('booking_users').doc(uid).set({
      'email': email,
      'role': role,
      'fullName': fullName ?? '',
    });
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('booking_users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['role'] ?? 'User';
    }
    return 'User';
  }

  Future<void> updateUserToken(String uid, String token) {
    return _db.collection('booking_users').doc(uid).update({'fcmToken': token});
  }

  // --- BUSINESS PROFILE ---
  Future<BusinessProfile?> getBusinessProfile(String uid) async {
    final doc = await _db
        .collection('booking_business_profiles')
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      return BusinessProfile.fromMap(doc.data()!, uid);
    }
    return null;
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) {
    return _db
        .collection('booking_business_profiles')
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<Customer?> getCustomerById(String id) async {
    final doc = await _db.collection('booking_customers').doc(id).get();
    if (doc.exists) {
      return Customer.fromFirestore(doc);
    }
    return null;
  }

  // --- ORDERS ---
  Stream<List<OrderModel>> getOrders({String? filterEmail}) {
    Query query = _db.collection('booking_orders');
    if (filterEmail != null) {
      query = query.where('creatorEmail', isEqualTo: filterEmail);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<OrderModel>> getOrdersByCustomer(String customerId) {
    return _db
        .collection('booking_orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addOrder(OrderModel order) async {
    await _db.collection('booking_orders').add(order.toMap());
    // await addNotification(
    //   AppNotification(
    //     id: '',
    //     title: 'New Order',
    //     message: 'Order #${order.orderNumber} for ${order.customerName}',
    //     timestamp: DateTime.now(),
    //     type: 'ORDER',
    //     creatorEmail: order.creatorEmail,
    //   ),
    // );
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) {
    return _db.collection('booking_orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  Future<void> deleteOrder(String orderId) {
    return _db.collection('booking_orders').doc(orderId).delete();
  }
}
