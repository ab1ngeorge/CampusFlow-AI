import 'dart:math';
import '../models/models.dart';
import 'mock_data.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

class CampusTools {
  static final List<ClearanceRequest> _submittedRequests = List.from(MockData.clearanceRequests);
  static final List<IssueTicket> _submittedIssues = [];

  // TOOL 1: check_dues
  static Future<DuesRecord> checkDuesAsync(String studentId) async {
    if (SupabaseConfig.useSupabase) {
      return await SupabaseService.instance.getDues(studentId);
    }
    return MockData.dues[studentId] ?? DuesRecord();
  }

  // Synchronous fallback — used by AI engine (always returns mock for now)
  static DuesRecord checkDues(String studentId) {
    return MockData.dues[studentId] ?? DuesRecord();
  }

  // TOOL 2: submit_clearance_request — with automated database verification
  static Future<ClearanceRequest> submitClearanceRequestAsync(String studentId, String clearanceType) async {
    final dues = await checkDuesAsync(studentId);
    Student? student;
    if (SupabaseConfig.useSupabase) {
      student = await SupabaseService.instance.getStudentById(studentId);
    } else {
      student = MockData.students[studentId];
    }
    final isHosteler = student?.hostelResident ?? false;

    // ── Auto-check each department database ──
    final deptStatuses = <String, String>{};
    final holdReasons = <String>[];

    // Library
    if (dues.libraryFine > 0) {
      deptStatuses['library'] = 'on_hold';
      holdReasons.add('Library fine: ₹${dues.libraryFine.toStringAsFixed(0)}');
    } else {
      deptStatuses['library'] = 'approved';
    }

    // Hostel
    if (isHosteler) {
      if (dues.hostelDues > 0) {
        deptStatuses['hostel'] = 'on_hold';
        holdReasons.add('Hostel dues: ₹${dues.hostelDues.toStringAsFixed(0)}');
      } else {
        deptStatuses['hostel'] = 'approved';
      }
    } else {
      deptStatuses['hostel'] = 'approved';
    }

    // Accounts
    if (dues.tuitionBalance > 0) {
      deptStatuses['accounts'] = 'on_hold';
      holdReasons.add('Tuition balance: ₹${dues.tuitionBalance.toStringAsFixed(0)}');
    } else {
      deptStatuses['accounts'] = 'approved';
    }

    // Lab
    if (dues.labFees > 0) {
      deptStatuses['lab'] = 'on_hold';
      holdReasons.add('Lab fees: ₹${dues.labFees.toStringAsFixed(0)}');
    } else {
      deptStatuses['lab'] = 'approved';
    }

    // Mess
    if (dues.messDues > 0) {
      deptStatuses['mess'] = 'on_hold';
      holdReasons.add('Mess dues: ₹${dues.messDues.toStringAsFixed(0)}');
    } else {
      deptStatuses['mess'] = 'approved';
    }

    // Tutor
    deptStatuses['tutor'] = 'approved';

    // ── Overall status ──
    final hasHolds = deptStatuses.values.any((s) => s == 'on_hold');
    final overallStatus = hasHolds ? 'on_hold' : 'approved';
    final estimatedDays = hasHolds ? 5 : 0;
    final remarks = hasHolds
        ? 'Action needed: ${holdReasons.join(', ')}. Clear dues to proceed.'
        : 'All departments verified and cleared. Auto-approved! No physical signatures required.';

    if (SupabaseConfig.useSupabase) {
      return await SupabaseService.instance.createClearanceRequest(
        studentId: studentId,
        clearanceType: clearanceType,
        departmentStatuses: deptStatuses,
        overallStatus: overallStatus,
        remarks: remarks,
        estimatedCompletion: DateTime.now().add(Duration(days: estimatedDays)),
      );
    }

    // Mock fallback
    final requestId = 'CLR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final request = ClearanceRequest(
      requestId: requestId,
      studentId: studentId,
      clearanceType: clearanceType,
      overallStatus: overallStatus,
      departmentStatuses: deptStatuses,
      estimatedCompletion: DateTime.now().add(Duration(days: estimatedDays)),
      remarks: remarks,
    );
    _submittedRequests.add(request);
    return request;
  }

  // Sync wrapper — kept for backward compatibility with AI engine
  static ClearanceRequest submitClearanceRequest(String studentId, String clearanceType) {
    final requestId = 'CLR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final dues = checkDues(studentId);
    final student = MockData.students[studentId];
    final isHosteler = student?.hostelResident ?? false;

    final deptStatuses = <String, String>{};
    final holdReasons = <String>[];

    if (dues.libraryFine > 0) {
      deptStatuses['library'] = 'on_hold';
      holdReasons.add('Library fine: ₹${dues.libraryFine.toStringAsFixed(0)}');
    } else {
      deptStatuses['library'] = 'approved';
    }

    if (isHosteler) {
      if (dues.hostelDues > 0) {
        deptStatuses['hostel'] = 'on_hold';
        holdReasons.add('Hostel dues: ₹${dues.hostelDues.toStringAsFixed(0)}');
      } else {
        deptStatuses['hostel'] = 'approved';
      }
    } else {
      deptStatuses['hostel'] = 'approved';
    }

    if (dues.tuitionBalance > 0) {
      deptStatuses['accounts'] = 'on_hold';
      holdReasons.add('Tuition balance: ₹${dues.tuitionBalance.toStringAsFixed(0)}');
    } else {
      deptStatuses['accounts'] = 'approved';
    }

    if (dues.labFees > 0) {
      deptStatuses['lab'] = 'on_hold';
      holdReasons.add('Lab fees: ₹${dues.labFees.toStringAsFixed(0)}');
    } else {
      deptStatuses['lab'] = 'approved';
    }

    if (dues.messDues > 0) {
      deptStatuses['mess'] = 'on_hold';
      holdReasons.add('Mess dues: ₹${dues.messDues.toStringAsFixed(0)}');
    } else {
      deptStatuses['mess'] = 'approved';
    }

    deptStatuses['tutor'] = 'approved';

    final hasHolds = deptStatuses.values.any((s) => s == 'on_hold');
    final overallStatus = hasHolds ? 'on_hold' : 'approved';
    final estimatedDays = hasHolds ? 5 : 0;
    final remarks = hasHolds
        ? 'Action needed: ${holdReasons.join(', ')}. Clear dues to proceed.'
        : 'All departments verified and cleared. Auto-approved! No physical signatures required.';

    final request = ClearanceRequest(
      requestId: requestId,
      studentId: studentId,
      clearanceType: clearanceType,
      overallStatus: overallStatus,
      departmentStatuses: deptStatuses,
      estimatedCompletion: DateTime.now().add(Duration(days: estimatedDays)),
      remarks: remarks,
    );
    _submittedRequests.add(request);
    return request;
  }

  // TOOL 3: get_clearance_status
  static Future<ClearanceRequest?> getClearanceStatusAsync(String studentId, String? requestId) async {
    if (SupabaseConfig.useSupabase) {
      final requests = await SupabaseService.instance.getClearanceRequests(studentId);
      if (requestId != null) {
        return requests.where((r) => r.requestId == requestId).firstOrNull;
      }
      return requests.isNotEmpty ? requests.first : null;
    }
    return getClearanceStatus(studentId, requestId);
  }

  static ClearanceRequest? getClearanceStatus(String studentId, String? requestId) {
    if (requestId != null) {
      return _submittedRequests.where(
        (r) => r.requestId == requestId && r.studentId == studentId,
      ).firstOrNull;
    }
    final studentRequests = _submittedRequests
        .where((r) => r.studentId == studentId)
        .toList();
    if (studentRequests.isEmpty) return null;
    studentRequests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return studentRequests.first;
  }

  static List<ClearanceRequest> getAllClearanceRequests(String studentId) {
    return _submittedRequests.where((r) => r.studentId == studentId).toList();
  }

  // TOOL 4: list_opportunities
  static Future<List<Opportunity>> listOpportunitiesAsync(String studentId) async {
    if (SupabaseConfig.useSupabase) {
      return await SupabaseService.instance.getOpportunities();
    }
    return listOpportunities(studentId);
  }

  static List<Opportunity> listOpportunities(String studentId) {
    final student = MockData.students[studentId];
    if (student == null) return [];
    List<Opportunity> matched = List.from(MockData.opportunities);
    matched.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return matched;
  }

  // TOOL 5: get_payment_summary
  static Future<PaymentSummary> getPaymentSummaryAsync(String studentId) async {
    if (SupabaseConfig.useSupabase) {
      // Future: fetch from Supabase
    }
    return getPaymentSummary(studentId);
  }

  static PaymentSummary getPaymentSummary(String studentId) {
    return MockData.paymentSummaries[studentId] ?? PaymentSummary();
  }

  // TOOL 6: report_issue
  static Future<IssueTicket> reportIssueAsync({
    required String studentId,
    required String category,
    required String description,
    required String location,
    String? photoUrl,
  }) async {
    if (SupabaseConfig.useSupabase) {
      return await SupabaseService.instance.reportIssue(
        studentId: studentId,
        category: category,
        description: description,
        location: location,
        photoUrl: photoUrl,
      );
    }
    return reportIssue(
      studentId: studentId,
      category: category,
      description: description,
      location: location,
      photoUrl: photoUrl,
    );
  }

  static IssueTicket reportIssue({
    required String studentId,
    required String category,
    required String description,
    required String location,
    String? photoUrl,
  }) {
    final ticketId = 'ISS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final assignedTo = _getAssignedDepartment(category);
    final ticket = IssueTicket(
      ticketId: ticketId,
      studentId: studentId,
      category: category,
      description: description,
      location: location,
      photoUrl: photoUrl,
      assignedTo: assignedTo,
    );
    _submittedIssues.add(ticket);
    return ticket;
  }

  // TOOL 7: get_document
  static Future<CampusDocument?> getDocumentAsync(String studentId, String documentType) async {
    if (SupabaseConfig.useSupabase) {
      return await SupabaseService.instance.getDocument(studentId, documentType);
    }
    return getDocument(studentId, documentType);
  }

  static CampusDocument? getDocument(String studentId, String documentType) {
    final docs = MockData.documents[studentId];
    if (docs == null) return null;
    return docs.where((d) => d.documentType == documentType).firstOrNull;
  }

  static Future<List<CampusDocument>> getAllDocumentsAsync(String studentId) async {
    if (SupabaseConfig.useSupabase) {
      return await SupabaseService.instance.getDocuments(studentId);
    }
    return getAllDocuments(studentId);
  }

  static List<CampusDocument> getAllDocuments(String studentId) {
    return MockData.documents[studentId] ?? [];
  }

  // TOOL 8: get_faq
  static FAQResult getFaq(String query) {
    final queryLower = query.toLowerCase();
    double bestScore = 0;
    Map<String, dynamic>? bestMatch;

    for (final faq in MockData.faqs) {
      final keywords = faq['keywords'] as List<String>;
      int matchCount = 0;
      for (final keyword in keywords) {
        if (queryLower.contains(keyword.toLowerCase())) {
          matchCount++;
        }
      }
      final score = matchCount / keywords.length;
      if (score > bestScore) {
        bestScore = score;
        bestMatch = faq;
      }
    }

    if (bestMatch != null && bestScore > 0) {
      return FAQResult(
        answer: bestMatch['answer'] as String,
        source: bestMatch['source'] as String,
        confidence: min(bestScore * 1.5, 1.0),
        relatedTopics: List<String>.from(bestMatch['related'] ?? []),
      );
    }

    return FAQResult(
      answer: 'I don\'t have specific information about that in my knowledge base.',
      source: 'General',
      confidence: 0.0,
      relatedTopics: [],
    );
  }

  // TOOL 9: get_notifications
  static Future<List<CampusNotification>> getNotificationsAsync(String studentId) async {
    if (SupabaseConfig.useSupabase) {
      return await SupabaseService.instance.getNotifications(studentId);
    }
    return getNotifications(studentId);
  }

  static List<CampusNotification> getNotifications(String studentId) {
    return MockData.notifications[studentId] ?? [];
  }

  static int getUnreadCount(String studentId) {
    final notifs = getNotifications(studentId);
    return notifs.where((n) => !n.read).length;
  }

  static Future<void> markNotificationReadAsync(String studentId, String notificationId) async {
    if (SupabaseConfig.useSupabase) {
      await SupabaseService.instance.markNotificationRead(notificationId);
      return;
    }
    markNotificationRead(studentId, notificationId);
  }

  static void markNotificationRead(String studentId, String notificationId) {
    final notifs = MockData.notifications[studentId];
    if (notifs != null) {
      for (var n in notifs) {
        if (n.id == notificationId) {
          n.read = true;
          break;
        }
      }
    }
  }

  /// Mark ALL notifications as read for a student.
  static Future<void> markAllNotificationsReadAsync(String studentId) async {
    // In-memory
    final notifs = MockData.notifications[studentId];
    if (notifs != null) {
      for (var n in notifs) {
        n.read = true;
      }
    }
    // Supabase
    if (SupabaseConfig.useSupabase) {
      await SupabaseService.instance.markAllNotificationsRead(studentId);
    }
  }

  // Helper function
  static String _getAssignedDepartment(String category) {
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
}
