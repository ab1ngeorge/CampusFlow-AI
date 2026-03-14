import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'dues_card.dart';
import 'status_table.dart';
import 'opportunity_card.dart';
import 'payment_summary_card.dart';
import 'document_card.dart';
import 'notification_card.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String highlightQuery;

  const MessageBubble({
    super.key,
    required this.message,
    this.highlightQuery = '',
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    // Blinking cursor for streaming
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _cursorOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(_cursorController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.sender == MessageSender.user;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Avatar + name row for assistant
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CampusFlow',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(widget.message.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message content
                _buildContent(isUser),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isUser) {
    if (isUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentIndigo, AppColors.accentViolet],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentIndigo.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.message.text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      );
    }

    // Assistant messages — check for rich content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: widget.message.isStreaming
                ? _buildStreamingText(widget.message.text)
                : _buildRichText(widget.message.text),
          ),
        if (widget.message.data != null) ...[
          const SizedBox(height: 8),
          _buildRichCard(),
        ],
      ],
    );
  }

  Widget _buildStreamingText(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: _buildRichText(text)),
        FadeTransition(
          opacity: _cursorOpacity,
          child: Text(
            '▌',
            style: GoogleFonts.inter(
              color: AppColors.accentTeal,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRichText(String text) {
    // Parse markdown-like formatting with optional search highlighting
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        _addSpansWithHighlight(spans, text.substring(lastEnd, match.start), false);
      }
      _addSpansWithHighlight(spans, match.group(1)!, true);
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      _addSpansWithHighlight(spans, text.substring(lastEnd), false);
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _addSpansWithHighlight(List<InlineSpan> spans, String text, bool isBold) {
    final query = widget.highlightQuery;
    final baseStyle = GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 14.5,
      height: 1.5,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
    );

    if (query.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
      return;
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: baseStyle.copyWith(
          backgroundColor: AppColors.warning.withValues(alpha: 0.3),
          color: AppColors.warning,
        ),
      ));
      start = idx + query.length;
    }
  }

  Widget _buildRichCard() {
    switch (widget.message.type) {
      case MessageType.duesCard:
        return DuesCard(dues: widget.message.data as DuesRecord);
      case MessageType.statusTable:
        return StatusTable(request: widget.message.data as ClearanceRequest);
      case MessageType.opportunityList:
        return OpportunityCardList(
            opportunities: widget.message.data as List<Opportunity>);
      case MessageType.paymentSummary:
        return PaymentSummaryCard(
            summary: widget.message.data as PaymentSummary);
      case MessageType.documentInfo:
        return DocumentCardList(
            documents: widget.message.data as List<CampusDocument>);
      case MessageType.notificationList:
        return NotificationCardList(
            notifications: widget.message.data as List<CampusNotification>);
      default:
        return const SizedBox.shrink();
    }
  }
}
