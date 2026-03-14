import '../models/models.dart';

class MockData {
  // ── Demo credentials: username → { password, userId } ──────
  static final Map<String, Map<String, String>> credentials = {
    // Department HODs
    'hod.cse':   {'password': 'HOD@123',       'userId': 'HOD-CSE'},
    'hod.ece':   {'password': 'HOD@123',       'userId': 'HOD-ECE'},
    'hod.me':    {'password': 'HOD@123',       'userId': 'HOD-ME'},
    'hod.ce':    {'password': 'HOD@123',       'userId': 'HOD-CE'},
    'hod.eee':   {'password': 'HOD@123',       'userId': 'HOD-EEE'},
    'hod.it':    {'password': 'HOD@123',       'userId': 'HOD-IT'},
    'hod.as':    {'password': 'HOD@123',       'userId': 'HOD-AS'},
    // Department Tutors
    'tutor.cse': {'password': 'Tutor@123',     'userId': 'TUTOR-CSE'},
    'tutor.ece': {'password': 'Tutor@123',     'userId': 'TUTOR-ECE'},
    'tutor.me':  {'password': 'Tutor@123',     'userId': 'TUTOR-ME'},
    'tutor.ce':  {'password': 'Tutor@123',     'userId': 'TUTOR-CE'},
    'tutor.eee': {'password': 'Tutor@123',     'userId': 'TUTOR-EEE'},
    'tutor.it':  {'password': 'Tutor@123',     'userId': 'TUTOR-IT'},
    'tutor.as':  {'password': 'Tutor@123',     'userId': 'TUTOR-AS'},
    // College-level staff
    'placement.office': {'password': 'Placement@123', 'userId': 'STAFF-PLACE'},
    'hostel.office':    {'password': 'Hostel@123',    'userId': 'STAFF-HOSTEL'},
    'accounts.office':  {'password': 'Accounts@123',  'userId': 'STAFF-ACCT'},
    'library.staff':    {'password': 'Library@123',   'userId': 'STAFF-LIB'},
    'sports.office':    {'password': 'Sports@123',    'userId': 'STAFF-SPORTS'},
    // Scholarship Officer
    'officer':          {'password': 'Officer@123',   'userId': 'OFFICER-001'},
    // Admin
    'admin':            {'password': 'Admin@123',     'userId': 'ADMIN-001'},
  };

  // ── All users ──────────────────────────────────────────────
  static final Map<String, Student> students = {
    // ── Student demo accounts ───────────────────────────────
    'STU-001001': Student(
      id: 'STU-001001',
      name: 'Arjun Sharma',
      department: 'Computer Science',
      year: 3,
      hostelResident: true,
      course: 'BTech',
      semester: 6,
      tutorName: 'Prof. Deepa Thomas',
      email: 'arjun.sharma@campus.edu',
      phone: '9876543210',
      category: 'OBC',
      incomeCertificateAvailable: true,
    ),
    'STU-001002': Student(
      id: 'STU-001002',
      name: 'Priya Nair',
      department: 'Electronics & Communication',
      year: 2,
      hostelResident: false,
      course: 'BTech',
      semester: 4,
      tutorName: 'Prof. Ramesh Babu',
      email: 'priya.nair@campus.edu',
      category: 'SC',
      incomeCertificateAvailable: true,
    ),
    'STU-001003': Student(
      id: 'STU-001003',
      name: 'Ravi Kumar',
      department: 'MBA',
      year: 1,
      hostelResident: true,
      course: 'MBA',
      semester: 2,
      tutorName: 'Dr. L. Reddy (MBA Tutor)',
      email: 'ravi.kumar@campus.edu',
      phone: '9123456780',
      category: 'General',
    ),

    // ── HOD accounts (per department) ────────────────────────
    'HOD-CSE': Student(
      id: 'HOD-CSE', name: 'Dr. Anand Krishnan', department: 'Computer Science',
      year: 0, hostelResident: false, role: 'hod', staffDepartment: 'Computer Science',
    ),
    'HOD-ECE': Student(
      id: 'HOD-ECE', name: 'Dr. Mary Reena K E', department: 'Electronics & Communication',
      year: 0, hostelResident: false, role: 'hod', staffDepartment: 'Electronics & Communication',
    ),
    'HOD-ME': Student(
      id: 'HOD-ME', name: 'Dr. Manoj Kumar C V', department: 'Mechanical Engineering',
      year: 0, hostelResident: false, role: 'hod', staffDepartment: 'Mechanical Engineering',
    ),
    'HOD-CE': Student(
      id: 'HOD-CE', name: 'Dr. Anjali M S', department: 'Civil Engineering',
      year: 0, hostelResident: false, role: 'hod', staffDepartment: 'Civil Engineering',
    ),
    'HOD-EEE': Student(
      id: 'HOD-EEE', name: 'Prof. Jayakumar M', department: 'Electrical & Electronics Engineering',
      year: 0, hostelResident: false, role: 'hod', staffDepartment: 'Electrical & Electronics Engineering',
    ),
    'HOD-IT': Student(
      id: 'HOD-IT', name: 'Dr. Anver S R', department: 'Information Technology',
      year: 0, hostelResident: false, role: 'hod', staffDepartment: 'Information Technology',
    ),
    'HOD-AS': Student(
      id: 'HOD-AS', name: 'Prof. Vineesh Kumar A V', department: 'Applied Science',
      year: 0, hostelResident: false, role: 'hod', staffDepartment: 'Applied Science',
    ),

    // ── Tutor accounts (per department) ──────────────────────
    'TUTOR-CSE': Student(
      id: 'TUTOR-CSE', name: 'Prof. Deepa Thomas', department: 'Computer Science',
      year: 0, hostelResident: false, role: 'tutor', staffDepartment: 'Computer Science',
    ),
    'TUTOR-ECE': Student(
      id: 'TUTOR-ECE', name: 'Prof. Ramesh Babu', department: 'Electronics & Communication',
      year: 0, hostelResident: false, role: 'tutor', staffDepartment: 'Electronics & Communication',
    ),
    'TUTOR-ME': Student(
      id: 'TUTOR-ME', name: 'Prof. Ajith Kumar', department: 'Mechanical Engineering',
      year: 0, hostelResident: false, role: 'tutor', staffDepartment: 'Mechanical Engineering',
    ),
    'TUTOR-CE': Student(
      id: 'TUTOR-CE', name: 'Prof. Smitha Das', department: 'Civil Engineering',
      year: 0, hostelResident: false, role: 'tutor', staffDepartment: 'Civil Engineering',
    ),
    'TUTOR-EEE': Student(
      id: 'TUTOR-EEE', name: 'Prof. Manoj George', department: 'Electrical & Electronics Engineering',
      year: 0, hostelResident: false, role: 'tutor', staffDepartment: 'Electrical & Electronics Engineering',
    ),
    'TUTOR-IT': Student(
      id: 'TUTOR-IT', name: 'Prof. Santhosh Nair', department: 'Information Technology',
      year: 0, hostelResident: false, role: 'tutor', staffDepartment: 'Information Technology',
    ),
    'TUTOR-AS': Student(
      id: 'TUTOR-AS', name: 'Prof. Lekha Menon', department: 'Applied Science',
      year: 0, hostelResident: false, role: 'tutor', staffDepartment: 'Applied Science',
    ),

    // ── College-level staff ──────────────────────────────────
    'STAFF-PLACE': Student(
      id: 'STAFF-PLACE', name: 'Mrs. Anjali Mohan', department: 'Placement Cell',
      year: 0, hostelResident: false, role: 'staff', staffDepartment: 'Placement',
    ),
    'STAFF-HOSTEL': Student(
      id: 'STAFF-HOSTEL', name: 'Mr. Prasad Nambiar', department: 'Hostel Office',
      year: 0, hostelResident: false, role: 'staff', staffDepartment: 'Hostel',
    ),
    'STAFF-ACCT': Student(
      id: 'STAFF-ACCT', name: 'Mrs. Sujatha Pillai', department: 'Accounts Office',
      year: 0, hostelResident: false, role: 'staff', staffDepartment: 'Accounts',
    ),
    'STAFF-LIB': Student(
      id: 'STAFF-LIB', name: 'Dr. Meena Iyer', department: 'Library',
      year: 0, hostelResident: false, role: 'staff', staffDepartment: 'Library',
    ),
    'STAFF-SPORTS': Student(
      id: 'STAFF-SPORTS', name: 'Mr. Hari Shankar', department: 'Physical Education',
      year: 0, hostelResident: false, role: 'staff', staffDepartment: 'Sports',
    ),

    // ── Scholarship Officer ─────────────────────────────────
    'OFFICER-001': Student(
      id: 'OFFICER-001',
      name: 'Mrs. Reshma Pillai',
      department: 'Scholarship Cell',
      year: 0,
      hostelResident: false,
      role: 'officer',
      staffDepartment: 'Scholarship',
    ),

    // ── System Administrator ─────────────────────────────────
    'ADMIN-001': Student(
      id: 'ADMIN-001',
      name: 'Prof. Suresh Nambiar',
      department: 'Administration',
      year: 0,
      hostelResident: false,
      role: 'admin',
    ),
  };

  // ── Retest Requests ───────────────────────────────────────
  static final List<RetestRequest> retestRequests = [
    RetestRequest(
      requestId: 'RT-001',
      studentId: 'STU-001001',
      studentName: 'Arjun Sharma',
      department: 'Computer Science',
      subject: 'Data Structures',
      examDate: DateTime(2026, 2, 15),
      reason: 'I missed the exam due to a medical emergency. Was hospitalized for 3 days.',
      documentUrl: 'medical_certificate.pdf',
      tutorStatus: 'approved',
      hodStatus: 'pending',
      finalStatus: 'pending_hod',
      tutorRemarks: 'Student has valid medical certificate. Recommending approval.',
      requestDate: DateTime(2026, 3, 10),
    ),
    RetestRequest(
      requestId: 'RT-002',
      studentId: 'STU-001002',
      studentName: 'Priya Nair',
      department: 'Electronics & Communication',
      subject: 'Digital Signal Processing',
      examDate: DateTime(2026, 2, 18),
      reason: 'Family emergency. Had to travel urgently.',
      finalStatus: 'pending_tutor',
      requestDate: DateTime(2026, 3, 12),
    ),
    RetestRequest(
      requestId: 'RT-003',
      studentId: 'STU-001001',
      studentName: 'Arjun Sharma',
      department: 'Computer Science',
      subject: 'Computer Networks',
      examDate: DateTime(2026, 1, 20),
      reason: 'Was representing the college in a national sports event.',
      documentUrl: 'sports_participation.pdf',
      tutorStatus: 'approved',
      hodStatus: 'approved',
      finalStatus: 'approved',
      tutorRemarks: 'Verified sports duty leave.',
      hodRemarks: 'Approved. Schedule retest within 2 weeks.',
      retestDate: DateTime(2026, 3, 25),
      retestInstructions: 'Report to Exam Hall 3 at 10:00 AM. Carry your ID card.',
      requestDate: DateTime(2026, 2, 28),
    ),
  ];

  // Dues
  static final Map<String, DuesRecord> dues = {
    'STU-001001': DuesRecord(
      libraryFine: 150,
      hostelDues: 2400,
      labFees: 0,
      tuitionBalance: 0,
      messDues: 800,
    ),
    'STU-001002': DuesRecord(
      libraryFine: 0,
      hostelDues: 0,
      labFees: 500,
      tuitionBalance: 12000,
      messDues: 0,
    ),
    'STU-001003': DuesRecord(
      libraryFine: 0,
      hostelDues: 0,
      labFees: 0,
      tuitionBalance: 0,
      messDues: 0,
    ),
  };

  // Existing clearance requests
  static final List<ClearanceRequest> clearanceRequests = [
    ClearanceRequest(
      requestId: 'CLR-20260301',
      studentId: 'STU-001001',
      clearanceType: 'bonafide_certificate',
      overallStatus: 'in_progress',
      departmentStatuses: {
        'library': 'approved',
        'hostel': 'pending',
        'accounts': 'approved',
        'tutor': 'pending',
      },
      submittedAt: DateTime(2026, 3, 1),
      estimatedCompletion: DateTime(2026, 3, 20),
    ),
  ];

  // Opportunities
  static final List<Opportunity> opportunities = [
    Opportunity(
      id: 'OPP-1001',
      type: 'scholarship',
      title: 'Merit-cum-Means Scholarship 2026',
      description: 'Annual scholarship for students with excellent academic performance and financial need.',
      eligibility: 'CGPA ≥ 8.5, Annual family income < ₹5,00,000',
      deadline: DateTime(2026, 3, 22),
      applyUrl: 'https://campus.edu/scholarships/mcm-2026',
      postedBy: 'Scholarship Cell',
      matchScore: 92,
    ),
    Opportunity(
      id: 'OPP-1002',
      type: 'internship',
      title: 'Google Summer of Code 2026',
      description: 'Contribute to open-source projects with mentorship from Google engineers.',
      eligibility: 'CS/IT students, Year 2+',
      deadline: DateTime(2026, 4, 5),
      applyUrl: 'https://summerofcode.withgoogle.com',
      postedBy: 'Placement Cell',
      matchScore: 88,
    ),
    Opportunity(
      id: 'OPP-1003',
      type: 'placement',
      title: 'TCS Recruitment Drive — On-Campus',
      description: 'Campus placement drive for final year students. Package: ₹7-12 LPA.',
      eligibility: 'Final year, CGPA ≥ 7.0, No active backlogs',
      deadline: DateTime(2026, 3, 28),
      applyUrl: null,
      postedBy: 'Placement Cell',
      matchScore: 75,
    ),
    Opportunity(
      id: 'OPP-1004',
      type: 'competition',
      title: 'National Hackathon — HackIndia 2026',
      description: 'Build innovative solutions in 48 hours. Prizes worth ₹5,00,000.',
      eligibility: 'All departments, Team of 2-4',
      deadline: DateTime(2026, 3, 18),
      applyUrl: 'https://hackindia.xyz',
      postedBy: 'Student Council',
      matchScore: 85,
    ),
    Opportunity(
      id: 'OPP-1005',
      type: 'workshop',
      title: 'AI & Machine Learning Bootcamp',
      description: '3-day intensive workshop on ML fundamentals with hands-on projects.',
      eligibility: 'CS/ECE students, Year 2+',
      deadline: DateTime(2026, 3, 25),
      postedBy: 'CSE Department',
      matchScore: 90,
    ),
  ];

  // ── Scholarships (managed by Officer) ────────────────────────
  static final List<Scholarship> scholarships = [
    Scholarship(
      id: 'SCH-001',
      type: 'egrant',
      name: 'Kerala State e-Grant',
      provider: 'Government of Kerala',
      description: 'Financial aid for undergraduate students from economically weaker sections in Kerala.',
      deadline: DateTime(2026, 6, 30),
      eligibleCourse: 'BTech',
      eligibleCategory: 'SC',
      incomeLimit: 200000,
      requiresIncomeCertificate: true,
      requiredDocuments: 'Income Certificate, Caste Certificate, Aadhaar, Mark Sheet',
      applyUrl: 'https://egrantz.kerala.gov.in',
      applicationProcess: 'Apply online through the e-Grantz portal. Submit certified copies to the Scholarship Cell.',
      postedBy: 'Scholarship Cell',
    ),
    Scholarship(
      id: 'SCH-002',
      type: 'scholarship',
      name: 'Merit-cum-Means Scholarship',
      provider: 'University',
      description: 'Annual scholarship for students with excellent academic performance and financial need.',
      deadline: DateTime(2026, 4, 15),
      eligibleCourse: 'BTech',
      minMarksPercent: 85,
      incomeLimit: 500000,
      eligibleCategory: 'All',
      requiredDocuments: 'Mark Sheet, Income Certificate, College ID',
      applyUrl: 'https://campus.edu/scholarships/mcm-2026',
      applicationProcess: 'Apply through the Scholarship Cell. Interview may be required.',
      postedBy: 'Scholarship Cell',
    ),
  ];

  // Payment history
  static final Map<String, PaymentSummary> paymentSummaries = {
    'STU-001001': PaymentSummary(
      tuitionPaid: 88000,
      tuitionBalance: 0,
      tuitionNextDue: DateTime(2026, 7, 1),
      hostelPaid: 22600,
      hostelBalance: 2400,
      hostelNextDue: DateTime(2026, 4, 1),
      libraryFines: 150,
      labFees: 0,
      paymentHistory: [
        PaymentRecord(date: DateTime(2026, 1, 15), amount: 44000, type: 'Tuition - Sem 5', receiptId: 'RCP-2026-0115'),
        PaymentRecord(date: DateTime(2026, 1, 15), amount: 12000, type: 'Hostel - Sem 5', receiptId: 'RCP-2026-0116'),
        PaymentRecord(date: DateTime(2025, 7, 10), amount: 44000, type: 'Tuition - Sem 4', receiptId: 'RCP-2025-0710'),
        PaymentRecord(date: DateTime(2025, 7, 10), amount: 10600, type: 'Hostel - Sem 4', receiptId: 'RCP-2025-0711'),
      ],
    ),
    'STU-001002': PaymentSummary(
      tuitionPaid: 32000,
      tuitionBalance: 12000,
      tuitionNextDue: DateTime(2026, 3, 31),
      hostelPaid: 0,
      hostelBalance: 0,
      libraryFines: 0,
      labFees: 500,
      paymentHistory: [
        PaymentRecord(date: DateTime(2026, 1, 20), amount: 32000, type: 'Tuition - Sem 3', receiptId: 'RCP-2026-0120'),
      ],
    ),
    'STU-001003': PaymentSummary(
      tuitionPaid: 75000,
      tuitionBalance: 0,
      tuitionNextDue: DateTime(2026, 7, 1),
      hostelPaid: 15000,
      hostelBalance: 0,
      hostelNextDue: DateTime(2026, 7, 1),
      libraryFines: 0,
      labFees: 0,
      paymentHistory: [
        PaymentRecord(date: DateTime(2026, 1, 5), amount: 75000, type: 'Tuition - Sem 1', receiptId: 'RCP-2026-0105'),
        PaymentRecord(date: DateTime(2026, 1, 5), amount: 15000, type: 'Hostel - Sem 1', receiptId: 'RCP-2026-0106'),
      ],
    ),
  };

  // Documents
  static final Map<String, List<CampusDocument>> documents = {
    'STU-001001': [
      CampusDocument(
        documentType: 'id_card',
        fileUrl: 'https://campus.edu/docs/STU-001001/id_card.pdf',
        issuedOn: DateTime(2024, 8, 1),
        expiresOn: DateTime(2027, 7, 31),
        verified: true,
      ),
      CampusDocument(
        documentType: 'fee_receipt',
        fileUrl: 'https://campus.edu/docs/STU-001001/fee_receipt_sem5.pdf',
        issuedOn: DateTime(2026, 1, 15),
        verified: true,
      ),
      CampusDocument(
        documentType: 'mark_sheet',
        fileUrl: 'https://campus.edu/docs/STU-001001/marksheet_sem4.pdf',
        issuedOn: DateTime(2025, 12, 20),
        verified: true,
      ),
    ],
    'STU-001002': [
      CampusDocument(
        documentType: 'id_card',
        fileUrl: 'https://campus.edu/docs/STU-001002/id_card.pdf',
        issuedOn: DateTime(2025, 8, 1),
        expiresOn: DateTime(2027, 7, 31),
        verified: true,
      ),
      CampusDocument(
        documentType: 'enrollment_certificate',
        fileUrl: 'https://campus.edu/docs/STU-001002/enrollment.pdf',
        issuedOn: DateTime(2025, 8, 15),
        verified: true,
      ),
    ],
    'STU-001003': [
      CampusDocument(
        documentType: 'id_card',
        fileUrl: 'https://campus.edu/docs/STU-001003/id_card.pdf',
        issuedOn: DateTime(2026, 1, 10),
        expiresOn: DateTime(2028, 7, 31),
        verified: true,
      ),
    ],
  };

  // FAQs
  static final List<Map<String, dynamic>> faqs = [
    {
      'keywords': ['library', 'timing', 'hours', 'open', 'close', 'library timings'],
      'answer': 'The Central Library is open from 8:00 AM to 10:00 PM on weekdays, and 9:00 AM to 6:00 PM on weekends. During exam season, extended hours (till midnight) are available.',
      'source': 'Library Department',
      'related': ['Library fine policy', 'Book borrowing limits'],
    },
    {
      'keywords': ['hostel', 'apply', 'admission', 'room', 'allotment'],
      'answer': 'Hostel applications open every June for the upcoming academic year. Apply through the Student Portal → Hostel Services → New Application. Allotment is based on distance from campus and academic standing. Current residents get priority for retention.',
      'source': 'Hostel Administration',
      'related': ['Hostel fees', 'Mess menu', 'Room change policy'],
    },
    {
      'keywords': ['exam', 'schedule', 'timetable', 'exam date', 'examination'],
      'answer': 'The end-semester examination schedule is published 3 weeks before exams on the Exam Branch portal. Internal/mid-term exam schedules are set by individual departments and shared via class coordinators.',
      'source': 'Examination Branch',
      'related': ['Revaluation process', 'Exam hall allocation', 'Supplementary exams'],
    },
    {
      'keywords': ['scholarship', 'eligibility', 'financial aid', 'merit'],
      'answer': 'Multiple scholarships are available: Merit-cum-Means (CGPA ≥ 8.5, income < ₹5L), State Government Scholarships (apply through e-scholarship portal), and Dept-specific merit awards. Check the Scholarship Cell in Admin Block, Room 203.',
      'source': 'Scholarship Cell',
      'related': ['Scholarship documents', 'Application deadlines'],
    },
    {
      'keywords': ['placement', 'drive', 'recruitment', 'job', 'campus placement'],
      'answer': 'Campus placements typically begin in August for final-year students. Register on the Placement Cell portal to receive drive notifications. Pre-Placement Talks (PPTs) are announced 1 week before each drive.',
      'source': 'Placement Cell',
      'related': ['Placement statistics', 'Resume format', 'Mock interviews'],
    },
    {
      'keywords': ['fee', 'payment', 'how to pay', 'pay online', 'fee payment'],
      'answer': 'Fees can be paid online through the Student Portal → Fee Payment section (supports UPI, Net Banking, and Card). For offline payment, visit the Accounts Office (Admin Block, Ground Floor) between 9:30 AM – 4:00 PM on working days.',
      'source': 'Accounts Department',
      'related': ['Fee structure', 'Installment options', 'Late fee policy'],
    },
    {
      'keywords': ['wifi', 'internet', 'network', 'connect', 'password'],
      'answer': 'Connect to the "CampusNet" WiFi network. Login using your student ID and portal password. If you face issues, reset your network password at the IT Helpdesk (Tech Block, Room 101) or call ext. 5555.',
      'source': 'IT Department',
      'related': ['VPN access', 'Email setup', 'Software licenses'],
    },
    {
      'keywords': ['certificate', 'apply', 'how to get', 'bonafide', 'transfer'],
      'answer': 'You can request certificates digitally through CampusFlow — just tell me which certificate you need! Available certificates: Bonafide, Transfer, Course Completion, No Dues, Migration, and Conduct Certificate.',
      'source': 'Administration',
      'related': ['Clearance process', 'Document verification'],
    },
    {
      'keywords': ['attendance', 'shortage', 'minimum', 'percentage'],
      'answer': 'Minimum attendance requirement is 75% per subject. Students below 65% will be debarred from end-semester exams. Attendance is tracked biometrically. Check your attendance on the Student Portal → Academics → Attendance.',
      'source': 'Academic Section',
      'related': ['Medical leave', 'Attendance condonation', 'OD policy'],
    },
    {
      'keywords': ['mess', 'menu', 'food', 'canteen', 'dining'],
      'answer': 'The mess menu rotates weekly. Breakfast: 7:30-9:00 AM, Lunch: 12:00-2:00 PM, Snacks: 4:30-5:30 PM, Dinner: 7:30-9:00 PM. Special diet requests can be made through the Hostel Warden office.',
      'source': 'Hostel Administration',
      'related': ['Mess rebate', 'Food quality complaints'],
    },
  ];

  // Notifications
  static final Map<String, List<CampusNotification>> notifications = {
    'STU-001001': [
      CampusNotification(
        id: 'NOT-001',
        type: 'due_reminder',
        title: 'Hostel Dues Reminder',
        message: 'Your hostel dues of ₹2,400 are due by April 1st. Avoid late fees by paying before the deadline.',
        timestamp: DateTime(2026, 3, 13, 10, 0),
        read: false,
      ),
      CampusNotification(
        id: 'NOT-002',
        type: 'clearance_update',
        title: 'Bonafide Certificate Update',
        message: 'Library and Accounts have approved your bonafide certificate request. Waiting for Hostel and Tutor.',
        timestamp: DateTime(2026, 3, 12, 14, 30),
        read: false,
      ),
      CampusNotification(
        id: 'NOT-003',
        type: 'opportunity',
        title: 'New Scholarship Available',
        message: 'Merit-cum-Means Scholarship 2026 applications are now open. Deadline: March 22nd.',
        timestamp: DateTime(2026, 3, 10, 9, 0),
        read: true,
      ),
      CampusNotification(
        id: 'NOT-004',
        type: 'alert',
        title: 'HackIndia 2026 — Deadline Soon!',
        message: 'Registration for HackIndia 2026 closes on March 18th. Don\'t miss out!',
        timestamp: DateTime(2026, 3, 11, 16, 0),
        read: false,
      ),
      CampusNotification(
        id: 'NOT-005',
        type: 'alert',
        title: 'Hackathon Alert',
        message: 'HackIndia 2026 registration closing soon!',
        timestamp: DateTime(2026, 3, 14, 11, 0),
        read: false,
      ),
    ],
    'STU-001002': [
      CampusNotification(
        id: 'NOT-005',
        type: 'due_reminder',
        title: 'Tuition Balance Alert',
        message: 'Your tuition balance of ₹12,000 is due by March 31st.',
        timestamp: DateTime(2026, 3, 13, 11, 0),
        read: false,
      ),
    ],
    'STU-001003': [
      CampusNotification(
        id: 'NOT-006',
        type: 'system',
        title: 'Welcome to CampusFlow!',
        message: 'Your account has been set up. Explore all the features available to you.',
        timestamp: DateTime(2026, 3, 12, 8, 0),
        read: false,
      ),
    ],
  };

  // ── Notification helper ─────────────────────────────────────
  /// Push a new notification to a user's notification list.
  static void pushNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) {
    final notif = CampusNotification(
      id: 'NOT-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    notifications.putIfAbsent(userId, () => []);
    notifications[userId]!.insert(0, notif);
  }

  /// Replace a student entry in the in-memory map.
  static void updateStudent(String id, Student updated) {
    students[id] = updated;
  }

  /// Find a user by role and staffDepartment.
  static Student? findUserByRoleAndDept(String role, String department) {
    return students.values.cast<Student?>().firstWhere(
      (s) => s!.role == role && s.staffDepartment == department,
      orElse: () => null,
    );
  }
}
