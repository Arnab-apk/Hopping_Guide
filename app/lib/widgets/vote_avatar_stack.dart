import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/squad_member.dart';

/// A horizontal stack of avatars showing who voted for a pandal.
/// Shows up to 4 avatars with an overflow badge (+N).
/// Current user's avatar is highlighted with a gold border.
/// Long press shows a tooltip with all voter names.
class VoteAvatarStack extends StatelessWidget {
  const VoteAvatarStack({
    super.key,
    required this.voters,
    this.currentUserId,
    this.maxVisible = 4,
    this.avatarSize = 24.0,
    this.showNamesOnHover = true,
  });

  final List<SquadMember> voters;
  final String? currentUserId;
  final int maxVisible;
  final double avatarSize;
  final bool showNamesOnHover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (voters.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleVoters = voters.take(maxVisible).toList();
    final overflowCount = voters.length - maxVisible;
    final stackWidth = visibleVoters.isEmpty
        ? 0.0
        : avatarSize + (visibleVoters.length - 1) * (avatarSize * 0.65);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar stack
        SizedBox(
          width: stackWidth,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: visibleVoters.asMap().entries.map((entry) {
              final index = entry.key;
              final voter = entry.value;
              final isCurrentUser = currentUserId != null && voter.id == currentUserId;

              return Positioned(
                left: (index * (avatarSize * 0.65)).toDouble(),
                child: _buildAvatar(voter, isCurrentUser, isDark, theme),
              );
            }).toList(),
          ),
        ),
        // Overflow badge
        if (overflowCount > 0) ...[
          const SizedBox(width: 4),
          _buildOverflowBadge(overflowCount, isDark, theme),
        ],
      ],
    );
  }

  Widget _buildAvatar(SquadMember voter, bool isCurrentUser, bool isDark, ThemeData theme) {
    final avatarColor = Color(voter.avatarColorHex);
    final borderColor = isCurrentUser ? AppColors.accentGold : avatarColor;
    final borderWidth = isCurrentUser ? 2.0 : 1.5;

    return Tooltip(
      message: voter.name.replaceAll(' (You)', ''),
      preferBelow: false,
      verticalOffset: 24,
      child: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: voter.photoUrl != null && voter.photoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: voter.photoUrl!,
                  fit: BoxFit.cover,
                  width: avatarSize,
                  height: avatarSize,
                  errorWidget: (context, url, error) => _buildFallbackAvatar(voter, avatarColor),
                )
              : _buildFallbackAvatar(voter, avatarColor),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(SquadMember voter, Color avatarColor) {
    return Container(
      color: avatarColor.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          voter.initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: avatarColor,
          ),
        ),
      ),
    );
  }

  Widget _buildOverflowBadge(int count, bool isDark, ThemeData theme) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white12 : Colors.black12,
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black26,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

/// Extended version with a label showing vote count and voter names on tap
class VoteAvatarStackWithLabel extends StatelessWidget {
  const VoteAvatarStackWithLabel({
    super.key,
    required this.voters,
    this.currentUserId,
    this.voteCount,
    this.maxVisible = 4,
    this.avatarSize = 24.0,
    this.onTap,
  });

  final List<SquadMember> voters;
  final String? currentUserId;
  final int? voteCount;
  final int maxVisible;
  final double avatarSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveCount = voteCount ?? voters.length;

    if (effectiveCount == 0 && voters.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoteAvatarStack(
              voters: voters,
              currentUserId: currentUserId,
              maxVisible: maxVisible,
              avatarSize: avatarSize,
            ),
            if (effectiveCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thumb_up_rounded,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$effectiveCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}