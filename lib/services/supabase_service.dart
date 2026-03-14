import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'supabase_config.dart';

/// Singleton service wrapping all Supabase operations.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Realtime channels ────────────────────────────────────────
  RealtimeChannel? _clearanceChannel;
  RealtimeChannel? _globalClearanceChannel; // For staff view
  RealtimeChannel? _notificationChannel;
  RealtimeChannel? _opportunityChannel;
  RealtimeChannel? _issueChannel;
  RealtimeChannel? _studentChannel;

  final _clearanceController = StreamController<Map<String, dynamic>>.broadcast();
  final _globalClearanceController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _opportunityController = StreamController<Map<String, dynamic>>.broadcast();
  final _issueController = StreamController<Map<String, dynamic>>.broadcast();
  final _studentController = StreamController<Map<String, dynamic>>.broadcast();

  // ── Initialization ──────────────────────────────────────────
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // ── Auth ─────────────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Auto-generate Student ID ────────────────────────────────
  /// Calls the Postgres `generate_student_id()` function via RPC.
  /// Falls back to a client-side ID if the function isn't available.
  Future<String> generateStudentId() async {
    try {
      final response = await _client.rpc('generate_student_id');
      debugPrint('[SupabaseService] Generated student ID via RPC: $response');
      return response as String;
    } catch (e) {
      // Fallback: generate a client-side ID using timestamp + random
      debugPrint('[SupabaseService] RPC generate_student_id failed: $e');
      debugPrint('[SupabaseService] Using client-side fallback ID generation');
      final now = DateTime.now();
      final rand = Random().nextInt(999);
      final id = 'STU-${now.millisecondsSinceEpoch.toString().substring(7)}$rand'.substring(0, 10);
      return id;
    }
  }

  /// Sign up a new student. The student ID is auto-generated.
  /// Returns `{authResponse, studentId}` so the UI can display the new ID.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String department = 'General',
    int year = 1,
    bool hostel = false,
  }) async {
    debugPrint('[SupabaseService] signUp() called for $email');

    // 1. Mint a unique student ID
    final studentId = await generateStudentId();
    debugPrint('[SupabaseService] studentId = $studentId');

    // 2. Create auth user
    debugPrint('[SupabaseService] Creating auth user...');
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'student_id': studentId,
      },
    );
    debugPrint('[SupabaseService] Auth user created: ${authResponse.user?.id}');

    // 3. Create the student profile row linked to the auth user
    if (authResponse.user != null) {
      debugPrint('[SupabaseService] Upserting student profile...');
      try {
        await _client.from('students').upsert({
          'auth_uid': authResponse.user!.id,
          'student_id': studentId,
          'name': name,
          'email': email,
          'department': department,
          'year': year,
          'hostel': hostel,
        }, onConflict: 'student_id');
        debugPrint('[SupabaseService] Student profile upserted OK');
      } catch (e) {
        debugPrint('[SupabaseService] Student profile upsert failed: $e');
        // Don't rethrow — the auth account was created successfully
      }
    }

    return {'authResponse': authResponse, 'studentId': studentId};
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Students ─────────────────────────────────────────────────
  Future<Student?> getStudentByAuthUid() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('students')
        .select()
        .eq('auth_uid', user.id)
        .maybeSingle();

    if (data == null) return null;
    return _studentFromRow(data);
  }

  Future<Student?> getStudentById(String studentId) async {
    final data = await _client
        .from('students')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();

    if (data == null) return null;
    return _studentFromRow(data);
  }

  /// Link an existing student row to the current auth user (for seed-data accounts).
  Future<void> linkAuthToStudent(String studentId) async {
    final user = currentUser;
    if (user == null) return;
    await _client
        .from('students')
        .update({'auth_uid': user.id, 'email': user.email})
        .eq('student_id', studentId);
  }

  // ── Dues ─────────────────────────────────────────────────────
  Future<DuesRecord> getDues(String studentId) async {
    final data = await _client
        .from('students')
        .select('library_fine, hostel_dues, lab_fees, tuition_balance, mess_dues')
        .eq('student_id', studentId)
        .maybeSingle();

    if (data == null) return DuesRecord();
    return DuesRecord(
      libraryFine: _toDouble(data['library_fine']),
      hostelDues: _toDouble(data['hostel_dues']),
      labFees: _toDouble(data['lab_fees']),
      tuitionBalance: _toDouble(data['tuition_balance']),
      messDues: _toDouble(data['mess_dues']),
    );
  }

  // ── Clearance Requests ───────────────────────────────────────
  Future<List<ClearanceRequest>> getClearanceRequests(String studentId) async {
    final data = await _client
        .from('clearance_requests')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => _clearanceFromRow(row)).toList();
  }

  Future<ClearanceRequest> createClearanceRequest({
    required String studentId,
    required String clearanceType,
    required Map<String, String> departmentStatuses,
    required String overallStatus,
    String? remarks,
    DateTime? estimatedCompletion,
  }) async {
    final row = {
      'student_id': studentId,
      'clearance_type': clearanceType,
      'library_status': departmentStatuses['library'] ?? 'pending',
      'hostel_status': departmentStatuses['hostel'] ?? 'pending',
      'accounts_status': departmentStatuses['accounts'] ?? 'pending',
      'lab_status': departmentStatuses['lab'] ?? 'pending',
      'mess_status': departmentStatuses['mess'] ?? 'pending',
      'tutor_status': departmentStatuses['tutor'] ?? 'pending',
      'overall_status': overallStatus,
      'remarks': remarks,
      'estimated_completion': estimatedCompletion?.toIso8601String(),
    };

    final inserted = await _client
        .from('clearance_requests')
        .insert(row)
        .select()
        .single();

    return _clearanceFromRow(inserted);
  }

  // ── Opportunities ────────────────────────────────────────────
  Future<List<Opportunity>> getOpportunities() async {
    final data = await _client
        .from('opportunities')
        .select()
        .order('match_score', ascending: false);

    return (data as List).map((row) => Opportunity(
      id: row['id'],
      type: row['type'] ?? 'general',
      title: row['title'],
      description: row['description'],
      eligibility: row['eligibility'] ?? '',
      deadline: DateTime.tryParse(row['deadline'] ?? '') ?? DateTime.now(),
      applyUrl: row['apply_url'],
      postedBy: row['posted_by'] ?? '',
      matchScore: row['match_score'] ?? 50,
    )).toList();
  }

  // ── Issues ───────────────────────────────────────────────────
  Future<IssueTicket> reportIssue({
    required String studentId,
    required String category,
    required String description,
    required String location,
    String? photoUrl,
  }) async {
    final assignedTo = _getAssignedDepartment(category);
    final row = {
      'student_id': studentId,
      'title': '${category[0].toUpperCase()}${category.substring(1)} Issue',
      'category': category,
      'description': description,
      'location': location,
      'image_url': photoUrl,
      'assigned_to': assignedTo,
    };

    final inserted = await _client
        .from('issues')
        .insert(row)
        .select()
        .single();

    return IssueTicket(
      ticketId: inserted['id'],
      studentId: inserted['student_id'],
      category: inserted['category'],
      description: inserted['description'],
      location: inserted['location'] ?? '',
      photoUrl: inserted['image_url'],
      status: inserted['status'] ?? 'logged',
      assignedTo: inserted['assigned_to'] ?? 'General Administration',
      submittedAt: DateTime.tryParse(inserted['created_at'] ?? ''),
    );
  }

  // ── Documents ────────────────────────────────────────────────
  Future<List<CampusDocument>> getDocuments(String studentId) async {
    final data = await _client
        .from('documents')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => CampusDocument(
      documentType: row['document_type'],
      fileUrl: row['file_url'],
      issuedOn: DateTime.tryParse(row['issued_on'] ?? '') ?? DateTime.now(),
      expiresOn: row['expires_on'] != null
          ? DateTime.tryParse(row['expires_on'])
          : null,
      verified: row['verified'] ?? false,
    )).toList();
  }

  Future<CampusDocument?> getDocument(String studentId, String documentType) async {
    final data = await _client
        .from('documents')
        .select()
        .eq('student_id', studentId)
        .eq('document_type', documentType)
        .maybeSingle();

    if (data == null) return null;
    return CampusDocument(
      documentType: data['document_type'],
      fileUrl: data['file_url'],
      issuedOn: DateTime.tryParse(data['issued_on'] ?? '') ?? DateTime.now(),
      expiresOn: data['expires_on'] != null
          ? DateTime.tryParse(data['expires_on'])
          : null,
      verified: data['verified'] ?? false,
    );
  }

  // ── Notifications ────────────────────────────────────────────
  Future<List<CampusNotification>> getNotifications(String studentId) async {
    final data = await _client
        .from('campus_notifications')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => CampusNotification(
      id: row['id'],
      type: row['type'] ?? 'system',
      title: row['title'],
      message: row['message'],
      timestamp: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
      read: row['read'] ?? false,
      actionUrl: row['action_url'],
    )).toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('campus_notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  Future<int> getUnreadNotificationCount(String studentId) async {
    final data = await _client
        .from('campus_notifications')
        .select('id')
        .eq('student_id', studentId)
        .eq('read', false);
    return (data as List).length;
  }

  /// Create a new notification for a user.
  Future<void> createNotification({
    required String studentId,
    required String type,
    required String title,
    required String message,
    String? actionUrl,
  }) async {
    await _client.from('campus_notifications').insert({
      'student_id': studentId,
      'type': type,
      'title': title,
      'message': message,
      'action_url': actionUrl,
      'read': false,
    });
  }

  /// Mark ALL notifications for a student as read.
  Future<void> markAllNotificationsRead(String studentId) async {
    await _client
        .from('campus_notifications')
        .update({'read': true})
        .eq('student_id', studentId)
        .eq('read', false);
  }

  // ── Update student profile ──────────────────────────────────
  /// Partial update – only sends the non-null keys.
  Future<void> updateStudentProfile(String studentId, Map<String, dynamic> data) async {
    debugPrint('[SupabaseService] updateStudentProfile($studentId) keys=${data.keys}');
    await _client
        .from('students')
        .update(data)
        .eq('student_id', studentId);
  }

  // ── Update clearance request status (staff approval) ───────
  /// Updates a single department status column and the overall status.
  Future<void> updateClearanceRequestStatus({
    required String requestId,
    required String deptKey,
    required String newStatus,
    required String overallStatus,
    String? remarks,
  }) async {
    final colName = '${deptKey}_status'; // e.g. library_status
    debugPrint('[SupabaseService] updateClearanceStatus($requestId) $colName=$newStatus overall=$overallStatus');
    await _client
        .from('clearance_requests')
        .update({
          colName: newStatus,
          'overall_status': overallStatus,
          'remarks': remarks,
        })
        .eq('id', requestId);
  }

  // ── Get ALL clearance requests (for staff view) ────────────
  Future<List<ClearanceRequest>> getAllClearanceRequestsForStaff() async {
    final data = await _client
        .from('clearance_requests')
        .select()
        .order('created_at', ascending: false);

    return (data as List).map((row) => _clearanceFromRow(row)).toList();
  }

  // ── Helpers ──────────────────────────────────────────────────
  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Student _studentFromRow(Map<String, dynamic> row) {
    return Student(
      id: row['student_id'],
      name: row['name'] ?? 'Unknown',
      department: row['department'] ?? 'General',
      year: row['year'] ?? 1,
      hostelResident: row['hostel'] ?? false,
      role: row['role'] ?? 'student',
      profileCompleted: row['profile_completed'] ?? false,
      staffDepartment: row['staff_department'],
      // Identity
      admissionNumber: row['admission_number'],
      gender: row['gender'],
      dateOfBirth: row['date_of_birth'] != null ? DateTime.tryParse(row['date_of_birth'].toString()) : null,
      bloodGroup: row['blood_group'],
      profileImageUrl: row['profile_image_url'],
      // Academic
      course: row['course'],
      branch: row['branch'],
      semester: row['semester'],
      batchYear: row['batch_year'],
      rollNumber: row['roll_number'],
      tutorName: row['tutor_name'],
      // Contact
      email: row['email'],
      phone: row['phone'],
      altPhone: row['alt_phone'],
      address: row['address'],
      city: row['city'],
      state: row['state'],
      postalCode: row['postal_code'],
      // Hostel
      hostelName: row['hostel_name'],
      roomNumber: row['room_number'],
      blockFloor: row['block_floor'],
      wardenName: row['warden_name'],
      // Guardian
      fatherName: row['father_name'],
      motherName: row['mother_name'],
      parentPhone: row['parent_phone'],
      guardianName: row['guardian_name'],
      guardianPhone: row['guardian_phone'],
      // Gov ID
      aadhaarNumber: row['aadhaar_number'],
      nationalId: row['national_id'],
      passportNumber: row['passport_number'],
      // Social
      religion: row['religion'],
      caste: row['caste'],
      category: row['category'],
      minorityStatus: row['minority_status'],
    );
  }

  ClearanceRequest _clearanceFromRow(Map<String, dynamic> row) {
    return ClearanceRequest(
      requestId: row['id'],
      studentId: row['student_id'],
      clearanceType: row['clearance_type'] ?? '',
      overallStatus: row['overall_status'] ?? 'pending',
      departmentStatuses: {
        'library': row['library_status'] ?? 'pending',
        'hostel': row['hostel_status'] ?? 'pending',
        'accounts': row['accounts_status'] ?? 'pending',
        'lab': row['lab_status'] ?? 'pending',
        'mess': row['mess_status'] ?? 'pending',
        'tutor': row['tutor_status'] ?? 'pending',
      },
      submittedAt: DateTime.tryParse(row['created_at'] ?? ''),
      estimatedCompletion: row['estimated_completion'] != null
          ? DateTime.tryParse(row['estimated_completion'])
          : null,
      remarks: row['remarks'],
    );
  }

  String _getAssignedDepartment(String category) {
    switch (category) {
      case 'infrastructure':
        return 'Estate & Maintenance';
      case 'hostel':
        return 'Hostel Administration';
      case 'internet':
        return 'IT Department';
      case 'cleanliness':
        return 'Housekeeping Department';
      case 'safety':
        return 'Campus Security';
      case 'canteen':
        return 'Canteen Management';
      case 'academics':
        return 'Department Admin';
      default:
        return 'General Administration';
    }
  }

  // ════════════════════════════════════════════════════════════
  // REALTIME SUBSCRIPTIONS — Full live database updates
  // ════════════════════════════════════════════════════════════

  // ── 1. Clearance Updates ──────────────────────────────────
  Stream<Map<String, dynamic>> subscribeToClearanceUpdates(String studentId) {
    unsubscribeClearance();
    debugPrint('[Realtime] ✓ Subscribing to clearance_requests for $studentId');

    _clearanceChannel = _client
        .channel('clearance_rt_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clearance_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('[Realtime] clearance event: ${payload.eventType.name}');
            _clearanceController.add({
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            });
          },
        )
        .subscribe();

    return _clearanceController.stream;
  }

  void unsubscribeClearance() {
    _clearanceChannel?.unsubscribe();
    _clearanceChannel = null;
  }

  // ── 1.5 Global Clearance Updates (Staff) ───────────────────
  Stream<Map<String, dynamic>> subscribeToAllClearanceUpdates() {
    unsubscribeGlobalClearance();
    debugPrint('[Realtime] ✓ Subscribing to ALL clearance_requests (global)');

    _globalClearanceChannel = _client
        .channel('clearance_global_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clearance_requests',
          callback: (payload) {
            debugPrint('[Realtime] global clearance event: ${payload.eventType.name}');
            _globalClearanceController.add({
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            });
          },
        )
        .subscribe();

    return _globalClearanceController.stream;
  }

  void unsubscribeGlobalClearance() {
    _globalClearanceChannel?.unsubscribe();
    _globalClearanceChannel = null;
  }

  // ── 2. Notification Alerts (INSERT / UPDATE) ──────────────
  Stream<Map<String, dynamic>> subscribeToNotifications(String studentId) {
    unsubscribeNotifications();
    debugPrint('[Realtime] ✓ Subscribing to campus_notifications for $studentId');

    _notificationChannel = _client
        .channel('notif_rt_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'campus_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('[Realtime] notification event: ${payload.eventType.name}');
            _notificationController.add({
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            });
          },
        )
        .subscribe();

    return _notificationController.stream;
  }

  void unsubscribeNotifications() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  // ── 3. Opportunities (INSERT — new scholarships/placements) ─
  Stream<Map<String, dynamic>> subscribeToOpportunities() {
    unsubscribeOpportunities();
    debugPrint('[Realtime] ✓ Subscribing to opportunities (global)');

    _opportunityChannel = _client
        .channel('oppo_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'opportunities',
          callback: (payload) {
            debugPrint('[Realtime] opportunity event: ${payload.eventType.name}');
            _opportunityController.add({
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
            });
          },
        )
        .subscribe();

    return _opportunityController.stream;
  }

  void unsubscribeOpportunities() {
    _opportunityChannel?.unsubscribe();
    _opportunityChannel = null;
  }

  // ── 4. Issue Status Updates ───────────────────────────────
  Stream<Map<String, dynamic>> subscribeToIssueUpdates(String studentId) {
    unsubscribeIssues();
    debugPrint('[Realtime] ✓ Subscribing to issues for $studentId');

    _issueChannel = _client
        .channel('issue_rt_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'issues',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('[Realtime] issue event: ${payload.eventType.name}');
            _issueController.add({
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            });
          },
        )
        .subscribe();

    return _issueController.stream;
  }

  void unsubscribeIssues() {
    _issueChannel?.unsubscribe();
    _issueChannel = null;
  }

  // ── 5. Student Profile/Dues Changes ───────────────────────
  Stream<Map<String, dynamic>> subscribeToStudentUpdates(String studentId) {
    unsubscribeStudent();
    debugPrint('[Realtime] ✓ Subscribing to students for $studentId');

    _studentChannel = _client
        .channel('student_rt_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'students',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('[Realtime] student event: ${payload.eventType.name}');
            _studentController.add({
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            });
          },
        )
        .subscribe();

    return _studentController.stream;
  }

  void unsubscribeStudent() {
    _studentChannel?.unsubscribe();
    _studentChannel = null;
  }

  // ── Unsubscribe ALL channels at once ──────────────────────
  void unsubscribeAll() {
    debugPrint('[Realtime] ✗ Unsubscribing from ALL channels');
    unsubscribeClearance();
    unsubscribeGlobalClearance();
    unsubscribeNotifications();
    unsubscribeOpportunities();
    unsubscribeIssues();
    unsubscribeStudent();
  }
}
