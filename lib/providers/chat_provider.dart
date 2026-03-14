import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/ai_engine.dart';
import '../services/campus_tools.dart';
import '../services/mock_data.dart';
import '../services/chat_storage.dart';
import '../services/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class ChatProvider extends ChangeNotifier {
  Student? _currentStudent;
  final List<ChatMessage> _messages = [];
  AIEngine? _engine;
  bool _isTyping = false;
  Timer? _streamTimer;
  String _searchQuery = '';

  // ── Realtime subscriptions ──────────────────────────────────
  StreamSubscription<Map<String, dynamic>>? _clearanceSub;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  StreamSubscription<Map<String, dynamic>>? _opportunitySub;
  StreamSubscription<Map<String, dynamic>>? _issueSub;
  StreamSubscription<Map<String, dynamic>>? _studentSub;

  /// Bumped on every realtime event so widgets can detect updates.
  int _realtimeRevision = 0;
  int get realtimeRevision => _realtimeRevision;

  /// Extra unread count bumped by live notification INSERTs (before cache refresh).
  int _liveUnreadBump = 0;

  // ── Data cache ───────────────────────────────────────────────
  DuesRecord? _cachedDues;
  PaymentSummary? _cachedPayment;
  List<CampusNotification>? _cachedNotifications;
  DateTime? _lastCacheRefresh;
  static const _cacheTtl = Duration(minutes: 2);
  bool _isCacheStale = true;

  Student? get currentStudent => _currentStudent;
  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  String get searchQuery => _searchQuery;

  // ── Cached data getters ──────────────────────────────────────
  DuesRecord get cachedDues {
    _ensureCacheFresh();
    return _cachedDues ?? DuesRecord();
  }

  PaymentSummary get cachedPayment {
    _ensureCacheFresh();
    return _cachedPayment ?? PaymentSummary();
  }

  List<CampusNotification> get cachedNotifications {
    _ensureCacheFresh();
    return _cachedNotifications ?? [];
  }

  int get unreadNotificationCount {
    return cachedNotifications.where((n) => !n.read).length + _liveUnreadBump;
  }

  void _ensureCacheFresh() {
    if (_currentStudent == null) return;
    if (_isCacheStale ||
        _lastCacheRefresh == null ||
        DateTime.now().difference(_lastCacheRefresh!) > _cacheTtl) {
      _refreshCacheSync();
    }
  }

  void _refreshCacheSync() {
    if (_currentStudent == null) return;
    _cachedDues = CampusTools.checkDues(_currentStudent!.id);
    _cachedPayment = CampusTools.getPaymentSummary(_currentStudent!.id);
    _cachedNotifications = CampusTools.getNotifications(_currentStudent!.id);
    _lastCacheRefresh = DateTime.now();
    _isCacheStale = false;
    _liveUnreadBump = 0;
  }

  /// Force refresh all cached data (async) and notify listeners.
  Future<void> refreshAllData() async {
    if (_currentStudent == null) return;
    final id = _currentStudent!.id;
    _cachedDues = await CampusTools.checkDuesAsync(id);
    _cachedPayment = await CampusTools.getPaymentSummaryAsync(id);
    _cachedNotifications = await CampusTools.getNotificationsAsync(id);
    _lastCacheRefresh = DateTime.now();
    _isCacheStale = false;
    _liveUnreadBump = 0;
    notifyListeners();
  }

  void invalidateCache() {
    _isCacheStale = true;
  }

  List<ChatMessage> get filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    return _messages
        .where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // ── Mock login (original) ───────────────────────────────────
  void login(String studentId) {
    _currentStudent = MockData.students[studentId];
    _currentStudent ??= Student(
      id: studentId,
      name: 'Demo Student',
      department: 'General',
      year: 1,
      hostelResident: false,
    );
    _autoFillTutor();
    _engine = AIEngine(studentId: _currentStudent!.id);
    _messages.clear();
    invalidateCache();

    _loadPreviousSession();
    _showWelcome();

    if (SupabaseConfig.useSupabase) {
      _subscribeToAll(_currentStudent!.id);
    }
  }

  // ── Supabase login ──────────────────────────────────────────
  Future<void> loginWithSupabase(String email, String password) async {
    final svc = SupabaseService.instance;
    await svc.signIn(email, password);

    // Try to get linked student profile
    Student? student = await svc.getStudentByAuthUid();

    // If no linked row yet (e.g. signed up but no profile row with auth_uid),
    // check by email metadata
    if (student == null) {
      final user = svc.currentUser;
      final meta = user?.userMetadata;
      final studentId = meta?['student_id'] as String?;
      if (studentId != null) {
        await svc.linkAuthToStudent(studentId);
        student = await svc.getStudentById(studentId);
      }
    }

    _currentStudent = student ?? Student(
      id: svc.currentUser?.id ?? 'unknown',
      name: svc.currentUser?.userMetadata?['name'] as String? ?? 'Student',
      department: 'General',
      year: 1,
      hostelResident: false,
    );
    _autoFillTutor();

    _engine = AIEngine(studentId: _currentStudent!.id);
    _messages.clear();
    invalidateCache();
    _loadPreviousSession();
    _showWelcome();

    // Subscribe to ALL real-time channels
    _subscribeToAll(_currentStudent!.id);
  }

  // ── Supabase sign up ────────────────────────────────────────
  /// Returns the auto-generated student ID.
  Future<String> signUpWithSupabase({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await SupabaseService.instance.signUp(
      email: email,
      password: password,
      name: name,
    );
    return result['studentId'] as String;
  }

  // ── Restore from persisted session ──────────────────────────
  Future<void> restoreSupabaseSession() async {
    final svc = SupabaseService.instance;
    Student? student = await svc.getStudentByAuthUid();
    _currentStudent = student ?? Student(
      id: svc.currentUser?.id ?? 'unknown',
      name: svc.currentUser?.userMetadata?['name'] as String? ?? 'Student',
      department: 'General',
      year: 1,
      hostelResident: false,
    );
    _engine = AIEngine(studentId: _currentStudent!.id);
    _messages.clear();
    invalidateCache();
    _loadPreviousSession();
    _showWelcome();

    // Subscribe to ALL real-time channels
    _subscribeToAll(_currentStudent!.id);
  }

  // ── Auto-fill tutor based on department ────────────────────
  static const _deptTutors = {
    'Computer Science': 'Dr. R. Krishnan (CSE Tutor)',
    'Electronics & Communication': 'Dr. S. Patel (ECE Tutor)',
    'Mechanical Engineering': 'Dr. A. Verma (ME Tutor)',
    'Civil Engineering': 'Dr. P. Nair (CE Tutor)',
    'Electrical & Electronics Engineering': 'Dr. M. Das (EEE Tutor)',
    'Information Technology': 'Dr. K. Sharma (IT Tutor)',
    'Applied Science': 'Dr. V. Iyer (AS Tutor)',
    'MBA': 'Dr. L. Reddy (MBA Tutor)',
  };

  void _autoFillTutor() {
    if (_currentStudent == null) return;
    final s = _currentStudent!;
    if (s.tutorName == null || s.tutorName!.isEmpty) {
      final tutor = _deptTutors[s.department];
      if (tutor != null) {
        _currentStudent = Student(
          id: s.id, name: s.name, department: s.department,
          year: s.year, hostelResident: s.hostelResident,
          role: s.role, staffDepartment: s.staffDepartment,
          profileCompleted: s.profileCompleted,
          admissionNumber: s.admissionNumber, gender: s.gender,
          dateOfBirth: s.dateOfBirth, bloodGroup: s.bloodGroup,
          profileImageUrl: s.profileImageUrl,
          course: s.course ?? 'BTech',
          branch: s.branch, semester: s.semester ?? 1,
          batchYear: s.batchYear, rollNumber: s.rollNumber,
          tutorName: tutor,
          email: s.email, phone: s.phone, altPhone: s.altPhone,
          address: s.address, city: s.city, state: s.state,
          postalCode: s.postalCode,
          hostelName: s.hostelName, roomNumber: s.roomNumber,
          blockFloor: s.blockFloor, wardenName: s.wardenName,
          fatherName: s.fatherName, motherName: s.motherName,
          parentPhone: s.parentPhone, guardianName: s.guardianName,
          guardianPhone: s.guardianPhone,
          aadhaarNumber: s.aadhaarNumber, nationalId: s.nationalId,
          passportNumber: s.passportNumber,
          religion: s.religion, caste: s.caste,
          category: s.category, minorityStatus: s.minorityStatus,
          incomeCertificateAvailable: s.incomeCertificateAvailable,
        );
        // Sync back to MockData
        MockData.updateStudent(s.id, _currentStudent!);
        debugPrint('[ChatProvider] Auto-filled tutorName: $tutor for ${s.id}');
      }
    }
  }

  // ── Refresh student profile (after registration update) ────
  Future<void> refreshStudentProfile() async {
    if (_currentStudent == null) return;
    if (SupabaseConfig.useSupabase) {
      final updated = await SupabaseService.instance.getStudentByAuthUid();
      if (updated != null) {
        _currentStudent = updated;
        // Keep MockData in sync so all in-memory consumers see the update
        MockData.updateStudent(updated.id, updated);
      }
    }
    _autoFillTutor();
    notifyListeners();
  }

  // ── Staff / Admin data helpers ──────────────────────────────
  /// Get all clearance requests (for staff/admin views).
  List<ClearanceRequest> get allClearanceRequests {
    return MockData.clearanceRequests;
  }

  /// Get pending clearances for a specific department.
  List<ClearanceRequest> getClearancesForDepartment(String department) {
    final deptKey = department.toLowerCase();
    return MockData.clearanceRequests.where((req) {
      final status = req.departmentStatuses[deptKey];
      return status == 'pending';
    }).toList();
  }

  // ── Logout ──────────────────────────────────────────────────
  void logout() {
    _saveSession();
    _streamTimer?.cancel();

    // Unsubscribe from ALL realtime channels
    _unsubscribeAll();

    if (SupabaseConfig.useSupabase) {
      SupabaseService.instance.signOut();
    }

    _currentStudent = null;
    _engine = null;
    _messages.clear();
    _isTyping = false;
    _searchQuery = '';
    _cachedDues = null;
    _cachedPayment = null;
    _cachedNotifications = null;
    _lastCacheRefresh = null;
    _isCacheStale = true;
    _liveUnreadBump = 0;
    _realtimeRevision = 0;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // REALTIME — Unified subscription to ALL tables
  // ════════════════════════════════════════════════════════════

  void _subscribeToAll(String studentId) {
    debugPrint('[ChatProvider] Setting up ALL realtime subscriptions for $studentId');

    final svc = SupabaseService.instance;

    // 1. Clearance
    _clearanceSub?.cancel();
    _clearanceSub = svc.subscribeToClearanceUpdates(studentId).listen((event) {
      debugPrint('[ChatProvider] ⚡ clearance realtime event: ${event['eventType']}');
      
      // If it's an UPDATE, mutate the in-memory ClearanceRequest so StatusTable rebuilds instantly
      if (event['eventType'] == 'UPDATE' && event['newRecord'] != null) {
        final newRecord = event['newRecord'] as Map<String, dynamic>;
        final reqId = newRecord['id'] as String?;
        if (reqId != null) {
          _updateInMemoryClearanceRequest(reqId, newRecord);
        }
      }
      _onRealtimeEvent();
    });

    // 2. Notifications
    _notificationSub?.cancel();
    _notificationSub = svc.subscribeToNotifications(studentId).listen((event) {
      debugPrint('[ChatProvider] ⚡ notification realtime event: ${event['eventType']}');
      if (event['eventType'] == 'INSERT') {
        // Instant unread bump so badge updates immediately
        _liveUnreadBump++;
        
        final newRecord = event['newRecord'];
        if (newRecord != null) {
          final title = newRecord['title']?.toString();
          final message = newRecord['message']?.toString();
          if (title != null && message != null) {
            // Show the popup notification on the recipient's phone
            NotificationService.showInstantNotification(
              title: title,
              body: message,
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            );
          }
        }
      }
      _onRealtimeEvent();
    });

    // 3. Opportunities
    _opportunitySub?.cancel();
    _opportunitySub = svc.subscribeToOpportunities().listen((_) {
      debugPrint('[ChatProvider] ⚡ opportunity realtime event');
      _onRealtimeEvent();
    });

    // 4. Issues
    _issueSub?.cancel();
    _issueSub = svc.subscribeToIssueUpdates(studentId).listen((_) {
      debugPrint('[ChatProvider] ⚡ issue realtime event');
      _onRealtimeEvent();
    });

    // 5. Student profile / dues changes
    _studentSub?.cancel();
    _studentSub = svc.subscribeToStudentUpdates(studentId).listen((_) async {
      debugPrint('[ChatProvider] ⚡ student realtime event (dues/profile changed)');
      // Also refresh the student object itself
      if (SupabaseConfig.useSupabase) {
        final updated = await svc.getStudentByAuthUid();
        if (updated != null) _currentStudent = updated;
      }
      _onRealtimeEvent();
    });
  }

  // ── Realtime Mutations ──────────────────────────────────────
  
  void _updateInMemoryClearanceRequest(String requestId, Map<String, dynamic> updatedRow) {
    debugPrint('[ChatProvider] Mutating matching ClearanceRequest in messages: $requestId');
    
    // Find the message that holds this clearance request in its data
    for (final msg in _messages) {
      if (msg.type == MessageType.statusTable && msg.data is ClearanceRequest) {
        final req = msg.data as ClearanceRequest;
        if (req.requestId == requestId) {
          // Mutate the object inplace so the UI reflects the new state immediately
          req.overallStatus = updatedRow['overall_status'] ?? req.overallStatus;
          req.remarks = updatedRow['remarks'] ?? req.remarks;
          
          if (updatedRow.containsKey('library_status')) req.departmentStatuses['library'] = updatedRow['library_status'];
          if (updatedRow.containsKey('hostel_status')) req.departmentStatuses['hostel'] = updatedRow['hostel_status'];
          if (updatedRow.containsKey('accounts_status')) req.departmentStatuses['accounts'] = updatedRow['accounts_status'];
          if (updatedRow.containsKey('lab_status')) req.departmentStatuses['lab'] = updatedRow['lab_status'];
          if (updatedRow.containsKey('mess_status')) req.departmentStatuses['mess'] = updatedRow['mess_status'];
          if (updatedRow.containsKey('tutor_status')) req.departmentStatuses['tutor'] = updatedRow['tutor_status'];
          
          debugPrint('[ChatProvider] Mutated StatusTable message to: ${req.overallStatus}');
          break; // Found it
        }
      }
    }
  }

  /// Shared handler for any realtime event — invalidate cache + bump revision.
  void _onRealtimeEvent() {
    invalidateCache();
    _realtimeRevision++;
    notifyListeners();
  }

  void _unsubscribeAll() {
    debugPrint('[ChatProvider] Tearing down ALL realtime subscriptions');
    _clearanceSub?.cancel();
    _clearanceSub = null;
    _notificationSub?.cancel();
    _notificationSub = null;
    _opportunitySub?.cancel();
    _opportunitySub = null;
    _issueSub?.cancel();
    _issueSub = null;
    _studentSub?.cancel();
    _studentSub = null;
    SupabaseService.instance.unsubscribeAll();
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      sender: MessageSender.user,
      text: text.trim(),
    ));
    _needsScroll = true;
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    _engine!.processMessage(text).then((responses) {
      _isTyping = false;

      for (final response in responses) {
        if (response.type == MessageType.text && response.data == null) {
          _streamMessage(response);
        } else {
          _messages.add(response);
        }
      }

      _needsScroll = true;
      invalidateCache(); // Message may have changed dues/clearance state
      notifyListeners();
      _saveSession();
    }).catchError((e) {
      _isTyping = false;
      _messages.add(ChatMessage(
        sender: MessageSender.assistant,
        text: 'Sorry, something went wrong. Please try again.',
      ));
      _needsScroll = true;
      notifyListeners();
    });
  }

  // ── Scroll control ─────────────────────────────────────────
  bool _needsScroll = false;
  bool get needsScroll => _needsScroll;
  void clearScrollFlag() => _needsScroll = false;

  void _streamMessage(ChatMessage original) {
    final words = original.text.split(' ');
    final streamMsg = ChatMessage(
      sender: MessageSender.assistant,
      text: '',
      isStreaming: true,
    );
    _messages.add(streamMsg);

    int wordIndex = 0;
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (wordIndex < words.length) {
        streamMsg.text += (wordIndex == 0 ? '' : ' ') + words[wordIndex];
        wordIndex++;
        _needsScroll = true;
        notifyListeners();
      } else {
        streamMsg.isStreaming = false;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void sendQuickAction(String action) {
    sendMessage(action);
  }

  // ── Private helpers ─────────────────────────────────────────

  void _showWelcome() {
    _isTyping = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      final welcomeMessages = _engine!.generateWelcome();
      _messages.addAll(welcomeMessages);
      _isTyping = false;
      _needsScroll = true;
      notifyListeners();
    });
  }

  // ── Chat Persistence ──────────────────────────────────────────

  Future<void> _saveSession() async {
    if (_currentStudent == null) return;
    await ChatStorage.saveChatSession(_currentStudent!.id, _messages);
  }

  Future<void> _loadPreviousSession() async {
    if (_currentStudent == null) return;
    final saved = await ChatStorage.loadChatSession(_currentStudent!.id);
    if (saved.isNotEmpty) {
      _messages.addAll(saved);
      _needsScroll = true;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    if (_currentStudent == null) return;
    await ChatStorage.deleteSession(_currentStudent!.id);
    _messages.clear();
    notifyListeners();
  }

  Future<List<String>> getSavedSessionIds() async {
    if (_currentStudent == null) return [];
    return ChatStorage.listSessionIds(_currentStudent!.id);
  }
}
