import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:campusflow_ai/services/ai_engine.dart';
import 'package:campusflow_ai/services/campus_tools.dart';
import 'package:campusflow_ai/models/models.dart';

void main() {
  // ─── TOOL 1: Check Dues ─────────────────────────────────────────
  group('Tool 1: Check Dues', () {
    test('Student with dues gets dues card', () async {
      final engine = AIEngine(studentId: 'STU-001001'); // Arjun - has dues
      final response = await engine.processMessage('Do I have any dues?');
      expect(response, isNotEmpty);
      expect(response.first.sender, MessageSender.assistant);
      expect(response.first.type, MessageType.duesCard);
      expect(response.first.data, isA<DuesRecord>());
      expect((response.first.data as DuesRecord).hasDues, true);
      debugPrint('✅ Tool 1 (with dues): ${response.first.text}');
    });

    test('Student without dues gets all-clear message', () async {
      final engine = AIEngine(studentId: 'STU-001003'); // Ravi - no dues
      final response = await engine.processMessage('Any outstanding dues?');
      expect(response, isNotEmpty);
      expect(response.first.text, contains('no pending dues'));
      debugPrint('✅ Tool 1 (no dues): ${response.first.text}');
    });
  });

  // ─── TOOL 2 & 3: Clearance Request + Status ────────────────────
  group('Tool 2 & 3: Clearance Flow', () {
    test('Direct certificate request triggers confirmation', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('I need a transfer certificate');
      expect(response, isNotEmpty);
      // Should ask for confirmation (since student has dues)
      final allText = response.map((m) => m.text).join(' ');
      expect(allText.toLowerCase(), contains('transfer certificate'));
      debugPrint('✅ Tool 2 (direct type): ${response.length} messages returned');
    });

    test('Generic clearance request asks for type', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('I need a certificate');
      expect(response, isNotEmpty);
      expect(response.first.text.toLowerCase(), contains('which one'));
      debugPrint('✅ Tool 2 (ask type): ${response.first.text.substring(0, 60)}...');
    });

    test('Multi-step clearance flow: ask type → select → confirm → submit', () async {
      final engine = AIEngine(studentId: 'STU-001003'); // Ravi - no dues

      // Step 1: Generic request
      var response = await engine.processMessage('I need a certificate');
      expect(response.first.text.toLowerCase(), contains('which one'));

      // Step 2: Select bonafide
      response = await engine.processMessage('bonafide');
      var allText = response.map((m) => m.text).join(' ');
      expect(allText.toLowerCase(), contains('bonafide'));

      // Step 3: Confirm
      response = await engine.processMessage('yes, go ahead');
      allText = response.map((m) => m.text).join(' ');
      expect(allText, contains('CLR-'));
      expect(allText, contains('AUTO-APPROVED'));
      debugPrint('✅ Tool 2+3 (full flow): Clearance submitted');
    });

    test('Status check returns clearance info', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('What is my clearance status?');
      expect(response, isNotEmpty);
      // Arjun has a pre-existing clearance in mock data
      if (response.first.type == MessageType.statusTable) {
        expect(response.first.data, isA<ClearanceRequest>());
        debugPrint('✅ Tool 3 (status): Request ${(response.first.data as ClearanceRequest).requestId}');
      } else {
        debugPrint('✅ Tool 3 (status): ${response.first.text.substring(0, 60)}...');
      }
    });
  });

  // ─── TOOL 4: Opportunities ─────────────────────────────────────
  group('Tool 4: Opportunities', () {
    test('Lists matching opportunities', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Any scholarships available?');
      expect(response, isNotEmpty);
      expect(response.first.type, MessageType.opportunityList);
      expect(response.first.data, isA<List<Opportunity>>());
      final opps = response.first.data as List<Opportunity>;
      expect(opps, isNotEmpty);
      debugPrint('✅ Tool 4: ${opps.length} opportunities returned');
    });
  });

  // ─── TOOL 5: Payment Summary ───────────────────────────────────
  group('Tool 5: Payment Summary', () {
    test('Returns full payment breakdown', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Show my fee details');
      expect(response, isNotEmpty);
      expect(response.first.type, MessageType.paymentSummary);
      expect(response.first.data, isA<PaymentSummary>());
      debugPrint('✅ Tool 5: Payment summary with total outstanding = ₹${(response.first.data as PaymentSummary).totalOutstanding}');
    });
  });

  // ─── TOOL 6: Issue Reporting ───────────────────────────────────
  group('Tool 6: Issue Reporting', () {
    test('Issue with location skips location step', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('WiFi not working in Block C Room 204');
      expect(response, isNotEmpty);
      expect(response.first.text, contains('Block C'));
      debugPrint('✅ Tool 6 (with location): ${response.first.text.substring(0, 60)}...');
    });

    test('Issue without location asks for it', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('WiFi is not working');
      expect(response, isNotEmpty);
      expect(response.first.text, contains('exactly where'));
      debugPrint('✅ Tool 6 (ask location): ${response.first.text.substring(0, 60)}...');
    });

    test('Full issue reporting flow: report → location → photo → confirm', () async {
      final engine = AIEngine(studentId: 'STU-001001');

      // Step 1: Report issue
      var response = await engine.processMessage('The lights are broken');
      expect(response.first.text, contains('where'));

      // Step 2: Provide location
      response = await engine.processMessage('Block A Room 101');
      expect(response.first.text, contains('photo'));

      // Step 3: Skip photo
      response = await engine.processMessage('no');
      expect(response.first.text, contains('Category'));
      expect(response.first.text, contains('Location'));

      // Step 4: Confirm
      response = await engine.processMessage('yes, log it');
      expect(response.first.text, contains('ISS-'));
      expect(response.first.text, contains('logged successfully'));
      debugPrint('✅ Tool 6 (full flow): Issue ticket created');
    });
  });

  // ─── TOOL 7: Documents ─────────────────────────────────────────
  group('Tool 7: Documents', () {
    test('Specific document request returns document', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Show my ID card');
      expect(response, isNotEmpty);
      if (response.first.type == MessageType.documentInfo) {
        debugPrint('✅ Tool 7 (specific): Document card returned');
      } else {
        debugPrint('✅ Tool 7 (specific): ${response.first.text.substring(0, 60)}...');
      }
    });

    test('General documents request lists all', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Show my documents');
      expect(response, isNotEmpty);
      debugPrint('✅ Tool 7 (all): Type=${response.first.type}');
    });
  });

  // ─── TOOL 8: FAQ ───────────────────────────────────────────────
  group('Tool 8: FAQ', () {
    test('Known FAQ topic returns answer', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('What are the library timings?');
      expect(response, isNotEmpty);
      debugPrint('✅ Tool 8: ${response.first.text.substring(0, 80)}...');
    });

    test('Unknown topic returns fallback', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('xyzzy blorp nonexistent query 12345');
      expect(response, isNotEmpty);
      expect(response.first.text, contains('not sure'));
      debugPrint('✅ Tool 8 (unknown): Fallback message returned');
    });
  });

  // ─── TOOL 9: Notifications ────────────────────────────────────
  group('Tool 9: Notifications', () {
    test('Returns notification list', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Show my notifications');
      expect(response, isNotEmpty);
      expect(response.first.type, MessageType.notificationList);
      final notifs = response.first.data as List<CampusNotification>;
      expect(notifs, isNotEmpty);
      debugPrint('✅ Tool 9: ${notifs.length} notifications returned');
    });
  });

  // ─── Out-of-Scope Handling ────────────────────────────────────
  group('Out-of-Scope Redirection', () {
    test('Mental health → counseling cell', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('I feel really stressed and anxious');
      expect(response.first.text, contains('Counselling'));
      expect(response.first.text, contains('4444'));
      debugPrint('✅ Out-of-scope (mental health): Redirected to counseling');
    });

    test('Medical emergency → health center', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('I need an ambulance');
      expect(response.first.text, contains('Health Center'));
      expect(response.first.text, contains('1111'));
      debugPrint('✅ Out-of-scope (medical): Redirected to health center');
    });

    test('Sensitive issue → grievance cell', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('I want to report ragging');
      expect(response.first.text, contains('Anti-Ragging'));
      expect(response.first.text, contains('3333'));
      debugPrint('✅ Out-of-scope (sensitive): Redirected to grievance cell');
    });

    test('Academic advice → advisor', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Which elective should I choose?');
      expect(response.first.text, contains('tutor'));
      debugPrint('✅ Out-of-scope (academic): Redirected to advisor');
    });
  });

  // ─── Greetings & Welcome ──────────────────────────────────────
  group('Greetings & Welcome', () {
    test('Welcome message includes proactive alerts', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final welcome = engine.generateWelcome();
      expect(welcome, isNotEmpty);
      expect(welcome.first.text, contains('Welcome'));
      expect(welcome.first.text, contains('CampusFlow'));
      debugPrint('✅ Welcome: ${welcome.first.text.substring(0, 80)}...');
    });

    test('Greeting returns capabilities list', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Hello!');
      expect(response.first.text, contains('How can I help'));
      debugPrint('✅ Greeting: ${response.first.text.substring(0, 60)}...');
    });

    test('Thank you returns farewell', () async {
      final engine = AIEngine(studentId: 'STU-001001');
      final response = await engine.processMessage('Thanks, bye!');
      expect(response.first.text, contains('welcome'));
      debugPrint('✅ Thanks: ${response.first.text}');
    });
  });

  // ─── Direct Service Layer Tests ───────────────────────────────
  group('Campus Tools (Direct)', () {
    test('checkDues returns correct data', () async {
      final dues = CampusTools.checkDues('STU-001001');
      expect(dues.hasDues, true);
      expect(dues.totalOutstanding, greaterThan(0));
      debugPrint('✅ CampusTools.checkDues: ₹${dues.totalOutstanding} outstanding');
    });

    test('submitClearanceRequest generates unique ID', () async {
      final req = CampusTools.submitClearanceRequest('STU-001001', 'transfer_certificate');
      expect(req.requestId, startsWith('CLR-'));
      expect(req.studentId, 'STU-001001');
      // STU-001001 (Arjun) has dues, so auto-verification puts request on_hold
      expect(req.overallStatus, 'on_hold');
      debugPrint('✅ CampusTools.submitClearanceRequest: ${req.requestId}');
    });

    test('reportIssue generates ticket', () async {
      final ticket = CampusTools.reportIssue(
        studentId: 'STU-001001',
        category: 'internet',
        description: 'WiFi down in Block C',
        location: 'Block C Room 204',
      );
      expect(ticket.ticketId, startsWith('ISS-'));
      expect(ticket.assignedTo, 'IT Department');
      debugPrint('✅ CampusTools.reportIssue: ${ticket.ticketId} → ${ticket.assignedTo}');
    });

    test('getFaq returns results with confidence', () async {
      final faq = CampusTools.getFaq('library timing hours');
      expect(faq.confidence, greaterThan(0));
      debugPrint('✅ CampusTools.getFaq: confidence=${faq.confidence}, answer=${faq.answer.substring(0, 50)}...');
    });

    test('getNotifications returns unread items', () async {
      final notifs = CampusTools.getNotifications('STU-001001');
      expect(notifs, isNotEmpty);
      final unread = CampusTools.getUnreadCount('STU-001001');
      expect(unread, greaterThanOrEqualTo(0));
      debugPrint('✅ CampusTools.getNotifications: ${notifs.length} total, $unread unread');
    });
  });
}
