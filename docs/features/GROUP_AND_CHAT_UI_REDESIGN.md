# 🎨 Group Page & Route Assistant UI Redesign

> Location: `docs/features/GROUP_AND_CHAT_UI_REDESIGN.md`
> Based on the current screens of the **Hopping Group** screen and the **UMA Route Assistant** screen.

---

## 1. What's Wrong Today

### 1.1 Group page
- **Duplicate entry points**: Bot icon in the app bar and a big "UMA Route Assistant" card. Chat icon in the app bar and a "Group Chat & Media" row.
- **Duplicate CTAs**: "+ Add" button and "Choose Pandals to Visit" button in the same card.
- **Every section is a card, and every empty card is large**: Members card, Pandals card, Assistant card, Chat row.
- **Group code is off-screen**: The code scrolls out of view.
- **Instruction text instead of affordance**: "Tap to view Profile", explanatory paragraphs.
- **Low-value info shown always**: Self row "0 m (Here)", battery 100%. Show battery only when < 20%.
- **No sense of "what do I do now?"**: Nothing changes between planning and actively hopping.

### 1.2 Route Assistant page
- **"Live Grounded Facts" subtitle and green "⚡ Grounded Facts" badge**: Internal engineering jargon shown to users.
- **"Ask me anything about…"**: Over-promises and reads like a generic template.
- **Suggestions shown twice**: In thread and in bottom emoji strip.
- **Emoji in chips** (🚶 🚇 🚧): Inconsistent with the app's clean Material icon set.
- **Big avatar + bubble for every assistant message**: Clutters the screen.
- **Huge empty area**: Empty state shows no real live info before first question.
- **Answers as plain text walls**: Route, closure, and crowd information should be scannable structured cards.

---

## 2. Design Principles

1. **One screen, one job.** Group = plan and coordinate. Assistant = answer route questions.
2. **Each action appears once.** Remove duplicates; keep the one closest to the thumb.
3. **Show state, not instructions.** Replace explanatory text with clear controls and live status.
4. **Answers are cards, not paragraphs.** Route, closure, and crowd get structured components with a one-line summary.
5. **Freshness over branding.** Show "updated 4 min ago" and source, never "AI-powered".
6. **Status uses color, icon *and* text.** Never color alone (accessibility & sunlight visibility).
7. **Usable one-handed, in the dark, in a crowd.** Big tap targets (48dp+), primary actions at the bottom, high contrast.

---

## 3. Group Page Architecture: Pinned Header + 3 Tabs

- **Pinned Header**:
  - `GroupCodeBar`: Code + Copy + Share
  - `MemberStrip`: Horizontal avatar strip + "Invite friends"
  - `TabBar`: **Trail**, **People**, **Chat** (with unread badge)
- **Trail Tab**:
  - Planning state: Reorderable list of stops with votes, "+ Add pandals", contextual "Check route" chips, and bottom primary "Start hopping ▶" button.
  - Live state: `NextStopBanner` with distance/time, closure warnings, crowd level, "Open route" and "Skip stop", plus separation indicator.
- **People Tab**:
  - Clean member list with distance to you, status, and battery % ONLY when < 20%.
- **Chat Tab**:
  - Embedded squad chat with real-time updates and media sharing.

---

## 4. Route Assistant Architecture: Scannable Cards & Natural Multi-lingual Tone

- **Human, natural language understanding**:
  - Understands English, natural Bengali, and colloquial Banglish (e.g. "koto dur?", "rasta bondho ache kina?", "kothay bhir kom?").
  - Answers in a warm, human, direct way (1-2 sentences), immediately followed by structured data cards.
- **Structured Answer Cards (`blocks`)**:
  - `RouteCard`: Origin → Destination, walk time, distance, issue count, actions (`Show on map`, `Start walking`).
  - `BlockageCard`: Barricade/closure type, location, source (police notice or user reports), age, "Still there? Yes / No".
  - `CrowdCard`: Visual crowd level bar (Quiet / Moderate / Busy / Packed), source, update age.
  - `StationCard`: Metro / Circular railway info, distance, walk action.
- **Useful Empty State**:
  - Quick From/To route card ("Where to?").
  - "Tonight near you": live top closures & crowd alerts.
  - "Try asking": single clean list of suggestions (no emoji) that vanishes after first query.
- **Assistant Message Style**:
  - Assistant answers render left-aligned directly on the background (no avatar, no bubble).
  - User messages render in right-aligned filled bubbles.
- **Engine Badge**:
  - Shows "Updated X min ago" (or "Basic answer · updated X min ago" on fallback), replacing AI jargon.
