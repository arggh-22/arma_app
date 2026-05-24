# Phase 1: Telegram Link Status Refresh - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md.

**Date:** 2026-05-24
**Phase:** 01-telegram-link-status-refresh
**Areas discussed:** Check-status UX details

---

## Check-status UX details

| Option | Description | Selected |
|--------|-------------|----------|
| Disable button + show inline spinner + stay on screen | In-place status check feedback | ✓ |
| Keep button enabled + global loading | Less strict in-flight guard | |
| Navigate to separate loading/result screen | More complex transition | |

**User's choice:** Disable button + show inline spinner + stay on screen  
**Notes:** Keep user in same Telegram screen while checking.

| Option | Description | Selected |
|--------|-------------|----------|
| Success snackbar + go back to dashboard | Immediate completion path | ✓ |
| Show success in same screen | Manual navigation | |
| Auto-open Telegram bot | Force external action | |

**User's choice:** Success snackbar + go back to dashboard  
**Notes:** Returning to dashboard after `is_guest=false` is required.

| Option | Description | Selected |
|--------|-------------|----------|
| Error snackbar + immediate retry enabled | Fast recovery in same flow | ✓ |
| Full-screen error | Heavy fallback | |
| Silent failure | No user feedback | |

**User's choice:** Error snackbar + immediate retry enabled  
**Notes:** Retry must remain on same screen.

---

## the agent's Discretion

- Snackbar copy text details.
- Internal refresh method naming and structure.

## Deferred Ideas

None.
