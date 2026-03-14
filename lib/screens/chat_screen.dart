import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/suggestion_chips.dart';
import '../services/pdf_export.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final provider = Provider.of<ChatProvider>(context, listen: false);
    provider.sendMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onChipTapped(String action) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    provider.sendQuickAction(action);
    _scrollToBottom();
  }


  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        Provider.of<ChatProvider>(context, listen: false).clearSearch();
      }
    });
  }

  void _onSearchChanged(String query) {
    Provider.of<ChatProvider>(context, listen: false).setSearchQuery(query);
  }

  void _exportChat() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final student = provider.currentStudent;
    if (student == null) return;

    await PdfExport.exportAndShare(student.name, provider.messages);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final student = chatProvider.currentStudent;
        if (student == null) {
          return const LoginScreen();
        }

        // Auto-scroll only when needed (flag-based — not every rebuild)
        if (chatProvider.needsScroll) {
          chatProvider.clearScrollFlag();
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }

        final displayMessages = chatProvider.searchQuery.isEmpty
            ? chatProvider.messages
            : chatProvider.filteredMessages;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(student, chatProvider),
          body: Column(
            children: [
              // Search bar
              if (_isSearching) _buildSearchBar(),

              // Messages list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: displayMessages.length + (chatProvider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayMessages.length && chatProvider.isTyping) {
                      return const TypingIndicator();
                    }
                    return MessageBubble(
                      message: displayMessages[index],
                      highlightQuery: chatProvider.searchQuery,
                    );
                  },
                ),
              ),

              // Suggestion chips
              SuggestionChips(onChipTapped: _onChipTapped),

              // Input bar
              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }



  PreferredSizeWidget _buildAppBar(Student student, ChatProvider chatProvider) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: const SizedBox(width: 12),
      leadingWidth: 12,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CampusFlow',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Online • Ready to help',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Search
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: _toggleSearch,
        ),
        // Overflow menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          color: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportChat();
                break;
              case 'profile':
                context.findAncestorStateOfType<MainScreenState>()?.switchToTab(5);
                break;
              case 'clear':
                Provider.of<ChatProvider>(context, listen: false).clearHistory();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentTeal, size: 20),
                  const SizedBox(width: 10),
                  Text('Export as PDF', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.accentIndigo, size: 20),
                  const SizedBox(width: 10),
                  Text('Profile', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Text('Clear History', style: GoogleFonts.inter(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
        // Notification bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
              onPressed: () => _onChipTapped('Show my notifications'),
            ),
            if (chatProvider.unreadNotificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${chatProvider.unreadNotificationCount}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentTeal.withValues(alpha: 0.3),
                AppColors.accentIndigo.withValues(alpha: 0.3),
                AppColors.accentViolet.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: _onSearchChanged,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentTeal),
          ),
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentIndigo.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
