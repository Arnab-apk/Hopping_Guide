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
        foregroundColor: PujaColors.festivalGold,
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
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: SquadChatService.instance.messagesStream(widget.squadCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: PujaColors.festivalGold));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PujaIcon.dhunuchiPriest(size: 54, color: PujaColors.festivalGold),
                        const SizedBox(height: 12),
                        Text(
                          'No Squad Messages Yet',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coordinate your route, crowd updates, and meetup points.',
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
                    ? PujaColors.festivalGold.withValues(alpha: 0.9)
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
                          color: isDark ? PujaColors.festivalGold : Colors.black87,
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
                        color: isMe ? Colors.black87 : (isDark ? Colors.white : Colors.black87),
                        height: 1.35,
                      ),
                    ),

                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.black54 : (isDark ? Colors.white38 : Colors.black45),
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
