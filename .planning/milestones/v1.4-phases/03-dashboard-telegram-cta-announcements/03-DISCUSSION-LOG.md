# Phase 3 Discussion Log — Dashboard Telegram CTA & Announcements

**Date:** 2026-05-24  
**Phase:** 03-dashboard-telegram-cta-announcements

## Areas selected

- Discuss all key areas.

## Q&A trail

### 1) Linked-user CTA behavior
**Question:** For linked users (`is_guest=false`), how should the dashboard CTA behave?  
**User answer (refined):** Keep current FAB position/scroll behavior, open `@devarmabot` externally, and use icon-only CTA for linked users.

**Clarification asked:** Should linked CTA be icon-only while guests keep extended **Link** FAB?  
**User answer:** Yes.

### 2) Announcement visibility with partial payloads
**Question:** How should block render when fields are partially present?  
**User answer:** Show block if either title or text is non-empty; hide missing part gracefully.

### 3) Read more trigger rule
**Question:** When should **Read more** appear?  
**User answer:** Only when `announcement_text` is non-empty; tap opens bottom sheet with full text.

### 4) Announcement visual style
**Question:** What styling approach should be used?  
**User answer:** Existing dashboard card/surface style, placed between statistics and default servers.

## Captured decisions summary

- Guest users keep extended **Link** FAB to `/telegram-link`.
- Linked users get icon-only Telegram FAB opening `@devarmabot`.
- Announcement block appears if either title or text exists; missing piece is omitted cleanly.
- Read more appears only when full text exists; opens bottom sheet.
- Announcement UI follows existing dashboard card/surface style.

## Deferred / Out of Scope

- None.
