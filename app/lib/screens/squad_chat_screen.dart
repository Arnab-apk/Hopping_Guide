import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import '../services/squad_chat_service.dart';
import '../services/squad_service.dart';
import '../widgets/puja_icons.dart';

/// Screen for private squad text chat, live crowd updates, and photo/video sharing.
class SquadChatScreen extends StatefulWidget {
  const SquadChatScreen({
    super.key,
    required this.squadCode,
    required this.squadName,
  });

  final String squadCode;
  final String squadName;

  static void open(BuildContext context, {required String squadCode, required String squadName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SquadChatScreen(
          squadCode: squadCode,
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
  bool _filterMediaOnly = false;
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUserModel;
    final senderId = user?.uid ?? 'user_self';
    final senderName = user?.displayName ?? 'You';
    final photoUrl = user?.photoUrl;

    _textController.clear();
    HapticFeedback.lightImpact();

    await SquadChatService.instance.sendText(
      widget.squadCode,
      senderId: senderId,
      senderName: senderName,
      text: text,
      senderPhotoUrl: photoUrl,
    );
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
                'Share Pandal Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take a live photo with camera or choose from gallery',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: PujaColors.festivalGold,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendPhoto(ImageSource.camera);
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: PujaColors.durgaRed,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendPhoto(ImageSource.gallery);
                    },
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

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );

      if (picked == null) return;

      if (mounted) {
        setState(() => _isSending = true);
      }

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;

      final base64String = base64Encode(bytes);
      final mediaDataUri = 'data:image/jpeg;base64,$base64String';

      await SquadChatService.instance.sendMedia(
        widget.squadCode,
        senderId: senderId,
        senderName: senderName,
        mediaUrl: mediaDataUri,
        isVideo: false,
        senderPhotoUrl: photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Photo shared with squad!'),
            backgroundColor: PujaColors.durgaRed,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildChatImage(String mediaUrl, {BoxFit fit = BoxFit.cover, double? height, double? width}) {
    if (mediaUrl.startsWith('data:image') || !mediaUrl.startsWith('http')) {
      try {
        final cleanBase64 = mediaUrl.contains(',') ? mediaUrl.split(',').last : mediaUrl;
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: fit,
          height: height,
          width: width,
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
      }
    }

    return CachedNetworkImage(
      imageUrl: mediaUrl,
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.squadName,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${squadService.members.length == 1 ? '1 member' : '${squadService.members.length} members'} · Code: ${widget.squadCode}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _filterMediaOnly ? 'Show All Messages' : 'Photos Only',
            icon: Icon(
              _filterMediaOnly ? Icons.chat_bubble_outline_rounded : Icons.photo_library_outlined,
              color: _filterMediaOnly ? PujaColors.festivalGold : null,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _filterMediaOnly = !_filterMediaOnly);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter indicator banner
          if (_filterMediaOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: PujaColors.festivalGold.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.collections_rounded, size: 16, color: PujaColors.festivalGold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Showing Shared Photos Gallery',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _filterMediaOnly = false),
                    child: const Text('Show All', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: SquadChatService.instance.messagesStream(widget.squadCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: PujaColors.festivalGold));
                }

                var messages = snapshot.data ?? [];
                if (_filterMediaOnly) {
                  messages = messages.where((m) => m.type != ChatMessageType.text).toList();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PujaIcon.dhunuchiPriest(size: 54, color: PujaColors.festivalGold),
                        const SizedBox(height: 12),
                        Text(
                          _filterMediaOnly ? 'No Shared Photos Yet' : 'No Squad Messages Yet',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _filterMediaOnly
                              ? 'Tap the camera icon below to share the first pandal moment!'
                              : 'Coordinate your route, crowd updates, and meetup points.',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.isUser(currentUserId);
                    return _buildMessageBubble(context, msg, isMe, isDark);
                  },
                );
              },
            ),
          ),

          // Sending loading indicator
          if (_isSending)
            const LinearProgressIndicator(
              minHeight: 2,
              color: PujaColors.festivalGold,
              backgroundColor: Colors.transparent,
            ),

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
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: PujaColors.festivalGold),
                    tooltip: 'Share Photo',
                    onPressed: _showMediaPicker,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message squad...',
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
                    decoration: const BoxDecoration(
                      color: PujaColors.durgaRed,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      tooltip: 'Send',
                      onPressed: _sendMessage,
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

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isMe, bool isDark) {
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: PujaColors.festivalGold.withValues(alpha: 0.2),
              child: Text(
                msg.senderInitials,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
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
                    ? PujaColors.durgaRed
                    : (isDark ? const Color(0xFF262732) : Colors.grey.shade200),
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
                          color: isDark ? PujaColors.festivalGold : Colors.black87,
                        ),
                      ),
                    ),

                  // Photo Display
                  if (msg.type == ChatMessageType.image && msg.mediaUrl != null) ...[
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
