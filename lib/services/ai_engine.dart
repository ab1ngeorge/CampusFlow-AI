import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'campus_tools.dart';
import 'mock_data.dart';

// Workflow states for multi-step flows
enum WorkflowState {
  none,
  clearanceAskType,
  clearanceConfirmSubmit,
  issueAskLocation,
  issueAskPhoto,
  issueConfirmSubmit,
}

class WorkflowContext {
  WorkflowState state;
  String? clearanceType;
  String? issueCategory;
  String? issueDescription;
  String? issueLocation;

  WorkflowContext({this.state = WorkflowState.none});

  void reset() {
    state = WorkflowState.none;
    clearanceType = null;
    issueCategory = null;
    issueDescription = null;
    issueLocation = null;
  }
}

class AIEngine {
  final String studentId;
  final WorkflowContext _workflow = WorkflowContext();
  final List<Map<String, String>> _chatHistory = [];
  static const int _maxHistory = 20;
  static const String _groqApiKey = 'GROQ_API_KEY';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  AIEngine({required this.studentId});

  Student? get _student => MockData.students[studentId];

  String get _firstName => _student?.firstName ?? 'there';

  void _addToHistory(String role, String content) {
    _chatHistory.add({'role': role, 'content': content});
    if (_chatHistory.length > _maxHistory) {
      _chatHistory.removeAt(0);
    }
  }

  // Main entry point: process user message and return response messages
  Future<List<ChatMessage>> processMessage(String userMessage) async {
    final msg = userMessage.trim().toLowerCase();

    // Add user message to conversation history
    _addToHistory('user', userMessage);

    // Check if we're in a workflow first (state machines bypass LLM for exact steps)
    if (_workflow.state != WorkflowState.none) {
      final result = await _handleWorkflowResponse(msg, userMessage);
      for (final m in result) {
        _addToHistory('assistant', m.text);
      }
      return result;
    }

    try {
      // Build messages array with conversation history for context
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '''You are the CampusFlow AI Intent Classifier. Analyze the user's message and determine the exact intent.
You MUST output ONLY valid JSON in the following format.

{
  "intent": "STR", // Choose strictly from the EXACT ENUM list below
  "extracted_info": "STR" // Optional: Extract context like certificate type (e.g. "transfer"), issue location (e.g. "Block C"), or FAQ topic. Leave empty if none.
}

EXACT ENUM LIST FOR "intent":
1. "check_dues": queries about owing money, fines, balances, dues.
2. "clearance_request": asking for certificates (bonafide, transfer, conduct, etc.) or clearance.
3. "status_check": checking the status of a request, approval tracking.
4. "opportunities": scholarships, internships, placements, hackathons.
5. "payment_summary": fee details, tuition receipts, payment history.
6. "report_issue": complaints, broken things, wifi down, plumbing, maintenance limits.
7. "documents": asking to view/download ID cards, marksheets, specific vault documents.
8. "notifications": asking for alerts, updates, new messages.
9. "mental_health": expressing stress, depression, anxiety, feeling overwhelmed.
10. "medical_emergency": accidents, injuries, ambulance, hospital.
11. "sensitive_issue": ragging, harassment, bullying, formal disciplinary complaints.
12. "academic_advice": asking which elective to take, career path questions.
13. "greeting": hello, hi, hey, good morning.
14. "thanks": thank you, bye, see ya.
15. "faq": general inquiries about campus rules, timings, facilities (e.g., library hours).

IMPORTANT: Use conversation history to understand follow-up questions. For example, if user asks "tell me more about the first one" after seeing opportunities, classify as "opportunities".'''
        },
      ];

      // Add last 10 conversation history entries for context
      final historySlice = _chatHistory.length > 10
          ? _chatHistory.sublist(_chatHistory.length - 10)
          : _chatHistory;
      messages.addAll(historySlice);

      // Call Groq to classify intent and extract entities
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = jsonDecode(content);
        
        final intent = result['intent'] as String?;
        final extractedInfo = result['extracted_info'] as String?;

        // Route based on LLM JSON output and track in history
        List<ChatMessage> responses;
        switch (intent) {
          case 'check_dues': responses = _handleDuesCheck(); break;
          case 'clearance_request': responses = _handleClearanceIntent(extractedInfo ?? msg); break;
          case 'status_check': responses = _handleStatusCheck(extractedInfo ?? msg); break;
          case 'opportunities': responses = _handleOpportunities(); break;
          case 'payment_summary': responses = _handlePaymentSummary(); break;
          case 'report_issue': responses = _handleIssueReport(extractedInfo ?? msg, userMessage); break;
          case 'documents': responses = _handleDocumentRequest(extractedInfo ?? msg); break;
          case 'notifications': responses = _handleNotifications(); break;
          case 'mental_health': responses = _handleMentalHealth(); break;
          case 'medical_emergency': responses = _handleMedicalEmergency(); break;
          case 'sensitive_issue': responses = _handleSensitiveIssue(); break;
          case 'academic_advice': responses = _handleAcademicAdvice(); break;
          case 'greeting': responses = _handleGreeting(); break;
          case 'thanks': responses = _handleThanks(); break;
          case 'faq': responses = _handleFAQ(extractedInfo ?? userMessage); break;
          default: responses = _handleFAQ(userMessage);
        }
        for (final m in responses) {
          _addToHistory('assistant', m.text);
        }
        return responses;
      } else {
        debugPrint('Groq API Error: ${response.statusCode} - ${response.body}');
        return [_handleApiError()];
      }
    } catch (e) {
      debugPrint('Groq Integration Error: $e');
      return [_handleApiError()];
    }
  }

  ChatMessage _handleApiError() {
    return ChatMessage(
      sender: MessageSender.assistant,
      text: 'I\'m sorry, I\'m having trouble connecting to my brain right now. Please try again in a moment!',
    );
  }

  // Generate welcome message on session start
  List<ChatMessage> generateWelcome() {
    final messages = <ChatMessage>[];
    final unreadCount = CampusTools.getUnreadCount(studentId);

    String welcome = 'Hey $_firstName! 👋 Welcome to CampusFlow. I\'m your campus assistant — I can help you check dues, request certificates, report issues, find opportunities, and much more.\n\n';

    if (unreadCount > 0) {
      welcome += '📬 You have **$unreadCount unread notification${unreadCount > 1 ? 's' : ''}**. ';

      // Surface urgent items
      final notifs = CampusTools.getNotifications(studentId);
      final urgent = notifs.where((n) => !n.read).toList();
      if (urgent.isNotEmpty) {
        welcome += 'Here\'s what\'s new:\n\n';
        for (var n in urgent.take(3)) {
          welcome += '${n.typeIcon} **${n.title}** — ${n.message}\n\n';
        }
      }
    }

    welcome += 'What can I help you with today?';

    messages.add(ChatMessage(
      sender: MessageSender.assistant,
      text: welcome,
    ));

    return messages;
  }

  // ── Intent handlers ──────────────────────────────────────────────

  List<ChatMessage> _handleDuesCheck() {
    final dues = CampusTools.checkDues(studentId);

    if (!dues.hasDues) {
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'Great news, $_firstName! 🎉 You have **no pending dues** across any department. You\'re fully cleared!\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Here\'s your current dues summary, $_firstName:',
        type: MessageType.duesCard,
        data: dues,
      ),
    ];
  }

  List<ChatMessage> _handleClearanceIntent(String msg) {
    String? detectedType;

    if (msg.contains('transfer')) {
      detectedType = 'transfer_certificate';
    } else if (msg.contains('bonafide')) {
      detectedType = 'bonafide_certificate';
    } else if (msg.contains('course completion')) {
      detectedType = 'course_completion_certificate';
    } else if (msg.contains('no dues')) {
      detectedType = 'no_dues_certificate';
    } else if (msg.contains('migration')) {
      detectedType = 'migration_certificate';
    } else if (msg.contains('conduct')) {
      detectedType = 'conduct_certificate';
    }

    if (detectedType != null) {
      // Check dues first
      final dues = CampusTools.checkDues(studentId);
      _workflow.clearanceType = detectedType;

      final typeName = _clearanceTypeDisplay(detectedType);

      if (dues.hasDues) {
        _workflow.state = WorkflowState.clearanceConfirmSubmit;
        return [
          ChatMessage(
            sender: MessageSender.assistant,
            text: 'Before I submit your **$typeName** request, I noticed there are some outstanding dues:',
            type: MessageType.duesCard,
            data: dues,
          ),
          ChatMessage(
            sender: MessageSender.assistant,
            text: 'These may need to be cleared before all departments approve your request. Would you still like me to **go ahead and submit it**, or would you prefer to **clear the dues first**?\n\nIs there anything else I can help you with today?',
          ),
        ];
      } else {
        _workflow.state = WorkflowState.clearanceConfirmSubmit;
        return [
          ChatMessage(
            sender: MessageSender.assistant,
            text: '✅ You have no pending dues — great!\n\nShall I go ahead and submit your **$typeName** request?',
          ),
        ];
      }
    }

    // Didn't detect which certificate — ask
    _workflow.state = WorkflowState.clearanceAskType;
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Sure, I can help you with a certificate request! Which one do you need?\n\n'
            '📜 **Transfer Certificate**\n'
            '📜 **Course Completion Certificate**\n'
            '📜 **Bonafide Certificate**\n'
            '📜 **No Dues Certificate**\n'
            '📜 **Migration Certificate**\n'
            '📜 **Conduct Certificate**\n\n'
            'Just let me know!',
      ),
    ];
  }

  List<ChatMessage> _handleStatusCheck(String msg) {
    // Try to extract request ID
    final reqIdMatch = RegExp(r'clr-\w+', caseSensitive: false).firstMatch(msg);
    String? requestId = reqIdMatch?.group(0)?.toUpperCase();

    final request = CampusTools.getClearanceStatus(studentId, requestId);
    if (request == null) {
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'I couldn\'t find any clearance requests on your account${requestId != null ? ' with ID $requestId' : ''}. Would you like to submit a new request?\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Here\'s the status of your **${request.clearanceTypeDisplay}** request (**${request.requestId}**):',
        type: MessageType.statusTable,
        data: request,
      ),
    ];
  }

  List<ChatMessage> _handleOpportunities() {
    final opportunities = CampusTools.listOpportunities(studentId);
    if (opportunities.isEmpty) {
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'I don\'t see any matching opportunities for your profile right now, $_firstName. I\'ll keep an eye out and notify you when something comes up!\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Here are the top opportunities matching your profile, $_firstName! 🌟',
        type: MessageType.opportunityList,
        data: opportunities.take(5).toList(),
      ),
    ];
  }

  List<ChatMessage> _handlePaymentSummary() {
    final summary = CampusTools.getPaymentSummary(studentId);
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Here\'s your complete payment summary, $_firstName:',
        type: MessageType.paymentSummary,
        data: summary,
      ),
    ];
  }

  List<ChatMessage> _handleIssueReport(String msg, String originalMessage) {
    // Detect category
    String? category;
    if (_matchesIntent(msg, ['wifi', 'internet', 'network', 'lan'])) {
      category = 'internet';
    } else if (_matchesIntent(msg, ['broken', 'furniture', 'light', 'fan', 'door', 'window', 'bench'])) {
      category = 'infrastructure';
    } else if (_matchesIntent(msg, ['dirty', 'clean', 'washroom', 'hygiene', 'garbage', 'trash'])) {
      category = 'cleanliness';
    } else if (_matchesIntent(msg, ['hostel', 'room', 'water issue', 'electricity issue'])) {
      category = 'hostel';
    } else if (_matchesIntent(msg, ['food', 'canteen', 'mess quality'])) {
      category = 'canteen';
    } else if (_matchesIntent(msg, ['unsafe', 'suspicious', 'security'])) {
      category = 'safety';
    } else if (_matchesIntent(msg, ['lab', 'equipment', 'classroom', 'projector'])) {
      category = 'academics';
    } else {
      category = 'other';
    }

    _workflow.issueCategory = category;
    _workflow.issueDescription = originalMessage;

    // Check if location was mentioned
    final locationMatch = RegExp(r'(?:block|room|floor|gate|building|hostel|lab|wing)\s*[a-z0-9\-]+', caseSensitive: false).firstMatch(originalMessage);
    if (locationMatch != null) {
      _workflow.issueLocation = locationMatch.group(0);
      _workflow.state = WorkflowState.issueAskPhoto;
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'That\'s frustrating — I\'ll log this right away. I\'ve noted the location as **${_workflow.issueLocation}**.\n\nDo you have a photo of the issue? (optional, but helpful — just type "no" to skip)',
        ),
      ];
    }

    _workflow.state = WorkflowState.issueAskLocation;
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'That\'s frustrating — I\'ll get this reported for you. Could you tell me **exactly where this is**? For example: Block C Room 204, or Near the main gate.',
      ),
    ];
  }

  List<ChatMessage> _handleDocumentRequest(String msg) {
    String? docType;
    if (msg.contains('id card') || msg.contains('id_card')) {
      docType = 'id_card';
    } else if (msg.contains('bonafide')) {
      docType = 'bonafide_certificate';
    } else if (msg.contains('fee receipt') || msg.contains('receipt')) {
      docType = 'fee_receipt';
    } else if (msg.contains('mark sheet') || msg.contains('marksheet')) {
      docType = 'mark_sheet';
    } else if (msg.contains('enrollment')) {
      docType = 'enrollment_certificate';
    } else if (msg.contains('transfer')) {
      docType = 'transfer_certificate';
    } else if (msg.contains('scholarship letter')) {
      docType = 'scholarship_letter';
    }

    if (docType == null) {
      // Show all documents
      final docs = CampusTools.getAllDocuments(studentId);
      if (docs.isEmpty) {
        return [
          ChatMessage(
            sender: MessageSender.assistant,
            text: 'I don\'t have any documents in your vault yet, $_firstName. You can request documents from the relevant department and they\'ll be added to your account.\n\nIs there anything else I can help you with today?',
          ),
        ];
      }

      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'Here are the documents available in your vault, $_firstName:',
          type: MessageType.documentInfo,
          data: docs,
        ),
      ];
    }

    final doc = CampusTools.getDocument(studentId, docType);
    if (doc == null) {
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'I couldn\'t find that document in your vault, $_firstName. It\'s possible it hasn\'t been uploaded yet. You can request it from the relevant office and they\'ll add it to your account.\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Found it! Here\'s your **${doc.typeDisplay}**:',
        type: MessageType.documentInfo,
        data: [doc],
      ),
    ];
  }

  List<ChatMessage> _handleNotifications() {
    final notifs = CampusTools.getNotifications(studentId);
    if (notifs.isEmpty) {
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'You\'re all caught up, $_firstName! No notifications right now. 🎉\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Here are your notifications, $_firstName:',
        type: MessageType.notificationList,
        data: notifs,
      ),
    ];
  }

  // Out-of-scope handlers
  List<ChatMessage> _handleMentalHealth() {
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'I hear you — that\'s really tough, and it\'s okay to feel that way, $_firstName. 💙\n\nThe **Student Counselling Cell** is a great resource for exactly this kind of moment, and everything you share there is completely confidential. You can reach them at:\n\n📞 **Ext. 4444** or visit **Admin Block, Room 105**\n🕐 Available Mon–Sat, 9:00 AM – 5:00 PM\n\nIs there anything else on the admin or campus side I can help sort out for you today?',
      ),
    ];
  }

  List<ChatMessage> _handleMedicalEmergency() {
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: '🚨 Please contact the **Campus Health Center** immediately:\n\n📞 **Emergency: Ext. 1111** or **+91 98765 43210**\n📍 Located at Medical Block, Ground Floor\n🕐 Open 24/7 for emergencies\n\nThis is beyond what I can help with here — but please don\'t hesitate to reach out to them right away.\n\nIs there anything else I can help you with today?',
      ),
    ];
  }

  List<ChatMessage> _handleSensitiveIssue() {
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'This needs to go to the right authority to be handled properly, $_firstName. I\'ll help you find the correct contact:\n\n📋 **Anti-Ragging Cell**: Ext. 3333, Admin Block Room 110\n📋 **Grievance Redressal Cell**: Ext. 3334, Admin Block Room 112\n📧 **Email**: grievance@campus.edu\n\nAll complaints are handled confidentially.\n\nIs there anything else I can help you with today?',
      ),
    ];
  }

  List<ChatMessage> _handleAcademicAdvice() {
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'That\'s a great question, $_firstName — but I\'d recommend talking to your **tutor or academic advisor** for this. They know your academic profile and can give you much better guidance than I can! 📚\n\nYou can reach your department office to schedule a meeting.\n\nIs there anything else I can help you with today?',
      ),
    ];
  }

  List<ChatMessage> _handleGreeting() {
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Hey $_firstName! 👋 How can I help you today? Here are some things I can do:\n\n'
            '💰 **Check your dues**\n'
            '📜 **Request a certificate**\n'
            '📊 **Track a clearance request**\n'
            '🌟 **Find opportunities** (scholarships, internships, placements)\n'
            '💳 **View payment summary**\n'
            '🔧 **Report a campus issue**\n'
            '📁 **Get your documents**\n'
            '❓ **Answer campus questions**\n\n'
            'Just ask away!',
      ),
    ];
  }

  List<ChatMessage> _handleThanks() {
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'You\'re welcome, $_firstName! 😊 Feel free to come back anytime you need help. Have a great day! 🌟',
      ),
    ];
  }

  List<ChatMessage> _handleFAQ(String query) {
    final result = CampusTools.getFaq(query);

    if (result.confidence >= 0.75) {
      String response = '${result.answer}\n\n📌 *Source: ${result.source}*';
      if (result.relatedTopics.isNotEmpty) {
        response += '\n\n**Related topics:** ${result.relatedTopics.join(', ')}';
      }
      response += '\n\nIs there anything else I can help you with today?';
      return [
        ChatMessage(sender: MessageSender.assistant, text: response),
      ];
    } else if (result.confidence > 0) {
      String response = 'Based on available information: ${result.answer}\n\n'
          'I\'d suggest verifying with the relevant office for the latest details.';
      if (result.relatedTopics.isNotEmpty) {
        response += '\n\n**Related topics:** ${result.relatedTopics.join(', ')}';
      }
      response += '\n\nIs there anything else I can help you with today?';
      return [
        ChatMessage(sender: MessageSender.assistant, text: response),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'I\'m not sure about that one, $_firstName. Could you try rephrasing your question? Or I can help with:\n\n'
            '💰 Dues & Payments\n'
            '📜 Certificate requests\n'
            '🌟 Opportunities\n'
            '🔧 Issue reporting\n'
            '📁 Documents\n'
            '❓ Campus FAQs\n\nIs there anything else I can help you with today?',
      ),
    ];
  }

  // ── Workflow handlers ────────────────────────────────────────────

  Future<List<ChatMessage>> _handleWorkflowResponse(String msg, String originalMessage) async {
    switch (_workflow.state) {
      case WorkflowState.clearanceAskType:
        return _handleClearanceTypeResponse(msg);
      case WorkflowState.clearanceConfirmSubmit:
        return _handleClearanceConfirmResponse(msg);
      case WorkflowState.issueAskLocation:
        return _handleIssueLocationResponse(originalMessage);
      case WorkflowState.issueAskPhoto:
        return _handleIssuePhotoResponse(msg);
      case WorkflowState.issueConfirmSubmit:
        return _handleIssueConfirmResponse(msg);
      default:
        _workflow.reset();
        return await processMessage(originalMessage);
    }
  }

  List<ChatMessage> _handleClearanceTypeResponse(String msg) {
    String? type;
    if (msg.contains('transfer')) {
      type = 'transfer_certificate';
    } else if (msg.contains('bonafide')) {
      type = 'bonafide_certificate';
    } else if (msg.contains('course completion') || msg.contains('completion')) {
      type = 'course_completion_certificate';
    } else if (msg.contains('no dues')) {
      type = 'no_dues_certificate';
    } else if (msg.contains('migration')) {
      type = 'migration_certificate';
    } else if (msg.contains('conduct')) {
      type = 'conduct_certificate';
    }

    if (type == null) {
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'I didn\'t catch that. Please choose from:\n\n'
              '1. Transfer Certificate\n'
              '2. Course Completion Certificate\n'
              '3. Bonafide Certificate\n'
              '4. No Dues Certificate\n'
              '5. Migration Certificate\n'
              '6. Conduct Certificate',
        ),
      ];
    }

    _workflow.reset();
    _workflow.clearanceType = type;
    final dues = CampusTools.checkDues(studentId);
    final typeName = _clearanceTypeDisplay(type);

    if (dues.hasDues) {
      _workflow.state = WorkflowState.clearanceConfirmSubmit;
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'Before I submit your **$typeName** request, here are your current dues:',
          type: MessageType.duesCard,
          data: dues,
        ),
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'Would you still like me to go ahead and submit, or clear dues first?',
        ),
      ];
    }

    _workflow.state = WorkflowState.clearanceConfirmSubmit;
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: '✅ No pending dues. Shall I submit your **$typeName** request?',
      ),
    ];
  }

  List<ChatMessage> _handleClearanceConfirmResponse(String msg) {
    if (_matchesIntent(msg, ['yes', 'sure', 'go ahead', 'submit', 'proceed', 'okay', 'ok', 'yep', 'yeah', 'do it'])) {
      final type = _workflow.clearanceType!;
      final request = CampusTools.submitClearanceRequest(studentId, type);
      _workflow.reset();

      final dateFormat = DateFormat('dd MMM yyyy');
      final approvedCount = request.departmentStatuses.values.where((s) => s == 'approved').length;
      final totalDepts = request.departmentStatuses.length;
      final allApproved = request.overallStatus == 'approved';

      // Build step-by-step verification summary
      String verificationSteps = '🔍 **Automated Verification Complete**\n\n';
      request.departmentStatuses.forEach((dept, status) {
        final deptName = dept[0].toUpperCase() + dept.substring(1);
        if (status == 'approved') {
          verificationSteps += '✅ **$deptName** — Verified & Auto-Approved\n';
        } else if (status == 'on_hold') {
          verificationSteps += '⏸️ **$deptName** — On Hold (dues pending)\n';
        } else {
          verificationSteps += '⏳ **$deptName** — Pending Review\n';
        }
      });

      if (allApproved) {
        // 🎉 Fully auto-approved — the dream scenario
        return [
          ChatMessage(
            sender: MessageSender.assistant,
            text: '$verificationSteps\n'
                '🎉 **ALL $totalDepts/$totalDepts departments cleared!**\n\n'
                '📋 **Request ID:** ${request.requestId}\n'
                '📊 **Status:** ✅ AUTO-APPROVED\n'
                '📅 **Completed:** ${dateFormat.format(DateTime.now())}\n\n'
                '**No physical signatures required.** Your **${request.clearanceTypeDisplay}** has been processed instantly — what used to take days now took seconds! 🚀\n\n'
                'You can download your certificate from the Documents section.',
          ),
          ChatMessage(
            sender: MessageSender.assistant,
            text: '',
            type: MessageType.statusTable,
            data: request,
          ),
        ];
      } else {
        // Some departments on hold — notify student
        return [
          ChatMessage(
            sender: MessageSender.assistant,
            text: '$verificationSteps\n'
                '📋 **Request ID:** ${request.requestId}\n'
                '📊 **Status:** ⏸️ On Hold ($approvedCount/$totalDepts departments cleared)\n'
                '📅 **Estimated completion:** ${dateFormat.format(request.estimatedCompletion!)}\n\n'
                '⚠️ **${request.remarks}**\n\n'
                'Once you clear the outstanding dues, the remaining departments will be auto-approved instantly. Track your request anytime by asking "What\'s my clearance status?"',
          ),
          ChatMessage(
            sender: MessageSender.assistant,
            text: '',
            type: MessageType.statusTable,
            data: request,
          ),
        ];
      }
    }

    if (_matchesIntent(msg, ['no', 'cancel', 'not now', 'later', 'clear dues first', 'nah', 'nope'])) {
      _workflow.reset();
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'No problem, $_firstName! You can always come back when you\'re ready. Would you like me to show you the payment options for your dues?\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Just to confirm — shall I go ahead and submit the request? (Yes/No)',
      ),
    ];
  }

  List<ChatMessage> _handleIssueLocationResponse(String originalMessage) {
    _workflow.issueLocation = originalMessage;
    _workflow.state = WorkflowState.issueAskPhoto;
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Got it — **$originalMessage**. Do you have a photo of the issue? (optional — type "no" to skip)',
      ),
    ];
  }

  List<ChatMessage> _handleIssuePhotoResponse(String msg) {
    _workflow.state = WorkflowState.issueConfirmSubmit;
    final categoryDisplay = _workflow.issueCategory?.replaceAll('_', ' ') ?? 'general';
    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Alright! Here\'s what I\'ll submit:\n\n'
            '🏷️ **Category:** ${categoryDisplay[0].toUpperCase()}${categoryDisplay.substring(1)}\n'
            '📍 **Location:** ${_workflow.issueLocation}\n'
            '📝 **Description:** ${_workflow.issueDescription}\n\n'
            'Shall I go ahead and log this complaint?',
      ),
    ];
  }

  List<ChatMessage> _handleIssueConfirmResponse(String msg) {
    if (_matchesIntent(msg, ['yes', 'sure', 'go ahead', 'submit', 'proceed', 'okay', 'ok', 'yep', 'yeah', 'do it', 'log it'])) {
      final ticket = CampusTools.reportIssue(
        studentId: studentId,
        category: _workflow.issueCategory!,
        description: _workflow.issueDescription!,
        location: _workflow.issueLocation!,
      );
      _workflow.reset();

      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: '✅ Your complaint has been logged successfully!\n\n'
              '🎫 **Ticket ID:** ${ticket.ticketId}\n'
              '📍 **Assigned to:** ${ticket.assignedTo}\n'
              '⏰ **Expected resolution:** ${ticket.expectedResolution}\n\n'
              'You can track this issue anytime by mentioning your Ticket ID.\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    if (_matchesIntent(msg, ['no', 'cancel', 'not now', 'nah', 'nope'])) {
      _workflow.reset();
      return [
        ChatMessage(
          sender: MessageSender.assistant,
          text: 'No problem! The report has been cancelled. Let me know if you need anything else.\n\nIs there anything else I can help you with today?',
        ),
      ];
    }

    return [
      ChatMessage(
        sender: MessageSender.assistant,
        text: 'Shall I go ahead and log this complaint? (Yes/No)',
      ),
    ];
  }

  // ── Helpers ──────────────────────────────────────────────────────

  bool _matchesIntent(String msg, List<String> keywords) {
    return keywords.any((k) => msg.contains(k));
  }

  String _clearanceTypeDisplay(String type) {
    switch (type) {
      case 'transfer_certificate': return 'Transfer Certificate';
      case 'course_completion_certificate': return 'Course Completion Certificate';
      case 'bonafide_certificate': return 'Bonafide Certificate';
      case 'no_dues_certificate': return 'No Dues Certificate';
      case 'migration_certificate': return 'Migration Certificate';
      case 'conduct_certificate': return 'Conduct Certificate';
      default: return type;
    }
  }
}
