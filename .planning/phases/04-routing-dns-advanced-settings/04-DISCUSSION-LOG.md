# Phase 4: Routing, DNS & Advanced Settings - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 04-routing-dns-advanced-settings
**Areas discussed:** Per-domain routing rules, Per-app proxy, DNS configuration, Xray engine & TLS tricks, Hysteria2 protocol

---

## Per-Domain Routing Rules

| Option | Description | Selected |
|--------|-------------|----------|
| Presets + simple custom rules | Region presets (Iran/China/Russia) for one-tap setup + ability to add individual domains as Proxy/Direct/Block | ✓ |
| Presets only | Just region bypass presets, no custom domain rules. Simpler UI. | |
| Full rule editor | Detailed rule editor with domain patterns, IP ranges, port ranges, regex support | |

**User's choice:** Presets + simple custom rules
**Notes:** Recommended option selected

| Option | Description | Selected |
|--------|-------------|----------|
| Bundled in-app | Hardcode known domestic domains/IPs. No external download needed. | |
| Download from community sources | Fetch geo rule sets from GitHub. More up-to-date but needs network. | |
| Both | Bundled defaults + option to update from community sources | ✓ |

**User's choice:** Both — bundled defaults + downloadable updates

| Option | Description | Selected |
|--------|-------------|----------|
| Simple domain list | User types domain, picks Proxy/Direct/Block from dropdown | ✓ |
| Category cards | Expandable cards per action category | |
| Agent's discretion | | |

**User's choice:** Simple domain list

---

## Per-App Proxy (Split Tunneling)

| Option | Description | Selected |
|--------|-------------|----------|
| Blacklist mode | All apps through VPN, exclude specific apps | |
| Whitelist mode | No apps through VPN, include specific apps | |
| User chooses mode | Toggle between blacklist and whitelist | ✓ |

**User's choice:** User chooses mode — toggle between blacklist and whitelist

| Option | Description | Selected |
|--------|-------------|----------|
| Scrollable list with search + checkboxes | All installed apps with icons, search, checkboxes | ✓ |
| Categorized list | Group by category with expand/collapse | |
| Agent's discretion | | |

**User's choice:** Scrollable list with search + checkboxes

---

## DNS Configuration

| Option | Description | Selected |
|--------|-------------|----------|
| DoH + plain DNS | DNS-over-HTTPS and plain DNS | |
| DoH + DoT + plain | All three DNS protocols | ✓ |
| Plain DNS only | Just custom DNS IP/port | |

**User's choice:** DoH + DoT + plain — support all three protocols

| Option | Description | Selected |
|--------|-------------|----------|
| Presets + custom input | Quick-select presets plus manual input | ✓ |
| Manual input only | User types DNS server manually | |
| Presets only | Pick from known providers only | |

**User's choice:** Presets + custom input

---

## Xray Engine & TLS Tricks

| Option | Description | Selected |
|--------|-------------|----------|
| Single "Advanced" section | One section with all toggles | |
| Separate sections | "Engine Settings" + "Anti-Censorship" as distinct groups | ✓ |
| Dedicated sub-screen | Full separate screen | |

**User's choice:** Separate sections — Engine Settings + Anti-Censorship

| Option | Description | Selected |
|--------|-------------|----------|
| Toggles + sensible defaults | Show detail fields only when toggle is ON | |
| All fields visible | Show all settings always with defaults pre-filled | |
| Preset profiles | Light/Moderate/Aggressive profiles | ✓ (modified) |

**User's choice:** Preset profiles PLUS full customization — profiles as starting points, all fields always visible with pre-filled defaults. User can select a profile and then tweak individual values.

---

## Hysteria2 Protocol

| Option | Description | Selected |
|--------|-------------|----------|
| Optional with auto-detect | Use bandwidth hints if provided, connect without if not | ✓ |
| Required fields | Always prompt for up/down bandwidth | |
| Not needed | Skip bandwidth hints entirely | |

**User's choice:** Optional with auto-detect

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, support salamander | Standard Hysteria2 obfuscation for GFW evasion | ✓ |
| No obfuscation | Keep it simple | |
| Agent's discretion | | |

**User's choice:** Yes, support salamander obfuscation

---

## Agent's Discretion

- Custom rule UI layout details
- Downloadable rule set update frequency
- TLS trick default values per preset profile
- Hysteria2 stream settings implementation

## Deferred Ideas

None
