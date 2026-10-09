import 'dart:convert';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/chat_message.dart';
import '../models/route_chat_models.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/squad_chat_service.dart';
import '../services/squad_service.dart';
import 'group_video_call_screen.dart';
import '../widgets/puja_icons.dart';

/// Screen for private squad text chat, live crowd updates, and photo/video sharing.
class SquadChatScreen extends StatefulWidget {
  const SquadChatScreen({
    super.key,
    required this.squadId,
    required this.squadName,
    this.embedded = false,
  });

  final String squadId;
  final String squadName;
  final bool embedded;

  static void open(BuildContext context, {required String squadId, required String squadName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SquadChatScreen(
          squadId: squadId,
          squadName: squadName,
        ),
      ),
    );
  }

  @override
  State<SquadChatScreen> createState() => _SquadChatScreenState();
}

class _SquadChatScreenState extends State<SquadChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _isBotThinking = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage({String? customText}) async {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUserModel;
    final senderId = user?.uid ?? 'user_self';
    final senderName = user?.displayName ?? 'You';
    final photoUrl = user?.photoUrl;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    try {
      await SquadChatService.instance.sendText(
      widget.squadId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      senderPhotoUrl: photoUrl,
    );

      if (!mounted) return;
      if (customText == null) _textController.clear();
      if (_shouldTriggerBot(text)) {
        _queryPujaBot(text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message could not be sent. Check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _shouldTriggerBot(String text) {
    final lower = text.toLowerCase().trim();
    return lower.startsWith('@bot') ||
        lower.startsWith('/bot') ||
        lower.startsWith('/ask') ||
        lower.startsWith('@puja') ||
        lower.startsWith('@pujo') ||
        lower.startsWith('@uma') ||
        lower.contains('@bot') ||
        lower.contains('@puja') ||
        lower.contains('@pujo');
  }

  Future<void> _queryPujaBot(String userQuery) async {
    setState(() => _isBotThinking = true);

    try {
      final squadService = Provider.of<SquadService>(context, listen: false);

      var cleanQuery = userQuery
          .replaceAll(RegExp(r'@[a-zA-Z0-9_]+'), '')
          .replaceAll(RegExp(r'^/(?:bot|ask)\s*', caseSensitive: false), '')
          .trim();
      if (cleanQuery.isEmpty) {
        cleanQuery = 'How is the crowd and what are the best pandals to visit near our circuit?';
      }

      RouteSummary? routeSummary;
      if (squadService.isHoppingActive && squadService.currentHoppingTarget != null) {
        final target = squadService.currentHoppingTarget!;
        routeSummary = RouteSummary(
          distanceM: 1200,
          durationS: 18 * 60,
          destinationName: target.pandalName,
        );
      } else if (squadService.chosenPandals.isNotEmpty) {
        final first = squadService.chosenPandals.first;
        final last = squadService.chosenPandals.last;
        routeSummary = RouteSummary(
          distanceM: 2500,
          durationS: 30 * 60,
          originName: first.pandalName,
          destinationName: last.pandalName,
        );
      }

      final reply = await ChatService.instance.ask(cleanQuery, route: routeSummary);
      final queryLang = ChatService.detectLanguage(cleanQuery);

      final buffer = StringBuffer(reply.answer.trim());

      for (final block in reply.blocks) {
        if (block is BlockageBlock) {
          if (queryLang == QueryLanguage.bengali) {
            buffer.writeln('\n⚠️ ${block.near}-এর কাছে ${block.kind} (${block.source})');
          } else if (queryLang == QueryLanguage.benglish) {
            buffer.writeln('\n⚠️ ${block.near}-er kache ${block.kind} (${block.source})');
          } else {
            buffer.writeln('\n⚠️ ${block.kind} near ${block.near} (${block.source})');
          }
        } else if (block is StationBlock) {
          final distKm = (block.distanceM / 1000).toStringAsFixed(1);
          if (queryLang == QueryLanguage.bengali) {
            buffer.writeln('\n🚇 যাতায়াত: ${block.name} (${block.kind}, প্রায় $distKm কিমি দূরে)');
          } else if (queryLang == QueryLanguage.benglish) {
            buffer.writeln('\n🚇 Transit: ${block.name} (${block.kind}, pray $distKm km dure)');
          } else {
            buffer.writeln('\n🚇 Transit: ${block.name} (${block.kind}, ~$distKm km away)');
          }
        } else if (block is CrowdBlock) {
          if (queryLang == QueryLanguage.bengali) {
            buffer.writeln('\n👥 ভিড়: ${block.place}-এ ${block.levelLabel}');
          } else if (queryLang == QueryLanguage.benglish) {
            buffer.writeln('\n👥 Bhir: ${block.place}-e ${block.levelLabel}');
          } else {
            buffer.writeln('\n👥 Crowd: ${block.levelLabel} at ${block.place}');
          }
        }
      }

      final botReplyText = buffer.toString().trim();

      await SquadChatService.instance.sendText(
        widget.squadId,
        senderId: 'system_pujo',
        senderName: 'Puja Bot 🪈',
        text: botReplyText,
      );
    } catch (e) {
      debugPrint('[SquadChat] Puja Bot error: $e');
      final queryLang = ChatService.detectLanguage(userQuery);
      final fallbackMsg = queryLang == QueryLanguage.bengali
          ? 'জয় মা দুর্গা! 🙏 সাময়িক সংযোগ সমস্যা হয়েছে, অনুগ্রহ করে স্কোয়াড ট্রেইল ট্যাব দেখে পরবর্তী মণ্ডপ চেক করুন।'
          : queryLang == QueryLanguage.benglish
              ? 'Joy Maa Durga! 🙏 Somoyik network somoshya hocche, apni amader squad trail tab theke next pandal check korte paren!'
              : 'Joy Maa Durga! 🙏 I had a brief network glitch, but you can check our squad trail tab for the next pandal stops!';
      await SquadChatService.instance.sendText(
        widget.squadId,
        senderId: 'system_pujo',
        senderName: 'Puja Bot 🪈',
        text: fallbackMsg,
      );
    } finally {
      if (mounted) {
        setState(() => _isBotThinking = false);
      }
    }
  }

  void _showMediaPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share a Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Take a photo or choose from your gallery',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildAttachOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndSendPhoto(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAttachOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndSendPhoto(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.chipMuted,
        side: const BorderSide(color: AppColors.chipMuted, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }

  Future<Uint8List> _ensureSafePhotoBytes(Uint8List original) async {
    // If already compact (<180 KB), it is 100% safe for Firestore and fast network transfer
    if (original.lengthInBytes <= 180 * 1024) return original;
    try {
      final codec = await ui.instantiateImageCodec(
        original,
        targetWidth: 600,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (byteData != null) {
        final downsampled = byteData.buffer.asUint8List();
        if (downsampled.lengthInBytes < original.lengthInBytes) {
          return downsampled;
        }
      }
    } catch (e) {
      debugPrint('[SquadChat] Downsampling photo fallback note: $e');
    }
    return original;
  }

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUserModel;
    final senderId = user?.uid ?? 'user_self';
    final senderName = user?.displayName ?? 'You';
    final photoUrl = user?.photoUrl;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 50,
      );

      if (picked == null) return;

      if (mounted) {
        setState(() => _isSending = true);
      }

      Uint8List bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;

      bytes = await _ensureSafePhotoBytes(bytes);

      if (bytes.lengthInBytes > 750 * 1024) {
        throw 'Image is too large (${(bytes.lengthInBytes / 1024).round()} KB). Please select a smaller photo.';
      }

      final base64String = base64Encode(bytes).replaceAll(RegExp(r'\s+'), '');
      final isPng = bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 &&
          bytes[2] == 0x4e && bytes[3] == 0x47;
      final mediaDataUri = 'data:image/${isPng ? 'png' : 'jpeg'};base64,$base64String';

      await SquadChatService.instance.sendMedia(
        widget.squadId,
        senderId: senderId,
        senderName: senderName,
        mediaUrl: mediaDataUri,
        isVideo: false,
        senderPhotoUrl: photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📸 Photo shared with group!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share photo: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildChatImage(String mediaUrl, {BoxFit fit = BoxFit.cover, double? height, double? width}) {
    final trimmed = mediaUrl.trim();
    if (trimmed.startsWith('data:image') || !trimmed.startsWith('http')) {
      try {
        String cleanBase64 = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        while (cleanBase64.length % 4 != 0) {
          cleanBase64 += '=';
        }
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: fit,
          height: height,
          width: width,
          cacheWidth: 800,
          errorBuilder: (c, e, s) => Container(
            height: height ?? 180,
            width: width,
            color: Colors.black12,
            child: const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
            ),
          ),
        );
      } catch (e) {
        debugPrint('[SquadChat] Error decoding base64 image: $e');
        return Container(
          height: height ?? 180,
          width: width,
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
          ),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      height: height,
      width: width,
      fit: fit,
      placeholder: (c, u) => Container(
        height: height ?? 180,
        width: width,
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(color: PujaColors.festivalGold),
        ),
      ),
      errorWidget: (c, u, e) => Container(
        height: height ?? 180,
        width: width,
        color: Colors.black12,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
        ),
      ),
    );
  }

  void _showMediaViewer(BuildContext context, ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: Text(
                msg.senderName,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (msg.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildChatImage(
                  msg.mediaUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            if (msg.text != null && msg.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  msg.text!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUserModel?.uid ?? 'user_self';
    final squadService = Provider.of<SquadService>(context);

    final chatBody = Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.video_call_rounded),
              label: const Text('Group video call'),
              onPressed: () => GroupVideoCallScreen.open(context,
                squadId: widget.squadId, squadName: widget.squadName),
            ),
          ),
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: SquadChatService.instance.messagesStream(widget.squadId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.chipMuted));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty && !_isBotThinking) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PujaIcon.dhunuchiPriest(size: 54, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          'No Group Messages Yet',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Coordinate your route, crowd updates, and meetup points.\nMention @bot or tap the prompts below to ask Puja Bot anytime!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final totalCount = messages.length + (_isBotThinking ? 1 : 0);
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (_isBotThinking && index == 0) {
                      return _buildThinkingBubble(context, isDark);
                    }
                    final messageIndex = _isBotThinking ? index - 1 : index;
                    final msg = messages[messageIndex];
                    final isMe = msg.isUser(currentUserId);
                    return _buildMessageBubble(context, msg, isMe, isDark);
                  },
                );
              },
            ),
          ),

          // Sending loading indicator
          if (_isSending)
            LinearProgressIndicator(
              minHeight: 2,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.transparent,
            ),

          // Quick Action Chips for Puja Bot
          _buildQuickActionChips(isDark),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1C22) : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Share Photo',
                    onPressed: _showMediaPicker,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message group or @bot...',
                        hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262730) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      tooltip: 'Send',
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

    if (widget.embedded) {
      return chatBody;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.squadName,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              squadService.members.length == 1 ? '1 member' : '${squadService.members.length} members',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Ask Puja Bot',
            onPressed: () {
              HapticFeedback.selectionClick();
              _textController.text = '@bot ';
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
              _focusNode.requestFocus();
            },
          ),
        ],
      ),
      body: chatBody,
    );
  }

  Widget _buildQuickActionChips(bool isDark) {
    final chips = [
      (
        icon: Icons.auto_awesome_rounded,
        label: '@bot Ask Bot',
        action: () {
          _textController.text = '@bot ';
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          _focusNode.requestFocus();
        },
      ),
      (
        icon: Icons.people_alt_outlined,
        label: 'Kothay bhir kom?',
        action: () => _sendMessage(customText: '@bot Kothay bhir kom ache ekhon?'),
      ),
      (
        icon: Icons.subway_outlined,
        label: 'Kacher metro?',
        action: () => _sendMessage(customText: '@bot Kacher metro station konta?'),
      ),
      (
        icon: Icons.local_activity_outlined,
        label: '🌸 সেরা পুজো?',
        action: () => _sendMessage(customText: '@bot কলকাতার সেরা পুজো কোনগুলো?'),
      ),
      (
        icon: Icons.traffic_outlined,
        label: 'Rasta bondho kina?',
        action: () => _sendMessage(customText: '@bot Rasta bondho ba police barricade ache kina?'),
      ),
      (
        icon: Icons.directions_walk_rounded,
        label: 'Next pandal route?',
        action: () => _sendMessage(customText: '@bot What is the best route and traffic condition to the next pandal?'),
      ),
      (
        icon: Icons.emergency_outlined,
        label: 'জরুরি হেল্পলাইন',
        action: () => _sendMessage(customText: '@bot পুলিশের জরুরি হেল্পলাইন নম্বর'),
      ),
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = chips[index];
          return ActionChip(
            avatar: Icon(item.icon, size: 14, color: AppColors.accentGold),
            label: Text(
              item.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF262730) : Colors.amber.shade50.withValues(alpha: 0.8),
            side: BorderSide(
              color: isDark ? AppColors.accentGold.withValues(alpha: 0.3) : AppColors.accentGold.withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              HapticFeedback.lightImpact();
              item.action();
            },
          );
        },
      ),
    );
  }

  Widget _buildThinkingBubble(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.accentGold, width: 1.2),
            ),
            child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.accentGold),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2215) : const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Puja Bot is checking Kolkata routes & crowd...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.accentGold : const Color(0xFF8A5A00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isMe, bool isDark) {
    final isBot = msg.senderId == 'system_pujo' || msg.senderName.contains('Puja Bot');
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    if (isBot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGold.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.accentGold, width: 1.5),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.accentGold),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF261E14) : const Color(0xFFFFF9EE),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accentGold.withValues(alpha: 0.4)
                        : AppColors.accentGold.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Puja Bot 🪈',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.accentGold : const Color(0xFF946200),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SQUAD GUIDE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.accentGold : const Color(0xFF946200),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (msg.text != null && msg.text!.isNotEmpty)
                      Text(
                        msg.text!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          height: 1.42,
                          color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF2C2518),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$timeStr · Shared with squad',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
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
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.chipMuted.withValues(alpha: 0.2),
              child: Text(
                msg.senderInitials,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.chipMuted),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.chipMuted
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg.senderName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.accentGold : Colors.black87,
                        ),
                      ),
                    ),

                  // Photo Display
                  if (msg.mediaUrl != null &&
                      msg.mediaUrl!.isNotEmpty &&
                      (msg.type == ChatMessageType.image || !msg.isVideo)) ...[
                    GestureDetector(
                      onTap: () => _showMediaViewer(context, msg),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildChatImage(
                          msg.mediaUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Text content
                  if (msg.text != null && msg.text!.isNotEmpty)
                    Text(
                      msg.text!,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        height: 1.35,
                      ),
                    ),

                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : (isDark ? Colors.white38 : Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
