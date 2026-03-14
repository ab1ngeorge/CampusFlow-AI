// Models for CampusFlow AI

/// User roles for CampusFlow AI.
enum UserRole { student, staff, hod, tutor, officer, admin }

UserRole parseRole(String? role) {
  switch (role) {
    case 'staff':
      return UserRole.staff;
    case 'hod':
      return UserRole.hod;
    case 'tutor':
      return UserRole.tutor;
    case 'admin':
      return UserRole.admin;
    case 'officer':
      return UserRole.officer;
    default:
      return UserRole.student;
  }
}

class Student {
  final String id;
  final String name;
  final String department;
  final int year;
  final bool hostelResident;
  final String role;
  final UserRole userRole;
  final bool profileCompleted;
  final String? staffDepartment; // e.g. "Library", "Accounts" — for staff users

  // Basic Identity
  final String? admissionNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? profileImageUrl;

  // Academic
  final String? course;
  final String? branch;
  final int? semester;
  final int? batchYear;
  final String? rollNumber;
  final String? tutorName;

  // Contact
  final String? email;
  final String? phone;
  final String? altPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;

  // Hostel
  final String? hostelName;
  final String? roomNumber;
  final String? blockFloor;
  final String? wardenName;

  // Guardian
  final String? fatherName;
  final String? motherName;
  final String? parentPhone;
  final String? guardianName;
  final String? guardianPhone;

  // Government / Identity
  final String? aadhaarNumber;
  final String? nationalId;
  final String? passportNumber;

  // Social Category
  final String? religion;
  final String? caste;
  final String? category;
  final bool? minorityStatus;
  final bool? incomeCertificateAvailable;

  Student({
    required this.id,
    required this.name,
    required this.department,
    required this.year,
    required this.hostelResident,
    this.role = 'student',
    UserRole? userRole,
    this.profileCompleted = false,
    this.staffDepartment,
    this.admissionNumber,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.profileImageUrl,
    this.course,
    this.branch,
    this.semester,
    this.batchYear,
    this.rollNumber,
    this.tutorName,
    this.email,
    this.phone,
    this.altPhone,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.hostelName,
    this.roomNumber,
    this.blockFloor,
    this.wardenName,
    this.fatherName,
    this.motherName,
    this.parentPhone,
    this.guardianName,
    this.guardianPhone,
    this.aadhaarNumber,
    this.nationalId,
    this.passportNumber,
    this.religion,
    this.caste,
    this.category,
    this.minorityStatus,
    this.incomeCertificateAvailable,
  }) : userRole = userRole ?? parseRole(role);

  String get firstName => name.split(' ').first;

  // ── Academic profile completeness ─────────────────────────
  /// Fields required before academic requests (retest, etc.) are allowed.
  static const _requiredLabels = {
    'department': 'Department / Branch',
    'course': 'Course (e.g. BTech)',
    'semester': 'Semester',
    'tutorName': 'Tutor / Faculty Advisor',
    'contact': 'Email or Phone',
  };

  /// Returns the list of missing required field labels.
  List<String> get missingAcademicFields {
    final missing = <String>[];
    if (department.isEmpty) missing.add(_requiredLabels['department']!);
    if (course == null || course!.isEmpty) missing.add(_requiredLabels['course']!);
    if (semester == null || semester == 0) missing.add(_requiredLabels['semester']!);
    if (tutorName == null || tutorName!.isEmpty) missing.add(_requiredLabels['tutorName']!);
    if ((email == null || email!.isEmpty) && (phone == null || phone!.isEmpty)) {
      missing.add(_requiredLabels['contact']!);
    }
    return missing;
  }

  /// True when all required academic fields are populated.
  bool get isAcademicProfileComplete => missingAcademicFields.isEmpty;

  /// Profile completion percentage (0–100) for required academic fields.
  int get academicProfilePercent {
    final total = _requiredLabels.length;
    final filled = total - missingAcademicFields.length;
    return ((filled / total) * 100).round();
  }
}

class DuesRecord {
  final double libraryFine;
  final double hostelDues;
  final double labFees;
  final double tuitionBalance;
  final double messDues;
  final DateTime lastUpdated;

  DuesRecord({
    this.libraryFine = 0,
    this.hostelDues = 0,
    this.labFees = 0,
    this.tuitionBalance = 0,
    this.messDues = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  double get totalOutstanding =>
      libraryFine + hostelDues + labFees + tuitionBalance + messDues;

  bool get hasDues => totalOutstanding > 0;
}

class ClearanceRequest {
  final String requestId;
  final String studentId;
  final String clearanceType;
  String overallStatus; // submitted, in_progress, approved, rejected, on_hold
  Map<String, String> departmentStatuses;
  final DateTime submittedAt;
  DateTime? estimatedCompletion;
  String? remarks;

  ClearanceRequest({
    required this.requestId,
    required this.studentId,
    required this.clearanceType,
    this.overallStatus = 'submitted',
    Map<String, String>? departmentStatuses,
    DateTime? submittedAt,
    this.estimatedCompletion,
    this.remarks,
  })  : departmentStatuses = departmentStatuses ??
            {
              'library': 'pending',
              'hostel': 'pending',
              'accounts': 'pending',
              'tutor': 'pending',
            },
        submittedAt = submittedAt ?? DateTime.now();

  String get clearanceTypeDisplay {
    switch (clearanceType) {
      case 'transfer_certificate':
        return 'Transfer Certificate';
      case 'course_completion_certificate':
        return 'Course Completion Certificate';
      case 'bonafide_certificate':
        return 'Bonafide Certificate';
      case 'no_dues_certificate':
        return 'No Dues Certificate';
      case 'migration_certificate':
        return 'Migration Certificate';
      case 'conduct_certificate':
        return 'Conduct Certificate';
      default:
        return clearanceType;
    }
  }
}

class Opportunity {
  final String id;
  final String type; // scholarship, internship, placement, competition, workshop
  final String title;
  final String description;
  final String eligibility;
  final DateTime deadline;
  final String? applyUrl;
  final String postedBy;
  final int matchScore;

  Opportunity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.eligibility,
    required this.deadline,
    this.applyUrl,
    required this.postedBy,
    required this.matchScore,
  });

  bool get isUrgent => deadline.difference(DateTime.now()).inDays <= 7;

  String get typeEmoji {
    switch (type) {
      case 'scholarship':
        return '🎓';
      case 'internship':
        return '💼';
      case 'placement':
        return '🏢';
      case 'competition':
        return '🏆';
      case 'workshop':
        return '🔧';
      default:
        return '📋';
    }
  }
}

class Scholarship {
  final String id;
  final String type;           // 'scholarship' or 'egrant'
  final String name;
  final String provider;       // Government / Private / University
  final String description;
  final DateTime deadline;
  // Eligibility
  final String? eligibleCourse;     // BTech, MTech, MBA, etc.
  final String? eligibleDepartment; // optional
  final int? eligibleYear;          // null = all years
  final String? eligibleCategory;   // SC/ST/OBC/General/Minority/All
  final String? eligibleGender;     // Male/Female/All
  final double? incomeLimit;        // max family income, null = no limit
  final double? minMarksPercent;    // minimum marks %, null = no min
  final bool requiresIncomeCertificate; // whether income certificate is needed
  // Application
  final String? requiredDocuments;
  final String? applyUrl;
  final String? applicationProcess;
  final String? noticePdfUrl;
  final String postedBy;
  final DateTime postedAt;
  bool isActive;

  Scholarship({
    required this.id,
    required this.type,
    required this.name,
    required this.provider,
    required this.description,
    required this.deadline,
    this.eligibleCourse,
    this.eligibleDepartment,
    this.eligibleYear,
    this.eligibleCategory,
    this.eligibleGender,
    this.incomeLimit,
    this.minMarksPercent,
    this.requiresIncomeCertificate = false,
    this.requiredDocuments,
    this.applyUrl,
    this.applicationProcess,
    this.noticePdfUrl,
    required this.postedBy,
    DateTime? postedAt,
    this.isActive = true,
  }) : postedAt = postedAt ?? DateTime.now();

  String get typeLabel => type == 'egrant' ? 'e-Grant' : 'Scholarship';
  String get typeEmoji => type == 'egrant' ? '🏛️' : '🎓';
  bool get isExpired => deadline.isBefore(DateTime.now());
  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  /// AI eligibility check — returns true if the student matches criteria.
  bool isStudentEligible(Student student) {
    if (eligibleCourse != null && eligibleCourse!.isNotEmpty) {
      if (student.course == null || student.course!.toLowerCase() != eligibleCourse!.toLowerCase()) return false;
    }
    if (eligibleDepartment != null && eligibleDepartment!.isNotEmpty) {
      if (!student.department.toLowerCase().contains(eligibleDepartment!.toLowerCase())) return false;
    }
    if (eligibleYear != null && eligibleYear! > 0) {
      if (student.year != eligibleYear) return false;
    }
    if (eligibleCategory != null && eligibleCategory != 'All' && eligibleCategory!.isNotEmpty) {
      if (student.category == null || !student.category!.toLowerCase().contains(eligibleCategory!.toLowerCase())) return false;
    }
    if (eligibleGender != null && eligibleGender != 'All' && eligibleGender!.isNotEmpty) {
      if (student.gender == null || student.gender!.toLowerCase() != eligibleGender!.toLowerCase()) return false;
    }
    if (requiresIncomeCertificate) {
      if (student.incomeCertificateAvailable != true) return false;
    }
    return true;
  }
}

class PaymentRecord {
  final DateTime date;
  final double amount;
  final String type;
  final String receiptId;

  PaymentRecord({
    required this.date,
    required this.amount,
    required this.type,
    required this.receiptId,
  });
}

class PaymentSummary {
  final double tuitionPaid;
  final double tuitionBalance;
  final DateTime? tuitionNextDue;
  final double hostelPaid;
  final double hostelBalance;
  final DateTime? hostelNextDue;
  final double libraryFines;
  final double labFees;
  final List<PaymentRecord> paymentHistory;

  PaymentSummary({
    this.tuitionPaid = 0,
    this.tuitionBalance = 0,
    this.tuitionNextDue,
    this.hostelPaid = 0,
    this.hostelBalance = 0,
    this.hostelNextDue,
    this.libraryFines = 0,
    this.labFees = 0,
    this.paymentHistory = const [],
  });

  double get totalOutstanding =>
      tuitionBalance + hostelBalance + libraryFines + labFees;
}

class IssueTicket {
  final String ticketId;
  final String studentId;
  final String category;
  final String description;
  final String location;
  final String? photoUrl;
  final String status;
  final String assignedTo;
  final DateTime submittedAt;
  final String expectedResolution;

  IssueTicket({
    required this.ticketId,
    required this.studentId,
    required this.category,
    required this.description,
    required this.location,
    this.photoUrl,
    this.status = 'logged',
    required this.assignedTo,
    DateTime? submittedAt,
    this.expectedResolution = '48 hours',
  }) : submittedAt = submittedAt ?? DateTime.now();
}

class CampusDocument {
  final String documentType;
  final String fileUrl;
  final DateTime issuedOn;
  final DateTime? expiresOn;
  final bool verified;

  CampusDocument({
    required this.documentType,
    required this.fileUrl,
    required this.issuedOn,
    this.expiresOn,
    this.verified = true,
  });

  String get typeDisplay {
    switch (documentType) {
      case 'id_card':
        return 'ID Card';
      case 'bonafide_certificate':
        return 'Bonafide Certificate';
      case 'fee_receipt':
        return 'Fee Receipt';
      case 'mark_sheet':
        return 'Mark Sheet';
      case 'enrollment_certificate':
        return 'Enrollment Certificate';
      case 'transfer_certificate':
        return 'Transfer Certificate';
      case 'scholarship_letter':
        return 'Scholarship Letter';
      default:
        return documentType;
    }
  }
}

class CampusNotification {
  final String id;
  final String type; // due_reminder, clearance_update, opportunity, alert, system
  final String title;
  final String message;
  final DateTime timestamp;
  bool read;
  final String? actionUrl;

  CampusNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
    this.actionUrl,
  });

  String get typeIcon {
    switch (type) {
      case 'due_reminder':
        return '💰';
      case 'clearance_update':
        return '📋';
      case 'opportunity':
        return '🌟';
      case 'alert':
        return '⚠️';
      case 'system':
        return '🔔';
      default:
        return '📌';
    }
  }
}

class FAQResult {
  final String answer;
  final String source;
  final double confidence;
  final List<String> relatedTopics;

  FAQResult({
    required this.answer,
    required this.source,
    required this.confidence,
    this.relatedTopics = const [],
  });
}

// Chat message model
enum MessageSender { user, assistant }
enum MessageType { text, duesCard, statusTable, opportunityList, paymentSummary, documentInfo, notificationList, issueConfirm }

class ChatMessage {
  final String id;
  final MessageSender sender;
  String text; // Mutable for streaming animation
  final MessageType type;
  final dynamic data;
  final DateTime timestamp;
  bool isStreaming; // True while text is being streamed word-by-word

  ChatMessage({
    String? id,
    required this.sender,
    required this.text,
    this.type = MessageType.text,
    this.data,
    DateTime? timestamp,
    this.isStreaming = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender.index,
    'text': text,
    'type': type.index,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    sender: MessageSender.values[json['sender'] as int],
    text: json['text'] as String,
    type: MessageType.values[json['type'] as int],
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

// ── Retest Request Model ──────────────────────────────────────
class RetestRequest {
  final String requestId;
  final String studentId;
  final String studentName;
  final String department;
  final String subject;
  final DateTime examDate;
  final String reason;
  final String? documentUrl;
  String tutorStatus;   // pending, approved, rejected
  String hodStatus;     // pending, approved, rejected
  String finalStatus;   // pending_tutor, pending_hod, approved, declined
  String? tutorRemarks;
  String? hodRemarks;
  DateTime? retestDate;
  String? retestInstructions;
  final DateTime requestDate;

  RetestRequest({
    required this.requestId,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.subject,
    required this.examDate,
    required this.reason,
    this.documentUrl,
    this.tutorStatus = 'pending',
    this.hodStatus = 'pending',
    this.finalStatus = 'pending_tutor',
    this.tutorRemarks,
    this.hodRemarks,
    this.retestDate,
    this.retestInstructions,
    DateTime? requestDate,
  }) : requestDate = requestDate ?? DateTime.now();

  String get statusDisplay {
    switch (finalStatus) {
      case 'pending_tutor': return 'Pending (Tutor Approval)';
      case 'pending_hod':   return 'Pending (HOD Approval)';
      case 'approved':      return 'Approved';
      case 'declined':      return 'Declined';
      default:              return finalStatus;
    }
  }
}
