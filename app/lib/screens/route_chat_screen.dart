import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/route_chat_models.dart';
import '../services/chat_service.dart';
import '../widgets/custom_trail_planner_dialog.dart';
import 'map_screen.dart';
import 'main_navigation_screen.dart';

/// Interactive Route Assistant for Kolkata Durga Puja.
/// Implements the clean, card-based, human UI redesign defined in
/// docs/features/GROUP_AND_CHAT_UI_REDESIGN.md.
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
  final TextEditingController _quickToController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<RouteChatMessage> _messages = [];
  bool _isLoading = false;
  ChatStatusSummary _status = ChatStatusSummary.fallback;

  final List<String> _suggestedQuestions = const [
    'Which pandals are least crowded now?',
    'Nearest metro to Baghbazar',
    'Is College Street open?',
    'Howrah to Kumartuli best route',
  ];

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService.instance;
    _loadStatus();

    // If an initial route was provided, send query
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

  Future<void> _loadStatus() async {
    try {
      final res = await _chatService.getStatus();
      if (mounted) {
        setState(() => _status = res);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _inputController.dispose();
    _quickToController.dispose();
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

      final isRouteRequest = RegExp(r'\b(route|way|walk|go to|directions|how to get|jabo|jao|rasta)\b', caseSensitive: false)
          .hasMatch(clean);
      final replyActions = <String>{
        ...reply.actions,
        if (isRouteRequest) 'show_on_map',
      }.toList();
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
        blocks: reply.blocks,
        actions: replyActions,
        sourceQuery: clean,
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
              text: 'Unable to connect to route service. Showing offline safety guides.',
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

  void _resetChat() {
    HapticFeedback.selectionClick();
    setState(() {
      _messages.clear();
      _inputController.clear();
      _quickToController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Route assistant',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Updated ${_status.updatedMinAgo} min ago · ${_status.closuresCount} closures tonight',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _resetChat,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('New chat'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(colorScheme, isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageItem(msg, colorScheme, isDark);
                      },
                    ),
            ),

            // Loading step indicator
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
                      'Checking route → Checking closures → Checking crowds...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Input Field
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Ask about routes, closures, metro…',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(_inputController.text),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
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

  /// Useful, informative empty state as specified in Section 4.1
  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Where to? Quick route card
          Text(
            'Where to?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        'From',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My location',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, size: 16, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        'To',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _quickToController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Choose pandal or station',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => CustomTrailPlannerDialog.show(context),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Build custom'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        final dest = _quickToController.text.trim();
                        _sendMessage(dest.isNotEmpty
                            ? 'Best way to $dest from current location'
                            : 'Best route to nearest major pandal');
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Check route'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Tonight near you
          Text(
            'Tonight near you',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ..._status.alerts.map((alert) {
            final isBlockage = alert.type == 'blockage';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBlockage
                    ? colorScheme.errorContainer.withValues(alpha: 0.25)
                    : colorScheme.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBlockage
                      ? colorScheme.error.withValues(alpha: 0.2)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isBlockage ? Icons.warning_amber_rounded : Icons.people_outline_rounded,
                    size: 18,
                    color: isBlockage ? colorScheme.error : colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          alert.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // 3. Try asking (List rows, appears once, no emojis)
          Text(
            'Try asking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          ..._suggestedQuestions.map((q) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                q,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _sendMessage(q),
            );
          }),
        ],
      ),
    );
  }

  /// Builds a user or assistant message item
  Widget _buildMessageItem(RouteChatMessage msg, ColorScheme colorScheme, bool isDark) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onPrimaryContainer,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    // Assistant Message: Document-style, left-aligned, no bubble, no avatar
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. One-sentence natural human answer
          Text(
            msg.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // 2. Structured Cards (Blocks)
          for (final block in msg.blocks) ...[
            _buildBlockCard(block, colorScheme, isDark),
            const SizedBox(height: 8),
          ],

          // 3. Engine / Update Metadata
          Text(
            msg.usedLlm
                ? (msg.freshnessText ?? 'Updated just now')
                : 'Basic answer · ${msg.freshnessText ?? "updated just now"}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),

          // 4. Message Actions Row
          if (msg.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: msg.actions.map((act) {
                return _buildActionButton(act, msg, colorScheme);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds structured fact card based on block type
  Widget _buildBlockCard(ChatFactBlock block, ColorScheme colorScheme, bool isDark) {
    switch (block) {
      case RouteBlock r:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alt_route, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${r.from} → ${r.to}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '~${r.durationMin} min on foot (${r.distanceKm.toStringAsFixed(1)} km)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (r.issues > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      '${r.issues} barricade/closure on route',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );

      case BlockageBlock b:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: colorScheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b.kind} near ${b.near}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${b.source} · ${b.updatedMinAgo} min ago',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case CrowdBlock c:
        Color crowdColor = Colors.green;
        if (c.level == 'high') crowdColor = Colors.orange;
        if (c.level == 'packed') crowdColor = Colors.red;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: crowdColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.place}: ${c.levelLabel}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${c.source} · ${c.updatedMinAgo} min ago',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case StationBlock s:
        final isMetro = s.kind.toLowerCase().contains('metro');
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(
                isMetro ? Icons.subway_outlined : Icons.train_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${s.kind} · ~${s.distanceM} m walk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () {
                  _sendMessage('Route to ${s.name} from current location');
                },
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Walk there'),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds action button under answer (e.g. Show on map, Share with group, Start walking)
  Widget _buildActionButton(String action, RouteChatMessage msg, ColorScheme colorScheme) {
    String label = action;
    IconData icon = Icons.open_in_new;

    switch (action) {
      case 'show_on_map':
        label = 'Show on map';
        icon = Icons.map_outlined;
        break;
      case 'share_with_group':
        label = 'Share with group';
        icon = Icons.share_outlined;
        break;
      case 'start_walking':
        label = 'Start walking';
        icon = Icons.directions_walk_rounded;
        break;
    }

    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        if (action == 'show_on_map' || action == 'start_walking') {
          final query = msg.sourceQuery;
          if (query != null && query.isNotEmpty) {
            MapScreen.requestAssistantRoute(context, query);
          } else {
            MainNavigationScreen.switchToTab(0);
          }
          Navigator.of(context).pop();
        } else if (action == 'share_with_group') {
          Clipboard.setData(ClipboardData(text: msg.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route update copied to clipboard for group share'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
