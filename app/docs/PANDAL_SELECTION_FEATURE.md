# Collaborative Pandal Selection Feature

## Overview
This feature allows all squad/team members to express their preferences for pandals they want to visit together. It extends the existing "Pandals to Hop Together" card in the Groups screen with:

1. **Member Vote Avatars** - Visual display of which team members voted for each pandal
2. **My Selections Filter** - Toggle to show only pandals the current user voted for
3. **Enhanced Vote UI** - Clearer distinction between "Added by me" vs "Voted by me"
4. **Vote Count with Member Names** - Tooltip showing member names on hover/long-press

## Current State Analysis

### Existing Implementation
- `SquadPandalStop` model has `votes: List<String>` (user IDs)
- `SquadService.toggleVotePandal()` allows voting/unvoting
- Group screen shows vote count and thumb up button
- `SquadPandalPickerSheet` for adding pandals

### Gaps to Address
1. No visual indication of *who* voted (just a count)
2. No "My Selections" filter for personal view
3. Vote button doesn't show current user's vote state clearly
4. No way to see team member preferences at a glance

## Implementation Plan

### 1. Model Enhancements (`squad_pandal_stop.dart`)
- Add helper getters for vote details:
  - `voterNames` - Map of userId -> display name (from squad members)
  - `currentUserVoted` - Boolean for current user
  - `voteCount` - Already exists

### 2. Service Enhancements (`squad_service.dart`)
- Add method to get voter display names from member list
- Ensure vote sync works correctly across all members

### 3. UI Components

#### A. Vote Avatar Stack Widget (`widgets/vote_avatar_stack.dart`)
- Horizontal stack of member avatars who voted
- Max 4 visible + "+N" overflow
- Tooltip/long-press shows full names
- Current user's avatar highlighted

#### B. Enhanced Pandal Stop Tile (`group_screen.dart` - `_buildPandalStopTile`)
- Integrate VoteAvatarStack
- Add "My Selections" filter toggle in card header
- Show "Added by me" / "Voted by me" badges
- Improve vote button visual feedback

#### C. My Selections Filter State
- Add `_showMySelectionsOnly` state in GroupScreen
- Filter `_chosenPandals` based on current user's votes
- Persist filter preference locally

### 4. SquadPandalPickerSheet Enhancements
- Show vote status for each pandal (if already in squad list)
- Allow voting directly from picker sheet
- Show "Team wants this" indicator

## Data Flow

```
User taps vote button
    → SquadService.toggleVotePandal(pandalId)
        → Updates local _chosenPandals (adds/removes userId from votes)
        → Persists to SharedPreferences
        → Syncs to Firestore (squad document chosenPandals field)
        → notifyListeners()
            → GroupScreen rebuilds
            → VoteAvatarStack shows updated avatars
            → Vote count updates
```

## UI/UX Details

### Vote Avatar Stack
```
[Avatar1][Avatar2][Avatar3][+2]  ← Horizontal stack, max 4
```
- Each avatar: 24dp, circular, colored border based on member's avatarColor
- Current user: gold border highlight
- Overflow: "+N" badge with member count

### My Selections Toggle
- Chip/Toggle in "Pandals to Hop Together" card header
- Label: "My Selections" with filter icon
- When active: only shows pandals where currentUserVoted == true
- Empty state: "You haven't selected any pandals yet"

### Vote Button States
- **Not voted**: Outlined thumb_up, "Vote" tooltip
- **Voted**: Filled thumb_up, primary color, "Remove vote" tooltip
- Shows vote count next to icon

## Testing Scenarios
1. Host adds pandal → auto-votes for it
2. Companion votes for pandal → avatar appears
3. Multiple companions vote → avatar stack grows
4. Current user toggles "My Selections" → list filters
5. User removes vote → avatar disappears, count decrements
6. Real-time sync: Companion votes → current user sees update immediately

## Files to Modify
1. `app/lib/models/squad_pandal_stop.dart` - Add helper getters
2. `app/lib/services/squad_service.dart` - Ensure vote sync works
3. `app/lib/widgets/vote_avatar_stack.dart` - New widget
4. `app/lib/screens/group_screen.dart` - Enhanced UI with filter & avatar stack
5. `app/lib/widgets/squad_pandal_picker_sheet.dart` - Show vote status

## Rollout Notes
- Backward compatible: existing votes preserved
- No database migration needed (votes already in chosenPandals JSON)
- Works offline (local state) and online (Firestore sync)