import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/route_chat_models.dart';
import '../services/chat_service.dart';
import '../widgets/puja_icons.dart';

/// Interactive Chatbot screen for UMA Route Assistant.
/// Grounded with real-time barricades, road closures, and crowd levels at $0 operational cost.
class RouteChatScreen extends StatefulWidget {
  const RouteChatScreen({
    super.key,
    this.initialRoute,
    this.initialQuestion,
    this.chatService,
  });

  final RouteSummary? initialRoute;
  final String? initialQuestion;
  final ChatService? chatService;

  static Route<void> route({RouteSummary? initialRoute, String? initialQuestion}) {
    return MaterialPageRoute(
      builder: (_) => RouteChatScreen(
        initialRoute: initialRoute,
        initialQuestion: initialQuestion,
      ),
    );
  }

  @override
  State<RouteChatScreen> createState() => _RouteChatScreenState();
}

class _RouteChatScreenState extends State<RouteChatScreen> {
  late final ChatService _chatService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<RouteChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showDisclaimer = true;

  final List<String> _quickChips = const [
    '🚶 Howrah to Kumartuli',
    '🚇 Nearest metro to Baghbazar',
    '🚧 Is College Street road open?',
    '👥 Least crowded pandals now',
    '🚨 Emergency Helplines',
    '🌙 Should I go now or after 11 PM?',
  ];

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService.instance;

    // Welcome greeting message
    _messages.add(
      RouteChatMessage(
        id: 'welcome_msg',
        text: 'নমস্কার! I am UMA Route Assistant. '
            'Ask me anything about walking routes, tonight’s barricades, crowd levels, or nearest metro stations.',
        isUser: false,
        timestamp: DateTime.now(),
        factsAsOf: DateTime.now(),
        usedLlm: false,
        suggestions: [
          'Howrah to Kumartuli best route?',
          'Nearest metro to Baghbazar?',
          'Any road closures near College Street?',
        ],
      ),
    );

    // If an initial route was provided, add context pill and optionally query
    if (widget.initialQuestion != null && widget.initialQuestion!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuestion!);
      });
    } else if (widget.initialRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final origin = widget.initialRoute!.originName ?? 'Origin';
        final dest = widget.initialRoute!.destinationName ?? 'Destination';
        _sendMessage('What are the active road closures or crowd on route from $origin to $dest?');
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();
    _inputController.clear();

    final userMsg = RouteChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
      text: clean,
      isUser: true,
      timestamp: DateTime.now(),
      routeSummary: widget.initialRoute,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _chatService.ask(
        clean,
        route: widget.initialRoute,
      );

      final botMsg = RouteChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_b',
        text: reply.answer,
        isUser: false,
        timestamp: DateTime.now(),
        factsAsOf: reply.factsAsOf,
        usedLlm: reply.usedLlm,
        isRateLimited: reply.isRateLimited,
        isError: reply.isError,
        suggestions: reply.suggestions,
      );

      if (mounted) {
        setState(() {
          _messages.add(botMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            RouteChatMessage(
              id: 'msg_${DateTime.now().millisecondsSinceEpoch}_err',
              text: 'Could not connect to route service. Showing offline safety guides.',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: PujaIcon.trishulEyes(
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'UMA Route Assistant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'পথের দিশারী • Live Grounded Facts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _messages.clear();
                _messages.add(
                  RouteChatMessage(
                    id: 'welcome_reset',
                    text: 'Chat cleared. How can I help you navigate Kolkata Durga Puja tonight?',
                    isUser: false,
                    timestamp: DateTime.now(),
                    factsAsOf: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Safety Disclaimer Banner
            if (_showDisclaimer)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF332A15)
                      : const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF6B5824) : const Color(0xFFFFD591),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Color(0xFFD46B08),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Conditions change quickly. Always follow Kolkata Police and volunteers on ground.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFFFC069) : const Color(0xFF873800),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showDisclaimer = false),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFFFFC069) : const Color(0xFF873800),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Active Route Context Pill (if attached)
            if (widget.initialRoute != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Route: ${widget.initialRoute!.originName ?? "Start"} → '
                        '${widget.initialRoute!.destinationName ?? "Destination"} '
                        '(${widget.initialRoute!.distanceKm.toStringAsFixed(1)} km • '
                        '~${widget.initialRoute!.durationMin} min)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, colorScheme, isDark);
                },
              ),
            ),

            // 4. Typing indicator
            if (_isLoading)
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Checking road blockages & crowd...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Quick-reply Chips Row
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickChips.length,
                itemBuilder: (context, idx) {
                  final chipText = _quickChips[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        chipText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _sendMessage(chipText),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 6. Bottom Input Field
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask about routes, blockages, metro...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                          suffixIcon: _inputController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _inputController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _inputController.text.trim().isNotEmpty && !_isLoading
                        ? () => _sendMessage(_inputController.text)
                        : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: colorScheme.surfaceContainerHigh,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    RouteChatMessage msg,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onPrimaryContainer,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                msg.formattedTime,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Assistant Message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PujaIcon.trishulEyes(
                      size: 15,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.4,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Metadata badges: Freshness + Engine Badge
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (msg.freshnessText != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    msg.freshnessText!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: msg.usedLlm
                                    ? Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12)
                                    : Colors.green.withValues(alpha: isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                msg.usedLlm ? '🤖 AI Answer' : '⚡ Grounded Facts',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: msg.usedLlm
                                      ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade800)
                                      : (isDark ? Colors.lightGreenAccent : Colors.green.shade800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Suggestions Chips (if provided)
            if (msg.suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: msg.suggestions.map((s) {
                    return ActionChip(
                      label: Text(
                        s,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                      onPressed: () => _sendMessage(s),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
