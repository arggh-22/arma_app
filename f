commit 4d1f77a66afb0b1d652ff79cd37e0a0bf9b2f978
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 19 18:37:27 2026 +0400

    debug: add native config dump + sing-box log subscription
    
    Two debug additions to surface the actual issue:
    1. SingBoxEngine: dump full config JSON to logcat (native side)
    2. TrafficMonitor: subscribe to CommandLog + forward to logcat
       tag 'sing-box' — shows DNS queries, proxy connections, TLS errors
    
    Both marked as TEMP DEBUG — remove when issue is resolved.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit e5ade20badb2bfe1b4a722d2e6744936e2818ce0
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 19 18:33:41 2026 +0400

    debug: route sing-box logs to stderr for logcat visibility
    
    sing-box runtime logs (DNS, proxy connections, TLS errors) were going
    through CommandServer gRPC channel with no subscriber — invisible in
    logcat. Adding output: stderr routes them to Android logcat.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 749f8f1b2b6f4094d4de07e24e12ee88f7d3ae9f
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 19 18:04:13 2026 +0400

    fix: auto-default flow to xtls-rprx-vision for VLESS Reality+TCP
    
    ROOT CAUSE: Most Reality+TCP servers require 'xtls-rprx-vision' flow, but
    many share links omit the flow parameter (considering it implied). The
    config builder returned empty string → sing-box negotiated no flow → TLS
    handshake succeeded ('connected') but data channel failed → no internet.
    
    Changes:
    - _resolveFlow: auto-default to 'xtls-rprx-vision' for Reality+TCP when
      flow is null/empty. TLS-only servers still require explicit flow.
    - Fragment TLS config: changed from wrong boolean format to proper sing-box
      object format with enabled/size/sleep fields using VpnSettings values.
    - Added test for Reality+TCP flow auto-default.
    - Updated fragment tests for object format.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 339437f0584f6fc0e85ca580f6b127ce5ea00146
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 19 17:51:45 2026 +0400

    fix: critical VPN connectivity bugs — DNS fallback, socket protection, config validation
    
    Three critical bugs found during comprehensive sing-box migration audit:
    
    1. DNS server missing from Android VPN builder (SingBoxEngine.kt)
       - If TunOptions.dnsServerAddress was empty without throwing, no DNS
         was added to VpnService.Builder — Android apps using system resolver
         had no DNS configured on the VPN network
       - Fix: always add a fallback DNS (172.19.0.2, the next IP in our /30
         TUN subnet) when TunOptions provides no DNS address
    
    2. protect() return value ignored (SingBoxEngine.kt)
       - VpnService.protect(fd) returns boolean but was not checked
       - If protection fails, proxy sockets route through TUN → infinite loop
       - Fix: check return value, log critical error and throw on failure
    
    3. No pre-flight config validation (connection_provider.dart)
       - Config went straight from builder to engine without validation
       - Invalid fields (e.g., fragment on stock sing-box) silently broke proxy
       - Fix: call SingBoxPlatformService.validateOrThrow() before startVpn()
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit e7088604ae32b00081840f8a4b72326327dc5d0d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 21:41:22 2026 +0400

    docs: add subscription headers documentation
    
    Comprehensive reference for all HTTP headers sent with subscription
    requests, including header details, example request, Happ comparison
    table, implementation files, and initialization flow.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit fcc4a4150041fec0424f9a48354bfeaa28ce484f
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 21:27:54 2026 +0400

    fix: remove explicit Accept-Encoding header causing decode error
    
    Dart's http package handles gzip decompression automatically.
    Setting Accept-Encoding manually causes the server to send compressed
    data that the package doesn't know to decompress, resulting in
    FormatException: Unexpected extension byte.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 85db6519ed13816c585f6593f9f82797cf5f18e8
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 21:17:32 2026 +0400

    fix: change _service from late final to late to allow rebuild
    
    SubscriptionNotifier.build() is called on every Riverpod rebuild,
    but late final only allows a single assignment, causing
    LateInitializationError on subsequent rebuilds.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit fcf00c6d3c5240cff45fe5b8d19ce5e647fd8f83
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 21:15:02 2026 +0400

    feat: add X-App-Version subscription header
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit b80dce141be9fecb48c7aa21a0a54eca91948092
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 21:12:26 2026 +0400

    feat: implement Happ-style subscription headers
    
    Replace single User-Agent + client-name with individual headers:
    - User-Agent: arma/{version}/{os}/{hwid}
    - X-Hwid: persistent device fingerprint (UUID)
    - X-Device-Os: Android (capitalized)
    - X-Device-Model: hardware model from device_info_plus
    - X-Ver-Os: Android SDK/API level
    - X-Device-Locale: device language code
    - Accept-Encoding: gzip, br
    
    Initialize AndroidDeviceInfo at startup and inject via Riverpod
    provider override, matching SharedPreferences pattern.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 7227586a11debcf12d80718435ea041270222cfe
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 21:08:04 2026 +0400

    feat: add device fingerprint to client-name subscription header
    
    - client-name now sends: 'Arma VPN/1.0.0 (android 13) <uuid>'
    - Persistent UUID generated on first launch, stored in SharedPreferences
    - Uniquely identifies each device even with same app version
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit d058f42b621c821b6575003354707226c4930a1a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 21:01:14 2026 +0400

    feat: change subscription User-Agent to 'arma' and add client-name header
    
    - User-Agent: 'arma' (was Chrome browser string)
    - client-name: 'Arma VPN/1.0.0 (android 13)' with OS + version info
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit a11edf2cd560444eeb33375e6fbaf61506985678
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:53:15 2026 +0400

    chore: archive v1.2 milestone — Server List UX & Subscription Intelligence
    
    3 phases, 6 plans, 10 requirements — all complete.
    Archived ROADMAP + REQUIREMENTS to milestones/.
    PROJECT.md evolved with v1.2 achievements.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 20a70a82f63db4c677b4c33cc281be4e2914b241
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:51:42 2026 +0400

    docs: mark all v1.2 requirements complete
    
    GROUP-01..05, IMPORT-01, CARD-01..04 all checked off.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit ddfaf38b1b06e639fa1064f16d923bc939d9ffe2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:48:34 2026 +0400

    docs(phase-10): complete phase — verification + CARD-03 status
    
    All 4 CARD requirements verified and marked complete.
    Phase 10 verification report created.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 90116049d760f94fbfab273294ca984a3d3fe2ca
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:43:21 2026 +0400

    docs(10-02): complete server list wiring plan — Phase 10 fully done
    
    - SUMMARY.md with task commits and decisions
    - STATE.md advanced to plan 2/2, progress 100%
    - ROADMAP.md phase 10 marked complete
    - REQUIREMENTS.md: CARD-01, CARD-02, CARD-04 marked complete

commit c503c4b579c8da52379f821788a463d8ccd0e6ad
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:39:38 2026 +0400

    feat(10-02): wire Dismissible swipe-to-delete, undo snackbar, dividers, and flag emoji into ServerListScreen
    
    - Add Dismissible wrapper around ServerCard with endToStart direction and 0.4 threshold
    - Add _onServerDismissed with deleteServer call and undo snackbar (5s floating)
    - Add _undoDelete to re-insert server and restore active state
    - Add Divider(indent: 48) between cards within each group
    - Remove outer Padding(horizontal: 16) wrapper — padding now inside ServerCard
    - Disable swipe when multi-select mode is active (D-09)
    - Store undo buffer as local state (_deletedServer, _wasActiveServer)

commit 5794c69fb4796fc2766de3cb834c0d327610ec9a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:36:54 2026 +0400

    docs(10-01): complete server card redesign plan
    
    - Add 10-01-SUMMARY.md with task commits, decisions, and deviations

commit 4281d21cdc26db44d2a9809cd5f91b511358ae17
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:35:53 2026 +0400

    feat(10-01): redesign ServerCard to flat layout with flag emoji
    
    - Replace Card widget with Container+InkWell flat layout
    - Add required flagEmoji parameter (pre-computed, passed from caller)
    - Add description subtitle (conditional on server.description)
    - Move ProtocolBadge to trailing position (after name, before latency)
    - Replace checkmark+border selection with 4px left primary border
    - Remove address:port line, elevation, borderRadius, dark outline border
    - Wrap InkWell in Material(type: transparency) for ripple support
    - Add Semantics with flagEmoji, protocol, latency, selected state
    - Update server_list_screen.dart caller with flagEmoji and import

commit 3092ee9f178c034b37950ac66f73df8b5d79637a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:33:24 2026 +0400

    feat(10-01): add l10n keys and undo snackbar constant
    
    - Add snackBarDurationUndo (5s) constant to AppConstants
    - Add serverDeleted and undoDeletion keys to all 4 ARB files (en, fa, ru, zh)
    - Regenerate AppLocalizations with new keys

commit f7212c46a3905d4281490349fd743a0c6b1da149
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:07:23 2026 +0400

    chore(state): Phase 10 planned — 2 plans in 2 waves
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 864b0751b9ad0c0e4dde6a27029ec920b41fa5d3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 20:03:50 2026 +0400

    docs(10): create phase plan

commit 0b9bd1bfbcc8b8e71bce0cd59732dfca11bd48b9
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:57:45 2026 +0400

    docs(10): research phase domain

commit eaa8d793ec03c60ccf4ac96b54516699e577b5d2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:50:10 2026 +0400

    docs(10): fix 12px spacing exception + improve undo action label

commit e95bdba0cba54e3313e595b1f07448c4d8ba29de
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:45:52 2026 +0400

    docs(10): UI design contract

commit 87a8cee27737bab03163bc4efc143ea8b49bbfd5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:38:26 2026 +0400

    chore(state): Phase 10 discuss complete
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 921636c83725b0af52c2e53a4ee2460cebe8d4e1
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:37:37 2026 +0400

    chore(planning): Phase 10 discussion — 11 decisions locked
    
    Server Card Redesign context gathered:
    - Two-line compact flat layout (flag | name | protocol | latency, description below)
    - Remove address:port, flat list items with dividers
    - Blue left border accent for active server
    - Swipe-left to delete with red background + trash icon, 5s undo
    - Bare flag emoji 24-28px, globe fallback
    - Swipe disabled in multi-select mode
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit b9628d540c60fa66feec1758e04cd673e468f634
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:24:53 2026 +0400

    docs(phase-09): complete phase execution

commit d200c5f76ab4535b4a826ffa5770ca39244ab107
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:21:50 2026 +0400

    fix(09): use repository directly in batch refresh to avoid auto-dispose crash

commit 6c5e593a27996038dcc1f81006593b2eee48f7e4
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:18:55 2026 +0400

    fix(09): prevent Ref-after-dispose in batch subscription refresh

commit 83675acdb591d0a54ac286043f23ec5d4423b2e6
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:16:46 2026 +0400

    fix(09): add ref.mounted guards to prevent Ref-after-dispose in subscription refresh

commit 4a01ecc8674d60c690e01078602f1c406c0baa41
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:13:43 2026 +0400

    fix(09): manual group header gets collapse toggle and server count

commit 34bac4ab6e07a8fc01930009bb32b40e6ae90945
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:08:57 2026 +0400

    fix(09): default groups expanded, store collapsed IDs instead
    
    - Invert semantics: store collapsed group IDs (empty set = all expanded)
    - Rename SharedPreferences key: expanded_groups → collapsed_groups
    - Update server_list_screen to use new contains() logic
    - Regenerate Riverpod codegen
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit de9a4942ab62c7bac4f1be9f39e913048a5bd869
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 19:05:13 2026 +0400

    fix(09): clipboard URL import uses addSubscription for proper entity + headers

commit 6c6bc34925173a59f0baba7e89576d969aaab60c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:55:45 2026 +0400

    fix(09): correct groupCollapseProvider name in server_list_screen

commit d1881e39fbc46cfa359cff1deca72c797d3fa407
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:22:50 2026 +0400

    test(09): persist human verification items as UAT

commit d10a5c5a4cbabe70bc807794bedd226c6f4fc506
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:18:08 2026 +0400

    docs(09): update plan 09-02 progress

commit a546c2e16a91c20195163f87fdd718b08b968571
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:17:55 2026 +0400

    docs(09-02): complete ServerGroupHeader redesign & wiring plan

commit 325f0b2f06527e376bc194f50df2dcd291d0e27e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:16:48 2026 +0400

    feat(09-02): rewire ServerListScreen with collapse provider and menu actions
    
    - Replace _collapsedGroups Set with groupCollapseNotifierProvider (persistent)
    - Use subscription.id as collapse key, '__manual__' for manual group
    - Add _showDeleteAllDialog with confirmation AlertDialog
    - Add _copySubscriptionUrl with clipboard + snackbar toast
    - Pass onDeleteAll, onCopyUrl, onOpenSupport to ServerGroupHeader
    - Support icon opens supportUrl via launchUrl in external browser

commit 59bcb95352e06cbd6ea861a3be72661b77eaab49
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:15:16 2026 +0400

    feat(09-02): redesign ServerGroupHeader with progress bar, expiry, support icon, and 3-dot menu
    
    - Replace refresh button with PopupMenuButton (refresh/delete/copy)
    - Add LinearProgressIndicator with green/orange/red coloring by usage %
    - Add expiry line with red text + bold when <3 days remain
    - Add support_agent icon when supportUrl present
    - Add Semantics label on collapse toggle for accessibility
    - Remove _buildInfoLine, add _buildProgressBar, _formatDataUsage, _buildExpiryLine
    - Add onDeleteAll, onCopyUrl, onOpenSupport callback params

commit 76b3a92a05a417018c0035dd76d7569e64c01a49
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:12:27 2026 +0400

    docs(09): update plan 09-01 progress

commit cd89c13beb69e1eaf898d83b875b62c7ccc53daf
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:11:57 2026 +0400

    docs(09-01): complete collapse state provider & l10n foundation plan
    
    - SUMMARY.md for Phase 09 Plan 01
    - 2/2 tasks completed in 3min
    - GroupCollapseNotifier + 8 l10n keys across 4 locales

commit 676abc6ddf6e7d625c23e2a7680314b1840a2376
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:10:38 2026 +0400

    feat(09-01): add Phase 9 l10n strings to all 4 ARB files
    
    - 8 new keys: refreshSubscription, deleteAllServers, copySubscriptionUrl,
      deleteAllServersTitle, deleteAllServersBody, expiresInDays, expired
    - Added to en, fa, ru, zh ARB files with correct placeholders
    - flutter gen-l10n codegen complete (AppLocalizations updated)
    - subscription_provider.g.dart hash updated (build_runner side effect)

commit 507d6288af0e1c0e4fe73eb94b920c4fd6ae7de2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:08:34 2026 +0400

    feat(09-01): create GroupCollapseNotifier provider with SharedPreferences persistence
    
    - @Riverpod(keepAlive: true) notifier storing expanded group IDs as Set<String>
    - SharedPreferences-backed persistence under 'expanded_groups' key
    - isExpanded() and toggle() methods with sync UI + async persist
    - Default state is collapsed (empty set), keyed by subscription.id
    - build_runner codegen complete (.g.dart generated)

commit 246df5a29bd8a436af4c44a4f2959d388fc856c8
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 18:04:49 2026 +0400

    docs(state): phase 9 planned

commit 037b9ebbccd343113db7ee5ebff3f16225d2ca58
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 17:16:00 2026 +0400

    docs(09): create phase plan — subscription group headers

commit 1baf44382db9ee809829fc2ff9320d413e5dc011
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 17:09:33 2026 +0400

    docs(state): record phase 9 UI-SPEC session

commit d68460be224d21cc4b19c66b50312722aa5321d9
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 17:06:05 2026 +0400

    docs(09): fix UI-SPEC typography, spacing, copywriting per checker

commit 1593e55a241dca44d73fabdfe59429943e7f5a23
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:59:32 2026 +0400

    docs(09): UI design contract

commit b3d7a4fbb514a4fb331c74e61a0311af7f1e9f01
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:50:13 2026 +0400

    docs(09): research phase domain

commit af025c18074c7effafcfa50fc5f42728bf8eeafb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:40:03 2026 +0400

    docs(state): record phase 9 context session

commit eccae74c3de68092cad0ffbd9aacb39f18685178
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:40:03 2026 +0400

    docs(09): capture phase context

commit 5e82eb7d32bbe82663d8ccfeb2b3faa36e949614
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:26:03 2026 +0400

    docs(08): phase 8 complete — entity extensions, parsers, flag emoji, clipboard fix

commit 2a21802c61502ef1d9f20048a93d5d518f36ee65
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:24:03 2026 +0400

    docs(08-01): complete entity extensions + description/header parsers plan
    
    - SUMMARY.md: 2 tasks completed, 16 tests added, 0 regressions
    - Deviations: improved decodeParam fallback for emoji+percent-encoded text

commit 3073406d3344f9c2ea816b93aa842b5fcc0027fc
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:22:25 2026 +0400

    feat(08-01): implement description parser, support-url header, and provider wiring
    
    - ParserUtils: add extractNameAndDescription() with ?-separator, 30-char truncation (D-01, D-02)
    - ParserUtils: improve decodeParam() fallback for mixed emoji+percent-encoded text
    - SubscriptionParser: extract descriptions at subscription body level (D-03)
    - SubscriptionHeaders: add supportUrl field and support-url header parsing (D-13)
    - SubscriptionProvider: wire supportUrl through both add and refresh paths
    - 12 description parser tests + 4 support-url header tests all passing

commit d189284dc9140e55f219d58df76dd7c5fce44b66
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:21:55 2026 +0400

    docs(08-02): complete flag emoji utility + shared clipboard import handler plan
    
    - SUMMARY: 2/2 tasks, 33 tests, 5min duration
    - IMPORT-01 requirement satisfied

commit 7421ac109c2809fca010e854990c1c8e0cadc626
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:20:09 2026 +0400

    feat(08-02): extract shared clipboard import handler, fix empty-state import
    
    - Create ClipboardImportHandler with full detection chain (D-09, D-11)
    - Detection: URL → share link → base64/multi-line → error toast
    - ImportFab now delegates to ClipboardImportHandler (zero duplication)
    - ServerListScreen replaces broken _importFromClipboard with shared handler
    - Empty-state clipboard button now handles subscription URLs and base64
    - Remove unused imports from both ImportFab and ServerListScreen
    - Satisfies IMPORT-01: all content types auto-detected from empty state

commit 4c0bba322f194a6c91817e3198511d67b7bcfd6c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:18:24 2026 +0400

    test(08-01): add failing tests for description parser and support-url header
    
    - Description parser tests: name/description splitting, URL-decoding, truncation, edge cases
    - Support-url header tests: presence, absence, empty, regression for existing fields
    - Subscription body integration tests: base64 and plain text description extraction

commit 4c00a72b91e6d8bbbaddd20773a45175518b53ec
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:17:32 2026 +0400

    feat(08-02): create flag emoji extractor utility with unit tests
    
    - 3-tier detection: embedded emoji → ISO country code → country name
    - Tier 1: Regional Indicator Symbol pairs (U+1F1E6-U+1F1FF)
    - Tier 2: word-boundary regex for 70+ common VPN country codes
    - Tier 3: 23 country name fragments (case-insensitive)
    - Multi-flag names return first flag only (D-06)
    - Fallback to globe emoji for unrecognized names
    - Pure utility function, no persistence (D-07)
    - 33 unit tests covering all tiers, false positives, edge cases

commit fe3c972884f6de14885032b551881008792f86d5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:17:27 2026 +0400

    feat(08-01): add description and supportUrl fields to entities and Hive models
    
    - ServerConfig: add String? description field (Freezed entity + Hive @HiveField(3))
    - Subscription: add String? supportUrl field (Freezed entity + Hive @HiveField(18))
    - ServerConfigModel: toDomain/fromDomain mapping for description
    - SubscriptionModel: toDomain/fromDomain mapping for supportUrl
    - Regenerated .freezed.dart and .g.dart files via build_runner

commit 9b1c7a894b16141ca2c5f24a72844086188b69e1
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:12:21 2026 +0400

    docs(state): phase 8 planning complete

commit 787b9bec07e43655325abbaa6f8f28a919746740
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:08:52 2026 +0400

    docs(08): create phase plan — 2 plans in 1 wave

commit ad45759773f81d5181a0922e6bcdbd701f6decd1
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 16:00:34 2026 +0400

    docs(08): research phase domain

commit 6ddcb932b73368df8f50bdd3c4078f3fd2e5ccac
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 15:52:24 2026 +0400

    docs(state): record phase 8 context session

commit cef23b7fdafaf0774f70e20236abd64302319c46
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 15:52:16 2026 +0400

    docs(08): capture phase context

commit 489b66790a060dd649a1309457f20a4a076aa7c5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 15:43:52 2026 +0400

    docs: create milestone v1.2 roadmap (3 phases)

commit 7da75ef5a4fc65f57882485d0921f752f1d6d8bb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 15:32:23 2026 +0400

    docs: define milestone v1.2 requirements

commit b4d8516983dcb5417eb10b3c21d2b5edcfff0b3c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 15:09:25 2026 +0400

    docs: start milestone v1.2 Server List UX & Subscription Intelligence

commit f01377b20bf9219830d75f6ce823b330a5a620f6
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 14:48:09 2026 +0400

    feat: integrate network filter into server list screen
    
    When a subscription has network-filter header enabled, servers are
    filtered by name based on current network type:
    - Names containing 'LTE' or 'Only mobile' → visible only on mobile
    - Names containing 'WiFi' or 'Only Wifi' → visible only on WiFi
    - Other server names → always visible
    
    Uses connectivity_plus to detect current network type reactively.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 7497319639273e7665954d8c82c44a1479bd06ec
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 14:43:21 2026 +0400

    feat: add routing header support (V2Ray→sing-box conversion)
    
    Parse the subscription 'routing' HTTP header containing base64-encoded
    V2Ray routing rules and convert to sing-box route rules:
    - geosite:X → remote rule_set reference (SagerNet URLs)
    - geoip:X → remote rule_set reference
    - regexp:... → domain_regex
    - domain:/full: prefixes → domain_suffix/domain exact match
    - outboundTag direct/proxy/block → outbound/action mapping
    
    Subscription routing rules are injected before app custom rules,
    giving server-provided routing priority over user settings.
    
    Changes:
    - New subscription_routing_parser.dart (V2Ray→sing-box converter)
    - Added routing field to Subscription entity + Hive model (field 14)
    - Config builder accepts subscriptionRouting parameter
    - Connection provider looks up subscription routing before connect
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 79c278629b418856284abd5fd92f9f84d80ab612
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 14:33:47 2026 +0400

    feat: add v2RayTun-compatible subscription headers support
    
    Parse and apply HTTP response headers from subscription servers:
    - profile-title: server-provided display name (raw/base64)
    - profile-update-interval: auto-refresh interval in hours
    - announce/announce-url: announcements with colored text (#RRGGBB)
    - update-always: force refresh on every app open
    - network-filter: filter configs by WiFi/LTE network type
    - subscription-userinfo: already supported (upload/download/total/expire)
    
    Changes:
    - New SubscriptionHeaders parser with base64 decoding
    - Extended Subscription entity and Hive model (fields 4,5,10-13)
    - Announcement banner in ServerGroupHeader with colored text
    - Network filter provider using connectivity_plus
    - SubscriptionProvider applies profile-title and update-always logic
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit bf42f8e87d5ac222c0465bf96151d8c968a07ef7
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 14:17:48 2026 +0400

    fix: accumulate latency results across writeGroups callbacks

commit ab34044ac2da4ba7097fb60daf1a168aa0d6df76
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sat Apr 11 14:15:06 2026 +0400

    fix: ignore pre-test writeGroups callbacks in LatencyTestManager

commit 30a31eb4447f20b88cd6f1a97f6743c297375fee
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 02:15:36 2026 +0400

    fix: use separate cache file for latency test to avoid VPN lock conflict

commit f487beaee76119e5e087de2bfd3cf852b0c0d436
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 02:09:48 2026 +0400

    fix: disable cache_file in latency test config to avoid lock conflict

commit 8d0ce7d626e97ed3c88e8c7122ddcadf63d0e2cb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 02:05:11 2026 +0400

    refactor: remove Xray engine, use sing-box for all protocols
    
    Removes dual Go runtime conflict that caused VPN process crash
    (two gomobile libraries sharing one go.Seq bridge is unsupported).
    
    Changes:
    - Remove libv2ray.aar (Xray native library)
    - Remove XrayEngine.kt, XrayCoreManager.kt, xray_config_builder.dart
    - Rebuild libbox.aar v1.13.6 with full Go runtime (no stripping needed)
    - Remove engine type toggle from Settings UI
    - Remove engine type routing from Intent/MethodChannel
    - SingBoxCoreManager: remove System.loadLibrary("box") hack
    - Always use SingBoxConfigBuilder for all protocol types
    
    sing-box natively supports VLESS, VMess, Trojan, Shadowsocks,
    Hysteria2 — same protocol set as Xray.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit cac26e4ba7e2d3187f07742d8d0c5eb3114432bf
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 01:17:29 2026 +0400

    fix: rebuild libbox.aar v1.13.6 with with_clash_api tag
    
    Built from sing-box v1.13.6 source with official build tags:
    with_gvisor, with_quic, with_wireguard, with_utls, with_clash_api
    
    Go runtime classes stripped to avoid duplicate class conflict with
    libv2ray.aar (System.loadLibrary("box") in SingBoxCoreManager
    handles native library loading).
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 7d3b485378cbaeeb058217f37358facd2e7ccf0d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 01:08:30 2026 +0400

    fix: pass engineType via Intent (cross-process safe, not SharedPrefs)

commit 92f7280e0b273c031ae0dd576f5b97723a3410ff
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:52:18 2026 +0400

    fix: migrate sing-box config to 1.13+ format (remove legacy inbound/outbound fields)

commit cafc58649cda6fb8a808b94229ab1e6a5979ab7c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:44:56 2026 +0400

    fix(07): load libbox.so explicitly before sing-box init

commit ad8b39e65fd18d5459d9a179ea83768258efc6ba
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:39:33 2026 +0400

    test(07): persist human verification items as UAT

commit bc93631d89811740246d24d8ee6bb61e44420aee
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:32:56 2026 +0400

    docs(07-03): complete Dart Providers & Settings UI plan
    
    - SUMMARY.md with 2 task commits, self-check passed
    - Engine toggle, FakeIP settings, engine branching all verified
    - flutter build apk --debug successful

commit da4a641dbfb2bc2781f7894ccd8032975f6596d7
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:31:16 2026 +0400

    feat(07-03): Settings UI — engine toggle + FakeIP toggle + CIDR input + l10n
    
    - Engine SegmentedButton (sing-box/Xray-core) in Engine section (D-01)
    - APK size note under engine toggle (D-04)
    - FakeIP DNS SwitchListTile in DNS section (D-09)
    - FakeIP CIDR TextField visible when enabled (D-10)
    - 10 l10n keys added to en, fa, ru, zh ARBs
    - Regenerated l10n Dart classes
    - flutter build apk --debug verified

commit 673266cda4217da40cd56fef0867e5ea5268b40f
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:28:21 2026 +0400

    feat(07-03): add engineType to providers + engine branching in ConnectionNotifier
    
    - EngineSettings: add engineType field with setEngineType + D-03 auto-reconnect
    - DnsSettings: add fakeipEnabled + fakeipCidr fields with setter methods
    - ConnectionNotifier: branch SingBoxConfigBuilder vs XrayConfigBuilder (ENGINE-04)
    - Per-app native SharedPrefs only for Xray engine (D-13), cleared for sing-box
    - Regenerated .g.dart files via build_runner

commit 29a13ff40e4a2a76079c772462d998c516046656
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:24:20 2026 +0400

    docs(07-02): complete engine selection & per-app cleanup plan
    
    - SUMMARY.md with execution results and verification

commit 6370efaabfd05ff5097b07369c4a8e32c230b3d0
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:23:19 2026 +0400

    feat(07-02): add engine selection from SharedPreferences in ArmaVpnService
    
    - Add XrayEngine import
    - Add readEngineType() reading flutter.engine_type from FlutterSharedPreferences
    - Replace hardcoded SingBoxEngine() with when(engineType) selection
    - Default to sing-box when no preference set (D-02)
    - Select XrayEngine when engine_type is 'xray' (ENGINE-04)
    - Cross-process compatible via FlutterSharedPreferences with flutter. prefix

commit f065e835fdf818f2bcc447461adc6df1587fbc05
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:22:35 2026 +0400

    refactor(07-02): remove per-app OverrideOptions from SingBoxEngine
    
    - Remove perAppConfig-to-OverrideOptions population block
    - Pass empty OverrideOptions() for libbox API compatibility
    - Per-app filtering now config-driven via TUN inbound JSON (D-12)
    - StringArrayIterator import preserved (used in systemCertificates)
    - VpnEngine interface contract unchanged (perAppConfig param kept)

commit 574d0943becf16922e4da6687ee29940450d3aca
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:20:55 2026 +0400

    docs(07-01): complete config builder enhancements plan
    
    - SUMMARY.md with 3 tasks, 4 files, 43 tests passing
    - Remote rule-sets, FakeIP DNS, per-app TUN, settings persistence

commit 1d1f5de87b02e7af1ca4f7b89d3184ee722bb6a5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:19:49 2026 +0400

    test(07-01): add tests for remote rule-sets, FakeIP DNS, per-app TUN + existing verification
    
    - Remote rule-sets: Iran, China, Russia URLs, type remote, no path key
    - FakeIP: server with inet4_range, DNS rules A/AAAA, store_fakeip in cache
    - Per-app: blacklist exclude_package, whitelist include_package, disabled neither
    - Existing: LAN bypass ip_is_private, DNS types (https/tls/udp/local), sniffing
    - Existing: fragment + record_fragment in TLS, mux padding
    - 43 tests total, all passing

commit 2a19b9cee438742f5037ea33697827c7bbeadcb0
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:18:22 2026 +0400

    feat(07-01): remote rule-sets, FakeIP DNS, per-app TUN in config builder
    
    - Convert all region rule-sets from local to remote with SagerNet GitHub URLs
    - Add download_detour: proxy and update_interval: 7d to all rule-sets
    - Add FakeIP DNS server with configurable inet4_range when enabled
    - Add FakeIP DNS rule routing A/AAAA queries to fakeip-dns
    - Add store_fakeip to experimental cache_file when FakeIP enabled
    - Add include_package/exclude_package to TUN inbound for per-app proxy
    - Wire all new VpnSettings fields through build() method

commit 4e87881b5a363556df9c53cbb983034ef9a27aec
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:16:55 2026 +0400

    feat(07-01): add engineType, fakeipEnabled, fakeipCidr settings fields
    
    - Add _engineTypeKey, _fakeipEnabledKey, _fakeipCidrKey to datasource
    - Add getter/setter pairs with defaults: singbox, false, 198.18.0.0/15
    - Add matching fields to VpnSettings entity with constructor defaults
    - Wire fromDatasource factory to read new settings

commit 024dd418f21508588a558d0271308de1be8f1444
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:13:01 2026 +0400

    docs(state): phase 7 planning complete

commit 9c8591be44ce8d9439f9a65659a24704ab647b41
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Thu Apr 9 00:08:01 2026 +0400

    docs(07): create phase plan — 3 plans in 2 waves

commit 3c971a95021ac4368f7329fb804e31c3ecf45930
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 23:56:35 2026 +0400

    docs(07): research phase domain

commit 6683012d3dfdf1dc0d5046a529d0c5e0db426e1e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 23:46:58 2026 +0400

    docs(state): record phase 7 context session

commit c2f059911f32a172e5323d0c7640ac81dc685807
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 23:46:39 2026 +0400

    docs(07): capture phase context

commit 0aa7aa2bda9ae409fcfb85a7827f51aa891005b3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 23:24:31 2026 +0400

    docs(phase-06): evolve PROJECT.md after phase completion
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit b3f99ddbc83653a883375fa694e0da858024e3db
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 23:24:08 2026 +0400

    docs(phase-06): complete phase execution
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit c66f3ba49b080abb7bff1e19010bea2b8ad24a80
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 23:21:41 2026 +0400

    fix(06): resolve Kotlin compilation errors against actual libbox.aar API
    
    SingBoxEngine:
    - findConnectionOwner returns ConnectionOwner (not Int)
    - Remove non-existent overrides: serviceStarted, serviceReset, postServiceClose
    - Add missing overrides: setSystemProxyEnabled, writeDebugMessage
    - Fix Notification.body (was .message)
    
    XrayEngine:
    - Replace TrafficMonitor with inline Timer+queryStats (TrafficMonitor is now sing-box only)
    - Fix queryStats(String,String) signature (returns Long, takes 2 params)
    
    LatencyTestManager:
    - Fix CommandServerHandler stubs to match actual interface
    - Fix findConnectionOwner return type to ConnectionOwner
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 1b1d5fbecc11827ea83f75e36091eb2a7b5b343c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 23:13:44 2026 +0400

    fix(06): correct l10n import path and provider name for build
    
    - traffic_stats_card.dart: flutter_gen → arma_proxy_vpn_client/core/l10n
    - per_outbound_stats_sheet.dart: flutter_gen → arma_proxy_vpn_client/core/l10n
    - latency_provider.dart: connectionNotifierProvider → connectionProvider
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit c37223424e7b93204e0e19772a52690f288247ed
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:53:11 2026 +0400

    test(06): persist human verification items as UAT
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 9e0625e106108d1d0f49601621f5b407e3fc07d2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:52:57 2026 +0400

    test(06): verification — 4/4 automated, 6 human items pending
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 48c88919bef61939dfff34600173731ddfa99b47
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:45:18 2026 +0400

    docs(06-04): complete URLTest latency testing plan
    
    - SUMMARY.md with 2 tasks, 7 files, 3 deviations (all Rule 2 auto-fixed)
    - STATE.md: phase 06 complete, progress 100%
    - ROADMAP.md: phase 06 marked complete (4/4 plans)
    - REQUIREMENTS.md: MONITOR-05 marked complete

commit be93edf8c477821dcfcd3c682900b6a026cb9520
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:42:25 2026 +0400

    feat(06-04): SingBoxConfigBuilder.buildForLatencyTest + LatencyNotifier swap to sing-box
    
    - buildForLatencyTest generates URLTest outbound group config for batch latency probing
    - LatencyNotifier swapped from XrayConfigBuilder + measureDelay to SingBoxConfigBuilder + measureLatency
    - testServer uses D-12 active connection when VPN connected, temp instance when disconnected
    - testAllServers uses batches of 10 (URLTest tests all in group simultaneously)
    - No XrayConfigBuilder references remain in latency_provider.dart
    - Regenerated .g.dart files for latency and connection providers

commit 5702a26acf808e8662b5fa901d96fec86429128e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:40:02 2026 +0400

    feat(06-04): LatencyTestManager + measureLatency/testActiveLatency handlers
    
    - LatencyTestManager creates temp CommandServer/CommandClient for URLTest latency probing
    - MainActivity: measureLatency handler for bulk testing, testActiveLatency for D-12 active connection
    - VpnPlatformService: measureLatency returns Map<serverTag, delayMs>, testActiveLatency for single server
    - ArmaVpnService: MSG_TEST_LATENCY IPC handler with temp CommandClient for active connection testing
    - VpnServiceConnection: sendMessage method for custom IPC messages
    - Existing measureDelay preserved for Xray compatibility (Phase 7 dual-engine)

commit c1f48f56fba8e351a6eed85b08bf46a89daa1be4
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:20:42 2026 +0400

    docs(06-03): complete IPC pipeline extension + connection UI plan

commit 6094567ccafdb8d337734fbde83c58d69dc58451
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:11:41 2026 +0400

    feat(06-03): TrafficStatsCard connection count + PerOutboundStatsSheet + l10n
    
    - TrafficStatsCard shows connection count row when connectionsOut > 0
    - Tapping connection count opens PerOutboundStatsSheet bottom sheet
    - PerOutboundStatsSheet with per-outbound traffic breakdown and Semantics
    - formatBytes helper added to speed_formatter.dart for cumulative bytes
    - 7 new l10n keys across all 4 locale ARB files (en, fa, ru, zh)
    - flutter gen-l10n regenerated localizations

commit b6e5f06b96dbacc7fa01d205da2d5714d01da82e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:09:55 2026 +0400

    feat(06-03): extend IPC pipeline + Dart models + swap to SingBoxConfigBuilder
    
    - ServiceConnection.kt reads 6 fields from IPC (uplink, downlink, connectionsIn, connectionsOut, uplinkTotal, downlinkTotal)
    - TrafficStats entity extended with 4 new fields (uplinkTotal, downlinkTotal, connectionsIn, connectionsOut)
    - TrafficStatsNotifier parses all 6 fields from EventChannel stats events
    - ConnectionNotifier swapped from XrayConfigBuilder to SingBoxConfigBuilder

commit 8e05352af4aca6718e717d71d0d08bce22420858
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:06:43 2026 +0400

    docs(06-02): complete SingBoxEngine + CommandClient TrafficMonitor plan
    
    - SUMMARY.md with 2 task commits and all decisions
    - STATE.md advanced to plan 3 of 4, 71% progress
    - ROADMAP.md updated with phase 06 progress
    - REQUIREMENTS.md: MONITOR-01, MONITOR-02 marked complete

commit 5d623e4990a4138706afb062b728f402f6fcdcff
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:04:25 2026 +0400

    feat(06-02): rewrite TrafficMonitor for CommandClient subscription
    
    - Complete rewrite from timer-based Xray QueryStats to CommandClient push
    - Implements CommandClientHandler with writeStatus as primary data path
    - 6-param callback: uplink, downlink, connectionsIn, connectionsOut, uplinkTotal, downlinkTotal
    - Subscribe to Libbox.CommandStatus at 1-second intervals
    - No CoreController dependency — fully sing-box native

commit 666aed20b77fc2bd122da13b7b5ad5e7d011a11d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 22:03:33 2026 +0400

    feat(06-02): create SingBoxEngine with PlatformInterface + CommandServerHandler
    
    - SingBoxEngine implements VpnEngine + PlatformInterface (15 methods) + CommandServerHandler
    - Inverted TUN control via openTun callback (D-05)
    - CommandServer lifecycle: start → startOrReloadService → closeService → close
    - Verified shutdown order per Pitfall 1 and 4
    - ArmaVpnService defaults to SingBoxEngine (D-03)
    - Per-app proxy via OverrideOptions with StringArrayIterator
    - System CA certificates provided to sing-box for TLS verification

commit 234a31862af79461237b9a4882cfb8a407bcdc16
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 21:54:44 2026 +0400

    docs(06-01): complete VPN engine strategy pattern plan
    
    - 06-01-SUMMARY.md with execution results
    - STATE.md updated: plan 2/4, 57% progress, decisions recorded
    - ROADMAP.md updated: phase 06 progress (1/4 plans)
    - REQUIREMENTS.md: ENGINE-02, ENGINE-03 marked complete

commit fa9e17d0a878b076649a404030f21b6f197da803
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 21:52:41 2026 +0400

    feat(06-01): extract XrayEngine and refactor ArmaVpnService to VpnEngine strategy pattern
    
    - XrayEngine.kt: extracted Xray-core logic (TUN creation, core lifecycle, traffic monitoring)
    - ArmaVpnService.kt: thin shell delegating to VpnEngine interface (464 lines, down from 596)
    - sendStatsToClient extended to 6 fields (uplink, downlink, connectionsIn, connectionsOut, uplinkTotal, downlinkTotal)
    - Removed full config logging (T-06-03 security mitigation), only log config.length
    - Removed Xray-specific health check Handler.postDelayed from service
    - Per-app config read from SharedPreferences in service, passed as PerAppConfig to engine
    - XrayCoreManager.initialize() moved from onCreate to engine.start() (lazy init)

commit acd94b000fe1266717abeabb394512af618ac56d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 21:35:01 2026 +0400

    feat(06-01): create VpnEngine strategy interface, PerAppConfig, and StringArrayIterator
    
    - VpnEngine interface with start/stop/isRunning/startMonitoring/stopMonitoring
    - PerAppConfig data class for per-app proxy configuration
    - StringArrayIterator gomobile StringIterator adapter for sing-box
    - 6-param onStats callback (uplinkBps, downlinkBps, connectionsIn, connectionsOut, uplinkTotal, downlinkTotal)

commit c0acd91dfb023003efc807dfa4c61ec3b1eb3b57
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 03:10:58 2026 +0400

    fix(06): resolve plan checker blocker + warnings
    
    Blocker: Extend VpnEngine callback from 4→6 params (add uplinkTotal, downlinkTotal)
    - Plan 01: VpnEngine interface, XrayEngine, sendStatsToClient all use 6 params
    - Plan 02: TrafficMonitor.writeStatus forwards totals through callback
    - Plan 03: ServiceConnection reads and forwards all 6 fields
    
    Warning W-2: Implement D-12 (single server test via active connection)
    - Plan 04: testServer() uses active CommandServer when connected, temp instance when disconnected
    - Added testActiveLatency MethodChannel + Dart method
    
    Warning W-3: Mark RESEARCH.md open questions as RESOLVED
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 165d8002c49e70af1f3a6e3dca7a9770f1041b03
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:57:39 2026 +0400

    docs(06): create phase plan — 4 plans in 3 waves

commit 0f5f911a8be54a4d3c0f7df6705ade895085dcfc
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:41:24 2026 +0400

    docs(06): UI design contract

commit b010a424ad5e1105acbd4238eb38f46cc92a485a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:26:50 2026 +0400

    docs(06): research phase domain — libbox API decompiled, PlatformInterface/CommandServer/CommandClient patterns verified

commit b123abb77a68902979a9c6abd0b56c87d79b208e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:19:31 2026 +0400

    docs(state): record phase 6 context session

commit f361114442838491f1f3a5770480585b7934f5d5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:19:31 2026 +0400

    docs(06): capture phase context

commit 9a89f7efa35e4050231b80bfd121e4de44c8aeef
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:10:00 2026 +0400

    docs: mark Phase 5 complete — all 3 plans executed

commit 0d805af3856ef1d20188992a30c9541f74fe0d9b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:09:33 2026 +0400

    docs(05-03): complete config validation service + unit tests plan
    
    - SingBoxPlatformService with user-friendly error translation
    - 26 unit tests covering all protocol × transport × TLS combinations
    - All tests pass, dart analyze clean

commit a62fed1fcb5be7c767613218272a2dd59c441764
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:07:39 2026 +0400

    test(05-03): add comprehensive config builder unit tests
    
    - 23 tests covering all 5 protocols × 5 transports × TLS modes
    - Verifies sing-box terminology (no Xray terms: freedom, blackhole, vnext)
    - Verifies VLESS flow empty for non-TCP transports
    - Verifies H2 forces TLS even with security=none
    - Verifies WS early_data_header_name for Xray server compat
    - Covers routing (LAN bypass, Iran region), DNS, inbound, experimental

commit 7b555786e3e003b6a60536f0e77d70ea8c7def31
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:06:24 2026 +0400

    feat(05-03): create SingBoxPlatformService Dart validation wrapper
    
    - getVersion() wraps getSingBoxVersion MethodChannel call
    - checkConfig() wraps checkSingBoxConfig with user-friendly error translation
    - validateOrThrow() convenience method for connect-time validation
    - _toUserFriendlyError() translates raw engine errors per D-13/T-05-08
    - ConfigValidationException for typed error handling

commit c8d6828cc27994e170fa6b7c2023b01e8393029d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:04:16 2026 +0400

    chore(05-02): add android/build/ to gitignore

commit d9ed1ae5fb8d4aead6756feba28ef3b5ca7ec57d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:03:52 2026 +0400

    docs(05-02): complete sing-box config builder plan
    
    - SUMMARY: 2 tasks, 23 tests, 484-line config builder
    - All 5 protocols × 5 transports × 4 TLS modes
    - ECH field added to ServerConfig

commit db03809e84f7d287d935345894bd9576f1c9324c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:01:29 2026 +0400

    feat(05-02): add all 5 transport builders to SingBoxConfigBuilder
    
    - WebSocket: path, headers, max_early_data, early_data_header_name (Xray compat)
    - gRPC: service_name
    - HTTP/2: type 'http' (not 'h2'), host array, path, TLS forced by _buildTls
    - HTTPUpgrade: host, path (CONFIG-08)
    - TCP: null (omit transport entirely, sing-box default)
    - Switch expression dispatches all 5 network types

commit 56acaff5b7b6a96bdaee83e4142826f47353937c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 02:00:33 2026 +0400

    feat(05-02): implement SingBoxConfigBuilder with all protocols and TLS modes
    
    - SingBoxConfigBuilder.build() generates valid sing-box JSON configs
    - 5 protocols: VLESS, VMess, Trojan, Shadowsocks, Hysteria2
    - TLS/Reality/ECH/uTLS under unified tls object
    - DNS with type detection (https/tls/local/udp)
    - TUN inbound with sniff/auto_route/strict_route
    - Route with ip_is_private LAN bypass, rule_set geo references
    - Mux (h2mux) with Hysteria2 exclusion
    - Fragment on TLS object (not sockopt)
    - Added echConfig field to ServerConfig (freezed regenerated)
    - 23 tests passing

commit bfc3d5f1a02c70e521e703491d9a23bdecdc29cb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:57:29 2026 +0400

    test(05-02): add failing tests for SingBoxConfigBuilder
    
    - Protocol tests: VLESS/Reality, VMess, Trojan, Shadowsocks, Hysteria2
    - TLS tests: uTLS, Reality nested, H2 force-TLS, ECH, no-TLS
    - Structure tests: 3 outbounds (proxy/direct/block), sing-box terminology
    - Route tests: ip_is_private, auto_detect_interface, region rule_sets
    - TUN inbound, DNS, mux, fragment, no-Xray-terms tests

commit 73fe47bc8c09ebbbc2aa74d81372d86ef6012eb8
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:54:24 2026 +0400

    docs(05-01): complete sing-box native foundation plan
    
    - SUMMARY.md with 2 tasks, 2 deviations documented
    - libbox.aar + SingBoxCoreManager + MethodChannel bridge + .srs assets

commit 60d440ba1950c36ab1caa3e06055095da4a0bfaf
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:52:39 2026 +0400

    feat(05-01): add SingBoxCoreManager and MethodChannel bridge
    
    - Created SingBoxCoreManager.kt singleton with setup/getVersion/checkConfig
    - Copies .srs rule-set files from APK assets to sing-box working dir
    - Added getSingBoxVersion and checkSingBoxConfig to MainActivity MethodChannel
    - Both handlers use coroutines (Dispatchers.IO) for non-blocking execution
    - T-05-03 mitigated: checkConfig does not log config JSON content
    - All existing MethodChannel handlers preserved unchanged

commit a5a5c41999ee9a9fad878e68b4d12b933b18b93a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:52:29 2026 +0400

    fix(05-01): strip duplicate go.Seq runtime from libbox.aar
    
    - Both gomobile-built AARs include identical go.Seq runtime classes
    - Removed go/ package from libbox.aar classes.jar to resolve conflict
    - libv2ray.aar provides the shared go.Seq runtime
    - Android project now compiles with dual AAR (no class conflicts)

commit 2920594724d6e7a1a854b6da48f75f52e9b1d19a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:48:19 2026 +0400

    feat(05-01): add libbox.aar and .srs geo rule-set assets
    
    - Built libbox.aar from sing-box v1.13.6 source with gomobile bind
    - Build tags: with_gvisor,with_quic,with_utls (D-03 minimal set)
    - Bundled 7 .srs rule-set files (Iran, China, Russia + geosite-private)
    - geoip-private.srs omitted: sing-box uses ip_is_private natively
    - Existing libv2ray.aar and geoip.dat/geosite.dat preserved (D-04)

commit 0e63f6cd5e9dc3c4947e896f54bb3505227da35b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:37:46 2026 +0400

    docs(state): Phase 5 planned — 3 plans ready

commit ffb5db59a43a066d5b08e309bab60d62237c70cb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:37:39 2026 +0400

    fix(05): add server_config.dart to Plan 02 files_modified (W-1)
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 2cf9a886f565ab8d8633043e03eccc2458da327b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:32:15 2026 +0400

    docs(05): create phase plan — 3 plans in 2 waves

commit 81dc332669ac4f97505317e2bc08196fd2705ca7
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:16:42 2026 +0400

    docs(05): research phase domain — sing-box config builder + library integration

commit 3e75bca879bda62ac2d26afc76fc9b9e5002d08a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:08:49 2026 +0400

    docs(state): record phase 5 context session

commit 0c2743969c1d19b01eecd42cc0d1bd322edb2792
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 01:08:40 2026 +0400

    docs(05): capture phase context

commit c07aec31f03c5f441b6b3cc30a53a51eb9fb2260
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 00:58:12 2026 +0400

    working x-ray

commit 1d6da906fa4b38bb7ca36f90fdd7eda782f581d5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 00:56:10 2026 +0400

    docs: create milestone v1.1 roadmap (3 phases)

commit 4ac758986e60d14a0ee0703c0ec8e7aa0796645a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 00:47:19 2026 +0400

    docs: define milestone v1.1 requirements (27 reqs, 6 categories)

commit 17d1c43f4e2401fa382b6eb204b0605e321f7136
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 00:31:21 2026 +0400

    docs: complete v1.1 sing-box engine migration research

commit 556c35ce745372795fa9b06dc8d7be55b98da7e6
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Wed Apr 8 00:07:48 2026 +0400

    docs: start milestone v1.1 — sing-box engine migration
    
    Replace Xray-core with sing-box for cross-platform support.
    v1.0 requirements validated, old phase dirs cleared.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 4e79b211a10f34235a8e9c3978b75ed756412db2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Mon Apr 6 00:42:30 2026 +0400

    docs: mark Phase 4 complete — all phases done
    
    Phase 4: Routing, DNS & Advanced Settings
    - 5 plans executed across 3 waves
    - 129/130 tests pass (1 pre-existing template test)
    - All 8 requirements verified: PROTO-05, ROUTE-02-05, UI-04-06
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit abfe1f91b280807d106c2f2954e6165a9ad32983
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Mon Apr 6 00:24:49 2026 +0400

    docs(04-05): complete routing screen UI plan summary
    
    - 2 tasks completed: routing provider + region/domain UI, per-app proxy section
    - 9 files created/modified
    - Requirements completed: ROUTE-03, ROUTE-04, ROUTE-05

commit f66bed85b44b10a35695e3b2b14fb302ae92dffe
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Mon Apr 6 00:23:36 2026 +0400

    feat(04-05): per-app proxy section with installed apps provider and app picker
    
    - Add InstalledApp model and installedAppsProvider FutureProvider via VpnPlatformService
    - Add AppPickerList with SearchBar, base64 app icons, and checkbox selection
    - Add Per-App Proxy ExpansionTile with enable toggle and blacklist/whitelist SegmentedButton
    - AnimatedSize wraps app picker for smooth show/hide on perAppEnabled toggle
    - Mode description text updates below SegmentedButton based on current mode
    - ConstrainedBox maxHeight 400 with ListView.builder for efficient rendering

commit 51101bd33117107fe1b2295b60a1e7c9434841d2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Mon Apr 6 00:18:39 2026 +0400

    feat(04-05): routing provider, region presets, and domain rules UI
    
    - Add RoutingSettingsNotifier with Riverpod for bypass LAN, regions, domain rules, per-app proxy
    - Add RegionPresetsSection with FilterChip row for Iran/China/Russia
    - Add DomainRuleRow with color-coded action dropdown and delete button
    - Add AddDomainRuleDialog with domain validation and SegmentedButton
    - Replace routing_screen.dart StatefulWidget with ConsumerStatefulWidget
    - Add ExpansionTile sections for Region Presets and Domain Rules
    - Domain rule delete shows SnackBar with undo action

commit f788743d367c9270c4de0c579df1051ca96d7b2c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Mon Apr 6 00:13:06 2026 +0400

    docs(04-04): complete settings screen extensions plan summary
    
    - DNS, engine settings, anti-censorship, and data sections implemented
    - 3 Riverpod providers with SharedPreferences auto-save
    - DNS picker sheet with 5 presets and custom input

commit e0c0e7add6457cc30c35acc062d2a724d2b4bedf
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Mon Apr 6 00:11:53 2026 +0400

    feat(04-04): add anti-censorship section with profiles and data section with cache clearing
    
    - Create AntiCensorshipNotifier with profile presets (none/light/moderate/aggressive)
    - Profile presets auto-fill fragment, sleep, padding, mixed SNI values
    - Add Anti-Censorship section with SegmentedButton profile selector
    - Add AnimatedSize for fragment size/sleep range TextFormFields
    - Add padding and mixed SNI toggle switches
    - Add Data section with clear cached data dialog (scoped to .dat + temp files)
    - Confirmation dialog uses colorScheme.error for destructive action

commit 306a3f1c8cbc00e8abe781c45ec0027458ce64f4
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Mon Apr 6 00:09:27 2026 +0400

    feat(04-04): add DNS and engine settings providers, DNS picker sheet, settings screen sections
    
    - Create EngineSettingsNotifier with sniffing/mux/concurrency auto-save
    - Create DnsSettingsNotifier with protocol/remoteDns/directDns auto-save
    - Create DnsPickerSheet with 5 presets (Cloudflare, Google, Quad9, AdGuard, Electro) + custom input
    - Add DNS section with SegmentedButton (DoH/DoT/Plain) and remote/direct DNS pickers
    - Add Engine Settings section with sniffing/mux toggles and AnimatedSize concurrency slider
    - Regenerate l10n files for new settings keys

commit bfd9ccc3578ac176fb4eb106331df9168d8c7a2c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:57:25 2026 +0400

    docs(04-03): complete native per-app proxy plan summary

commit ed2730c2b5dd8f63397065cb07e5300a11459587
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:56:31 2026 +0400

    feat(04-03): add per-app routing to ArmaVpnService configureTunInterface
    
    - Whitelist mode: only selected apps via addAllowedApplication (no mixing)
    - Blacklist mode: selected apps excluded via addDisallowedApplication
    - Default (no per-app config): self-exclusion only, preserving Phase 2 behavior
    - Each add call wrapped in try-catch for uninstalled app resilience
    - Reads config from SharedPreferences (per_app_config) set by MainActivity

commit c47c05c9623e57db0c9ad263db97faea46370b04
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:55:46 2026 +0400

    feat(04-03): add getInstalledApps + setPerAppConfig MethodChannel handlers
    
    - Add getInstalledApps handler in MainActivity returning sorted user apps with base64 icons
    - Add setPerAppConfig handler persisting mode/apps to SharedPreferences (per_app_config)
    - Add getInstalledApps() Dart wrapper in VpnPlatformService
    - Replace setPerAppConfig stub with real MethodChannel invocation
    - System apps filtered via ApplicationInfo.FLAG_SYSTEM
    - Uses debugPrint for error logging per lint rules

commit 27576b835ca30a757e6c713d3f5a80b30912d6e2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:49:32 2026 +0400

    docs(04-02): complete config builder VpnSettings integration plan
    
    - SUMMARY.md with full execution record and self-check PASSED

commit 5e7ad63b7e6cbf940e4e4a56686cc7e61f98b5a3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:48:36 2026 +0400

    feat(04-02): wire ConnectionNotifier to read VpnSettings at connect time
    
    - Read VpnSettings from SharedPreferences + Hive at connect time
    - Pass VpnSettings to XrayConfigBuilder.build() for user-configurable config
    - Add per-app proxy config call wrapped in try-catch (stub for Plan 03)
    - Add setPerAppConfig stub to VpnPlatformService (Rule 3: blocking fix)
    - Regenerated connection_provider.g.dart with updated hash

commit 218f9e33c3e869fc48b3d0762ea96236c3f3edf1
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:47:02 2026 +0400

    feat(04-02): extend XrayConfigBuilder with VpnSettings parameter
    
    - Add optional VpnSettings parameter to build() for user-configurable settings
    - DNS accepts remoteDns/directDns for DoH/DoT/plain protocols
    - Sniffing toggle controls TUN inbound sniffing.enabled + routeOnly field
    - Mux config added to proxy outbound when enabled (excluded for Hysteria2)
    - Fragment sockopt with tlshello packets for anti-censorship
    - Hysteria2 gets dedicated stream settings with network: hysteria2
    - Hysteria2 bandwidth hints (up_mbps/down_mbps) added conditionally
    - Routing supports region presets (iran/china/russia) and custom domain rules
    - LAN bypass now conditional per user setting
    - Backward compatible: build() with no settings uses VpnSettings defaults

commit 92a5b8aba8462efa8f16a01c22ff9644d0cf887b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:38:22 2026 +0400

    feat(04-01): ServerConfig Hysteria2 fields, l10n keys, build_runner, Hive registration
    
    - Added upMbps, downMbps, insecure fields to ServerConfig (Freezed)
    - Added @HiveField(45-47) to ServerConfigModel for Hysteria2 persistence
    - Updated toDomain/fromDomain mappings with new fields
    - Added 70+ l10n keys to all 4 locales (en, fa, ru, zh) for Phase 4 UI
    - Registered DomainRuleModelAdapter and opened domain_rules box in main.dart
    - Ran build_runner: regenerated freezed, json_serializable, hive adapters

commit e08547b23dd727453a0620bb121d8c849640c048
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:35:18 2026 +0400

    feat(04-01): settings persistence, VpnSettings data class, DomainRule model
    
    - Extended SettingsLocalDatasource with all Phase 4 SharedPreferences keys
    - Created VpnSettings aggregator with fromDatasource factory constructor
    - Created DomainRule domain entity (proxy/direct/block actions)
    - Created DomainRuleModel Hive model (typeId: 2)
    - Created RoutingLocalDatasource with CRUD operations for domain rules

commit 79544a116ed3b639b8263da1b7a71e9d70ec7038
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:31:06 2026 +0400

    docs(state): Phase 4 planned — 5 plans ready to execute
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 932566dd9e15d20776f407361ef00fca5e1c93f7
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:23:37 2026 +0400

    docs(04): create phase plan — 5 plans in 3 waves

commit 4b4fdd21fadf3dacb5a6f13390ceceee42770e11
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 23:06:18 2026 +0400

    docs(04): research phase domain

commit e1eacaf76e62fdcfe48bf411c2b05457fa43f1ef
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 22:53:16 2026 +0400

    docs(04): revise UI design contract — fix copywriting and spacing issues

commit bf8ef06fed1fa1bdea3f27b95d02949de11b8a50
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 22:46:17 2026 +0400

    docs(04): UI design contract

commit b4d724832ba16c31b88114232dda1fbd5b7ff0b4
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 22:40:04 2026 +0400

    docs(state): record phase 4 context session

commit 153f184c721519900640e5f9e98a649d2becbc20
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 22:39:58 2026 +0400

    docs(04): capture phase context

commit e990d659ad9157fd1cb7b0c550d24c978dab6e87
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 22:19:39 2026 +0400

    chore: mark Phase 3 complete — 3/4 phases done
    
    Phase 3 delivered: subscription management, QR scanning, latency
    testing, bulk operations, sort/filter, log viewer.
    
    Bug fixes applied during testing:
    - MeasureDelay GeoIP fix (buildForLatencyTest)
    - Smart clipboard import (URL/link/base64 auto-detect)
    - Lifecycle-aware VPN state management
    - Disconnect/reconnect race condition
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 2708a87668b2a23cf4e71a7f39f7116f2ea94f39
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 22:16:12 2026 +0400

    fix: prevent disconnect/reconnect race condition — zero traffic bug
    
    Root cause: stopVpnService() sent BOTH Messenger STOP + Intent STOP.
    On fast reconnect, the queued Intent STOP arrived AFTER the new Intent
    START, killing the just-started connection:
    
      Messenger STOP → Intent START → Intent STOP ← kills reconnect!
    
    Fixes:
    - stopVpnService: use only Messenger (immediate, no queuing race)
    - stopVpn: skip if already stopped (guard against stale commands)
    - startVpn: verify isRunning after startLoop — throw if core failed
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 8cf63a36023b6311327464feb297e05664c41f1c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 22:05:42 2026 +0400

    fix: lifecycle-aware VPN state management — fixes stuck states
    
    - Add WidgetsBindingObserver to re-sync state when app returns to foreground
    - Add resyncState() that queries actual native VPN running state
    - Add state timeouts: 30s connecting, 10s disconnecting auto-reset
    - Allow reconnect from stuck Connecting/Connected states (force reset)
    - Remove overly strict Disconnecting guard on disconnect()
    - Cancel timeouts when real status events arrive
    
    Previously, if the app went to background during connect/disconnect,
    EventChannel events could be missed, leaving Dart state stuck in
    Connecting/Disconnecting forever. Now the state auto-recovers on resume.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 81aa868c94952c4c3a705cdb41ae9080fdbefc76
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:52:55 2026 +0400

    fix(03): smart clipboard import — auto-detect URL, link, or base64
    
    - Subscription URLs (http/https) → fetches and imports all servers
    - Single share links (vless://, vmess://, etc.) → imports one server
    - Multi-line or base64 content → parses multiple servers via SubscriptionParser
    - clearSnackBars() before showing new ones so errors don't block FAB
    - Shorter snackbar durations to prevent UI blocking
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 3c68c2fb36d162dbbd9188c9962e407bcc9dd5c0
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:45:13 2026 +0400

    fix(03): use minimal config for MeasureDelay — no geoip/geosite refs
    
    MeasureDelay runs as a standalone Go call without initCoreEnv, so
    geo data files (geoip.dat, geosite.dat) are unavailable. The previous
    code used XrayConfigBuilder.build() which includes routing rules
    referencing geoip:private — causing 'failed to open file: geoip.dat'.
    
    New buildForLatencyTest() generates minimal config:
    - No inbounds (MeasureDelay creates its own internal connection)
    - No routing rules (all traffic goes through the proxy outbound)
    - Only proxy + direct outbounds
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 98aa26cbd5d1a581df3c9382bad06555404d70dc
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:23:39 2026 +0400

    docs(03-06): complete server list UI integration plan

commit 8b4d19604028b4853208c111fc0ad230159d608d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:21:11 2026 +0400

    feat(03-06): wire ServerCard, ServerGroupHeader, ServerListScreen, ImportFab with Phase 3 features
    
    - ServerCard: latency indicator, multi-select checkbox, primaryContainer tint
    - ServerGroupHeader: subscription metadata, collapse toggle, refresh button, data usage/expiry
    - ServerListScreen: sort/filter bar, multi-select appbar, Best Server, Test All, pull-to-refresh, bulk delete
    - ImportFab: functional QR scan, Add Subscription option, 4-option menu

commit 36070cfca66b0eb27ec377e51e81bc150566f96d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:17:07 2026 +0400

    feat(03-06): create multi-select, sort/filter providers and SortFilterBar, LatencyIndicator widgets
    
    - MultiSelectNotifier with enterSelectionMode/toggle/selectAll/clearSelection
    - SortFilterNotifier with SortCriteria and FilterCriteria enums
    - SortFilterBar with sort dropdown and filter chips
    - LatencyIndicator with color-coded latency display and tap-to-retest

commit 78c94402def427c90a380b2c12f541cc4e155dca
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:14:23 2026 +0400

    docs(03-05): complete subscription service, QR scanner & config sharing plan
    
    - SUMMARY.md with 2/2 tasks, threat mitigations, 1 deviation documented
    - STATE.md advanced to plan 6/6, progress 88%
    - ROADMAP.md updated with plan progress
    - CONF-07 marked complete

commit f377e593f9476ebb881f9ce34aa04007d1ce0792
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:12:50 2026 +0400

    feat(03-05): QR scanner screen + QR display dialog + add subscription dialog
    
    - QrScannerScreen: camera scanner with auto-detect (share link vs URL vs unknown)
    - Scan overlay with transparent cutout, flash toggle, camera switch controls
    - QrDisplayDialog: modal bottom sheet with QR code, copy/share actions
    - AddSubscriptionDialog: URL/name/UA/auto-update form with loading state
    - T-03-12: only known URI schemes processed in scanner

commit 811c4314d39b781813889d67eaadd1da224a791a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:11:07 2026 +0400

    feat(03-05): subscription service + provider with auto-refresh on launch
    
    - SubscriptionService: HTTP fetch with custom UA, 15s timeout, 5MB limit
    - SubscriptionNotifier: add/refresh/delete lifecycle with D-13 replace-all
    - D-14 auto-select first server after subscription refresh
    - D-04/CONF-07 auto-refresh on app launch for autoUpdate=true subscriptions
    - ArmaApp converted to ConsumerStatefulWidget for startup hook

commit 329deedcf732db38fa65a6246b04e44d18cb3b0b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:07:29 2026 +0400

    docs(03-04): complete log viewer and export plan
    
    - SUMMARY.md with ring buffer log service and viewer implementation details
    - STATE.md advanced to plan 5/6, progress 81%
    - ROADMAP.md updated with phase 03 progress (4/6 plans)
    - Requirements MON-05 and MON-06 marked complete

commit 768f780690beb4e11b443cf00ba769a6c05eaddd
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:05:57 2026 +0400

    feat(03-04): add LogViewerScreen with filtering, search, auto-scroll, and Settings entry
    
    - Monospace log viewer with color-coded levels (error=red, warning=orange)
    - DropdownButton filter (All/Info/Warning/Error) and search text field
    - Auto-scroll to bottom with manual override on scroll up
    - Export via share_plus share sheet from AppBar action
    - Diagnostics section in Settings with View Logs navigation
    - /logs route registered in GoRouter outside tab shell

commit a04d0b74b13dc1e150fcea5b94499b531108aeba
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 21:04:08 2026 +0400

    feat(03-04): add LogService ring buffer and LogProvider for VPN debug events
    
    - LogService with 5000-line ring buffer, stream broadcasting, and file export via share_plus
    - LogProvider subscribes to VPN EventChannel debug events and provides reactive log lines
    - Ring buffer eviction prevents unbounded memory growth (T-03-11)
    - Export only via user-initiated action (T-03-10)

commit c642fb136f6e6a44d0b14cb0e42a93365ab344b9
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:53:28 2026 +0400

    docs(03-03): complete latency testing and auto-select plan

commit 188cbb2379bed00ef309e3cc8b63a7c0613f2d09
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:24:02 2026 +0400

    feat(03-03): add latency testing, best server selection, and auto-fallback
    
    - Create LatencyNotifier with testServer() and testAllServers() (concurrency 3)
    - Create bestServer reactive provider and selectBestServer pure function
    - Add auto-fallback to ConnectionNotifier on error (D-17, SERV-09)
    - Bounded fallback to 3 consecutive attempts to prevent infinite loops
    - Progressive UI updates during bulk testing via -2 sentinel value

commit 8f5c85f5db374c081717321bfe2f7a22a81490e2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:21:15 2026 +0400

    feat(03-03): add measureDelay to Kotlin MethodChannel + Dart platform service
    
    - Add measureDelay case to MainActivity.kt MethodChannel handler
    - Blocking Go measureOutboundDelay call runs on Dispatchers.IO
    - Result delivered on Dispatchers.Main for MethodChannel.Result safety
    - Add measureDelay() method to VpnPlatformService returning int ms or -1 on failure
    - Handle Go Long → Dart int/num type coercion from platform channel

commit f604e7f5afee71cd39e1f78e71a70233964c7f40
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:19:31 2026 +0400

    docs(03-02): complete subscription body parsers & share link generator plan
    
    - SUMMARY.md with self-check passed
    - STATE.md advanced to plan 3 of 6, 69% progress
    - Requirements CONF-09, CONF-10 marked complete

commit c7aca712052a517bf63e057b6e98892cfd4cb0ce
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:18:05 2026 +0400

    feat(03-02): implement share link generator for all 5 protocols
    
    - ShareLinkGenerator with Dart 3 switch expression dispatch
    - VLESS: UUID@host:port?params with Reality support (pbk, sid, fp, flow, spx)
    - VMess: legacy base64-JSON format for max compatibility
    - Trojan: password@host:port?params with TLS support
    - Shadowsocks: SIP002 base64(method:password)@host:port format
    - Hysteria2: password@host:port with obfs params
    - All 12 tests pass including roundtrip verification for all protocols

commit 3b8bb71a47cf20cead69de782d339d7b9de2d519
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:17:12 2026 +0400

    test(03-02): add failing tests for share link generator
    
    - Tests for all 5 protocols: VLESS, VMess, Trojan, SS, Hysteria2
    - Roundtrip tests: generate → parse for all 5 protocols
    - Edge case: special characters in server name (URI encoding)
    - VMess base64 JSON structure verification

commit 9d329f66836ea6fcbd779f952bd8b9e2212ced8c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:16:25 2026 +0400

    feat(03-02): implement subscription body parsers (base64, SIP008, Clash YAML)
    
    - SubscriptionParser: auto-detects format (SIP008 JSON, Clash YAML, base64, plain text)
    - Sip008Parser: parses both array and wrapped JSON SIP008 formats
    - ClashParser: maps vmess/vless/trojan/ss/hysteria2 with transport opts
    - Base64 padding normalization for missing trailing '=' chars
    - 27 tests passing across all 3 parser test files

commit 2bae12acfd744f5eeac6091c10976ccc977572dc
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:15:16 2026 +0400

    test(03-02): add failing tests for subscription body parsers
    
    - SIP008 parser tests: array, wrapped, invalid JSON, missing fields
    - Clash YAML parser tests: vmess/ws-opts, trojan/tls, unsupported types
    - Subscription parser tests: base64, plain text, delegation, empty body

commit 654c33e8735a79587a1cfff4cb132e5736bae773
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:13:04 2026 +0400

    docs(03-01): complete subscription data foundation plan
    
    - SUMMARY.md with 2 tasks, 30 files, 4min duration
    - STATE.md advanced to plan 2 of 6, progress 63%
    - ROADMAP.md updated with Phase 03 progress
    - Requirements CONF-02, CONF-04, CONF-08, SERV-08 marked complete

commit d452f24801d88b581107560f7cc4b1e411039d3b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:11:31 2026 +0400

    feat(03-01): add Phase 3 l10n keys to all 4 locale ARB files
    
    - Add 46+ l10n keys for subscriptions, QR scanning, sorting, filtering, logs, diagnostics
    - All keys added to en, fa, ru, zh ARB files with proper placeholder metadata
    - Regenerated Dart localization files via flutter gen-l10n

commit 5f33166c3ee4dfabf10407ead124deeaef15ae20
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:09:58 2026 +0400

    feat(03-01): add subscription data layer, dependencies, and CAMERA permission
    
    - Add mobile_scanner, qr_flutter, http, yaml, share_plus, path_provider deps
    - Add kotlinx-coroutines-android to Gradle dependencies
    - Add CAMERA permission and camera feature to AndroidManifest.xml
    - Create Subscription freezed entity with usage info fields
    - Create SubscriptionModel (Hive typeId: 1) with toDomain/fromDomain
    - Create SubscriptionLocalDatasource with CRUD + batch saveAll
    - Create SubscriptionRepository interface and SubscriptionRepositoryImpl
    - Create subscription-userinfo header parser
    - Register SubscriptionModelAdapter and open subscriptions box in main.dart

commit 09632499d93d772cd04acd005d58b610fb48361a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:04:10 2026 +0400

    docs: mark Phase 3 as planned (6 plans, 3 waves)
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 5dbde59498a6306d6a3c1b8b0c8266e82d48be22
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 20:03:23 2026 +0400

    fix(03): revise plans based on checker feedback

commit 39a71824935925f27c649aa62e7afb6f3f6d0ceb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 19:55:17 2026 +0400

    docs(03): create phase plan — 6 plans in 3 waves

commit e7c8a81b8c58577b8a161b180007d7838e34f56e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 19:24:23 2026 +0400

    docs(03): fix UI-SPEC checker issues — copywriting labels, spacing scale, typography

commit a75857d3add91a9e91b964a523ebc76a66313b1c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 18:36:52 2026 +0400

    docs(03): UI design contract

commit d77a827d169f724a70d1c9135f901661b7ba73a0
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 18:31:25 2026 +0400

    docs(03): research phase domain - subscriptions, QR, latency, bulk ops, logs

commit 0f504e5927ad4ebdc8131df2318011f1c9a586f3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 18:21:38 2026 +0400

    docs: add Phase 3 context decisions (subscriptions & server intelligence)
    
    Captures 19 implementation decisions from interactive discuss phase:
    - Subscription formats: base64 + SIP008 + Clash YAML auto-detect
    - QR scanner: mobile_scanner with auto-detect content type
    - Latency: Xray MeasureDelay with 3-5 parallel bulk testing
    - Logs: dual stream+file architecture, 5000-line ring buffer
    - Subscription UX: inline group headers, replace-all on refresh
    - Auto-select: weighted latency+success, manual+fallback triggers
    - Export: share link text + qr_flutter QR code generation
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 2cd5c3d68eb1d65b9d98d08d0a9ff7c6b169fbb7
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 18:04:16 2026 +0400

    chore(gsd): mark Phase 2 complete — VPN engine working
    
    All 5 plans executed, all critical bugs fixed:
    - TUN inbound replacing SOCKS (root cause of no internet)
    - Reconnect race condition (cleanup guard)
    - State sync on app reopen (EventChannel replay)
    - EventChannel conflict (shared broadcast stream)
    - Auto-connect on app open (isVpnActive tracking)
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 69b6862ec8c2842b0adea452008324be4ce0c614
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 17:56:35 2026 +0400

    fix(vpn): sync connection state when app reopens
    
    When the app is closed while VPN is connected, the :vpn_process stays
    alive. On app reopen, the new Flutter instance starts in Disconnected
    state.
    
    Fix uses two sync mechanisms:
    1. EventChannel.onListen replays lastKnownStatus from VpnServiceConnection
       (status received via Messenger before Flutter listener was ready)
    2. ConnectionNotifier queries isRunning after 800ms delay as fallback
    
    Also updated isRunning to check VpnServiceConnection.lastKnownStatus
    in addition to isVpnActive for cross-process state consistency.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit f6dfda038a780159fd1f790e26942a5f37ab7b10
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 17:34:18 2026 +0400

    fix(vpn): add cleanup guard before reconnect to prevent race conditions
    
    The gVisor TCP/IP stack runs goroutines that may not stop instantly when
    coreInstance.Close() is called. On reconnect, the old goroutines could
    interfere with the new TUN + gVisor stack. Added cleanupPreviousSession()
    that always runs before startVpn to ensure:
    1. Old CoreController is fully stopped (with 300ms grace period for goroutines)
    2. Old TUN fd is closed (with 200ms for Android VPN routing cleanup)
    3. Traffic monitor and network callback are properly released
    
    This also handles the case where startVpn is called while still 'running'
    (e.g., rapid tap) — it cleans up first instead of ignoring the request.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 94d4e9793c2a71501aae9a35263973745fdc2712
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 17:28:36 2026 +0400

    fix(vpn): replace stopSelf with stopForeground for reliable reconnect
    
    stopSelf() destroyed the VPN service instance between connect/disconnect
    cycles, causing the gVisor TCP/IP stack and TUN resources to not be
    properly released before the new service instance started. Replaced with
    stopForeground(STOP_FOREGROUND_REMOVE) which just removes the notification
    while keeping the same service instance alive (it's bound from MainActivity
    via BIND_AUTO_CREATE anyway). This enables fast, reliable reconnection.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit f776ade6001fb61f54520cd50562007ea7ef6446
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 17:15:06 2026 +0400

    fix(vpn): replace SOCKS inbound with TUN inbound for traffic routing
    
    ROOT CAUSE: AndroidLibXrayLite's startLoop(config, tunFd) stores the TUN
    fd as env var 'xray.tun.fd' and starts Xray-core with the provided config.
    It does NOT include tun2socks — nothing bridges TUN traffic to the SOCKS
    inbound. Traffic enters TUN but never reaches Xray-core's SOCKS server.
    
    FIX: Use Xray-core's built-in TUN inbound protocol instead of SOCKS.
    The TUN handler (proxy/tun/tun_android.go) reads the fd from the env var,
    creates a gVisor TCP/IP stack, and processes raw IP packets directly.
    This eliminates the need for any external tun2socks binary.
    
    The 'addDisallowedApplication(packageName)' in VPN builder ensures the
    VPN process's own outbound sockets bypass the TUN, preventing loops.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit c3c2c5fe3aab29dee7b4a1abd03509ad4a2b90e2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 16:58:48 2026 +0400

    debug: add comprehensive logging across entire VPN stack
    
    - ArmaVpnService: log every step of start/stop, full config dump,
      onEmitStatus calls, delayed health check with queryStats
    - XrayCoreManager: log init, asset paths, file sizes, version
    - MainActivity: log method channel calls, event forwarding
    - ServiceConnection: log IPC messages, handle MSG_DEBUG_LOG
    - VPN process → Flutter log forwarding via MSG_DEBUG_LOG
    - Dart: print() in ConnectionProvider, VpnPlatformService
    - Xray log level set to 'debug' for maximum core output
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 38118d24b17e393a22d1dfd2906fc02ec795fad6
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 16:50:31 2026 +0400

    fix(vpn): protect outbound sockets from TUN routing loop
    
    ROOT CAUSE: Xray-core's outbound connections to the proxy server were
    being routed back through the TUN interface, creating an infinite loop:
    Xray outbound → socket → TUN → back to Xray → no internet.
    
    The CoreCallbackHandler.onEmitStatus() callback receives socket file
    descriptors from Xray-core when it creates outbound connections.
    We must call VpnService.protect(fd) to exclude these sockets from
    VPN routing so they can reach the internet directly.
    
    This is the same pattern used by V2rayNG and other VPN clients
    based on AndroidLibXrayLite.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 64af07eee169f56365b1fe29e995d33165c70d9c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 16:45:14 2026 +0400

    debug(vpn): add Xray startup logging and info-level config logs
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 7da427d7f4a08b5202ba102db512e4e6db1e9dad
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 16:36:35 2026 +0400

    fix(vpn): add proxy server direct routing to prevent DNS loop
    
    When TUN captures all traffic (0.0.0.0/0), DNS queries for the proxy
    server's hostname (e.g., conn.arma-web.org) go through TUN → Xray →
    proxy outbound → needs to connect to proxy server → needs DNS → loop.
    
    Fix: add the proxy server address as the first routing rule with
    'direct' outbound, so its traffic bypasses the proxy. Handles both
    IP addresses and hostnames.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 04702add4c81da70594ee06e392c501a7f2875df
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 16:20:06 2026 +0400

    fix(vpn): 5 critical connection bugs from device testing
    
    1. EventChannel conflict: multiple receiveBroadcastStream() calls
       overwrote native handler — only last subscriber got events.
       Fix: cache shared broadcast stream in VpnPlatformService.
    
    2. False auto-connect on app open: BIND_AUTO_CREATE made isRunning
       return true (Messenger bound ≠ VPN active). Fix: track actual
       VPN state via isVpnActive flag updated from service events.
    
    3. No error handling in startLoop: Xray-core failures were silent,
       VPN reported 'connected' even when core failed. Fix: try/catch
       with error status and cleanup on failure.
    
    4. Can't disconnect while connecting: button ignored taps during
       Connecting state. Fix: allow disconnect from Connecting state.
    
    5. Messenger registration race: clientMessenger null when service
       sends status. Fix: save lastStatus, send on client registration.
    
    Also: stopVpn now uses both Messenger and Intent for reliability.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 06d0b51e84ec631ea8bd2efeb37200660212d332
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:24:05 2026 +0400

    test(02): persist human verification items as UAT

commit 0e93b8c9ac912c2e5dba36b9381765ab4d1402c1
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:23:48 2026 +0400

    test(02): phase verification - PASSED (5/5 must-haves, 17/17 reqs, human testing needed)

commit 255eae1c605a8824ce03d434c092a9138f5f69b3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:17:50 2026 +0400

    docs(02-05): complete dashboard UI plan - animated connect button, timer & traffic stats
    
    - SUMMARY.md with 2 task commits, 13 files modified
    - STATE.md: plan 5/5 complete, phase 02 ready for verification
    - ROADMAP.md: phase 02 marked complete (5/5 plans)
    - REQUIREMENTS.md: UI-02 marked complete

commit c21f07e769d56e877048b72bb58e336cdcfedc94
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:16:07 2026 +0400

    feat(02-05): TrafficStatsCard + wire DashboardScreen with real providers
    
    - Create TrafficStatsCard with ↓ download / ↑ upload side-by-side cards (D-05)
    - Uses formatSpeed() for human-readable speed formatting
    - Rewrite DashboardScreen with live providers replacing all placeholders
    - Add connection status text with color-coded state display
    - Add ConnectionTimer and TrafficStatsCard to dashboard layout
    - Add l10n keys: connecting, connected (EN/RU/FA/ZH)
    - TrafficStatsPlaceholder no longer imported

commit e5226a961ba9a1e15de28a1bd64677b49f207ef3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:14:11 2026 +0400

    feat(02-05): animated ConnectButton + ConnectionTimer widget
    
    - Add flutter_animate ^4.5.2 dependency
    - Rewrite ConnectButton as ConsumerWidget with 4 visual states (D-03)
    - Grey (disconnected) → pulsing teal shimmer (connecting) → solid teal glow (connected)
    - Tap calls connect/disconnect via ConnectionNotifier
    - Create ConnectionTimer ConsumerStatefulWidget showing HH:MM:SS elapsed time (D-04)
    - Timer starts on Connected state, resets on Disconnected

commit 198302a82a582d92073b084ded581befc2c411da
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:10:58 2026 +0400

    docs(02-04): complete platform channel bridge plan
    
    - SUMMARY.md with 2 task commits, 9 files, self-check passed
    - STATE.md advanced to plan 5 of 5, 80% progress
    - ROADMAP.md updated with plan progress
    - REQUIREMENTS.md: ENG-03, ENG-04, MON-01, MON-02 completed

commit 6513312492407f4d8baf256d1a2f594f9d91490f
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:09:30 2026 +0400

    feat(02-04): Dart connection entities + platform service + Riverpod providers
    
    - ConnectionStatus sealed class: Disconnected/Connecting/Connected/Disconnecting
    - TrafficStats data class with uplinkBytesPerSecond/downlinkBytesPerSecond
    - VpnPlatformService: MethodChannel/EventChannel wrapper for native VPN ops
    - ConnectionNotifier: keepAlive Riverpod provider with connect/disconnect state machine
    - TrafficStatsNotifier: keepAlive Riverpod provider streaming traffic events
    - Generated .g.dart files with connectionProvider and trafficStatsProvider

commit 60820bbdb4d7f0fecf38d86feb7e25f5f0c27a42
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:07:33 2026 +0400

    feat(02-04): IPC ServiceConnection + MainActivity platform channels
    
    - VpnServiceConnection: Messenger-based IPC bridge (sendStart/sendStop/queryIsRunning)
    - MainActivity: MethodChannel (com.arma.vpn/method) with startVpn/stopVpn/isRunning/requestVpnPermission
    - MainActivity: EventChannel (com.arma.vpn/vpn_status) streaming status + traffic stats
    - VPN permission flow via startActivityForResult/onActivityResult
    - Service binding with BIND_AUTO_CREATE on configureFlutterEngine

commit 8a9ac8a5a319d4f053bf4fc3efde2fd1b22b0ecb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:04:44 2026 +0400

    docs(02-03): complete VPN engine plan

commit 74bb99be576d883f6bd0a498e7e7977e983f8a72
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 15:02:53 2026 +0400

    feat(02-03): ArmaVpnService with TUN, lifecycle, shutdown order, network callback
    
    - TUN interface: MTU 9000, IPv4/IPv6 routes, self-exclusion (Pitfall #12)
    - D-09 shutdown order: stopLoop → stopSelf → close TUN fd
    - Foreground notification with status + traffic speeds (D-07)
    - Messenger IPC for cross-process communication
    - ConnectivityManager NetworkCallback with NET_CAPABILITY_NOT_VPN (D-10)
    - StrictMode relaxation for Go runtime init (Pitfall #15)
    - CoreCallbackHandler: onEmitStatus + shutdown + startup callbacks
    - Build verified: flutter build apk --debug passes

commit 794eb54fadee10979a90c7b5448c1f3563a00146
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:59:15 2026 +0400

    feat(02-03): XrayCoreManager + VpnNotificationManager + TrafficMonitor
    
    - XrayCoreManager: Go runtime init with Seq.setContext, geo asset copy, Libv2ray API wrapper
    - VpnNotificationManager: LOW importance channel, persistent notification with status/server/speeds
    - TrafficMonitor: polls QueryStats(proxy, uplink/downlink) every 1 second with callback

commit 835114e1f5f49a72d5718edcb7a82f5207bc3475
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:56:05 2026 +0400

    docs(02-02): complete Xray JSON config builder plan
    
    - SUMMARY.md with 21 passing tests across 6 groups
    - STATE.md updated: plan 3 of 5, 60% progress
    - ROADMAP.md updated: phase 02 progress (2/5 plans)
    - REQUIREMENTS.md: ENG-02, PROTO-01-04, PROTO-06, ROUTE-01, ROUTE-06 complete

commit 30ff6aeb0e8842d508135660f4ffd3b0d97cec8a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:53:53 2026 +0400

    feat(02-02): implement XrayConfigBuilder and formatSpeed utility
    
    - XrayConfigBuilder.build(ServerConfig) produces complete Xray JSON config
    - Handles VLESS, VMess, Trojan, Shadowsocks protocols with correct outbound structure
    - VLESS/VMess use vnext[], Trojan/SS use servers[] (per Xray spec)
    - VLESS flow only set for TCP + TLS/Reality, cleared for WS/gRPC/H2
    - Reality uses realitySettings, TLS uses tlsSettings (never mixed)
    - H2 transport forces TLS security mode
    - Includes stats:{} and policy for QueryStats traffic monitoring
    - Split DNS: Cloudflare 1.1.1.1 for proxied, localhost for local
    - LAN bypass via geoip:private and geosite:private routing rules
    - Three outbounds: proxy, direct (freedom), block (blackhole)
    - formatSpeed converts bytes/sec to B/s, KB/s, MB/s, GB/s tiers

commit 3c5c05095074661c24d7e8745968e59af2bcaacb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:52:33 2026 +0400

    test(02-02): add failing tests for XrayConfigBuilder and formatSpeed
    
    - 15 test cases across 6 groups: VLESS, VMess, Trojan, Shadowsocks, transports, config structure
    - Speed formatter tests for B/s, KB/s, MB/s, GB/s tiers
    - Tests verify protocol-specific outbound structures (vnext vs servers)
    - Tests verify Reality vs TLS settings, flow clearing, H2 TLS forcing
    - Tests verify stats/policy, split DNS, LAN bypass routing presence

commit ab317af154070ac868b084f12fd29b555b5e7865
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:49:53 2026 +0400

    docs(02-01): complete AAR + manifest integration plan
    
    - Create 02-01-SUMMARY.md with execution results
    - Update STATE.md: advance to plan 2/5, 50% progress
    - Update ROADMAP.md: phase 02 plan progress 1/5
    - Update REQUIREMENTS.md: mark ENG-01, ENG-05 complete

commit 843ffc036412285a1dc3267a974039d948fb9dcf
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:48:10 2026 +0400

    feat(02-01): AndroidManifest VPN permissions + service declaration + icon
    
    - Add 6 permissions: INTERNET, ACCESS/CHANGE_NETWORK_STATE, FOREGROUND_SERVICE, FOREGROUND_SERVICE_SPECIAL_USE, POST_NOTIFICATIONS
    - Declare ArmaVpnService in :vpn_process with BIND_VPN_SERVICE + foregroundServiceType=specialUse
    - Add SUPPORTS_ALWAYS_ON and PROPERTY_SPECIAL_USE_FGS_SUBTYPE for Android 14+
    - Create ic_vpn_key.xml Material vector drawable for notification

commit c5b8e14511490b1039b8bf1576ffe565729a206d
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:47:26 2026 +0400

    feat(02-01): integrate Xray-core AAR + geo assets + Gradle config
    
    - Add libv2ray.aar (53MB) from 2dust/AndroidLibXrayLite
    - Add geoip.dat and geosite.dat from Loyalsoldier/v2ray-rules-dat
    - Configure packaging.jniLibs.useLegacyPackaging for Go native libs
    - Add fileTree dependency for libs/*.aar

commit 4c5bd49874017a8ec38b5e2482df8dfc3652c4a2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:32:16 2026 +0400

    phase 2: add plan verification report (PASSED WITH WARNINGS)
    
    5 plans verified across 4 waves, 17/17 requirements covered,
    12/12 decisions honored, all 5 success criteria fully traced.
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit d32923531aa13920eb0ebe36d00f3014c959b233
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:25:49 2026 +0400

    docs(02): create phase 2 plan — VPN engine & core connection (5 plans, 4 waves)

commit 4e6cf20c3a69dcb0d2cd6d12d6cc0a23e70d28b3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 14:06:18 2026 +0400

    docs(02): research VPN engine & core connection phase

commit 40eb36d45cb57e397a9b766a71e33bae58c1e016
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 13:54:14 2026 +0400

    docs(state): record phase 2 context session

commit 8e859897cb085231052c107aeafc2a9513956700
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 13:54:14 2026 +0400

    docs(02): capture phase context

commit 3c622703aeb87a1c7895c08a9ae2d70b5c806c0e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 13:41:19 2026 +0400

    docs(phase-01): mark phase 1 complete, advance to phase 2
    
    Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

commit 12ce462007345eb22fec5a4d72d6779da8b3000f
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 13:41:01 2026 +0400

    docs(01): phase verification passed

commit 24750f5bd811632ccbc28fc381d5bb329836d5eb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 04:12:28 2026 +0400

    fix(01-05): move MainActivity.kt to com.arma.vpn package

commit ed2e59b8e86e9f1c8e49404d919eee9b724722b3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 04:03:48 2026 +0400

    feat(01-05): build import FAB, paste config dialog, and clipboard import flow
    
    - ClipboardHelper utility for reading system clipboard
    - ImportFab with 3 expandable mini-FAB options (QR, Paste Config, Clipboard)
    - Animated FAB icon rotation (45°) and fade/scale sub-options
    - Clipboard import: reads, parses via ShareLinkParser, deduplicates, stores
    - PasteConfigDialog: full-screen multiline TextField with inline validation
    - Both import flows show success/error/duplicate SnackBars
    - Wired empty-state import button to clipboard flow

commit 309f90c7ad81e53de349e44740ceb6321827dfcd
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 04:02:01 2026 +0400

    feat(01-05): build server list screen with cards, badges, grouping, and empty state
    
    - ProtocolBadge widget with protocol-specific colors and semantics
    - ServerCard with tap-to-select, haptic feedback, primary border highlight
    - ServerGroupHeader for subscription/manual grouping
    - EmptyServerState with icon, heading, body, and import button
    - ServerListScreen with AsyncValue handling, grouped list, delete dialog
    - ImportFab placeholder (full implementation in Task 2)

commit 1d74b022c507e80611c1804f719cbbdf08d2253b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:58:50 2026 +0400

    docs(01-03): complete share link parsers plan

commit 37adfe71b7ede514c4295a4bfb34353f840573e6
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:57:01 2026 +0400

    refactor(01-03): extract ParserUtils for shared parsing logic
    
    - New parser_utils.dart: nonEmpty, nonEmptyOr, decodeParam, extractName, isValidHostPort, exceedsMaxLength
    - Removed duplicated private helpers (_nonEmpty, _decodeParam, _maxInputLength) from all 5 parsers
    - Centralized input length constant (10000) and name truncation logic (50 chars)
    - All 60 tests still passing, zero analyzer issues

commit ea9771be909b9d7b47606c64453fa91844b7d81a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:54:50 2026 +0400

    docs(01-04): complete dashboard, settings & routing screens plan
    
    - Add 01-04-SUMMARY.md with execution results
    - Update STATE.md with progress (60%), decisions, metrics
    - Update ROADMAP.md with plan progress
    - Mark requirements UI-01, STOR-02, SERV-02 complete

commit 50b6a162c1ee81105220d33d83826d1f7819bdc2
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:54:40 2026 +0400

    feat(01-03): implement all 5 protocol share link parsers
    
    - ShareLinkParser: dispatcher routing by URI scheme with raw JSON VMess fallback
    - VlessParser: Reality/XTLS-Vision, WebSocket, gRPC transports, non-ASCII names
    - VmessParser: dual format support (legacy base64-JSON + standard URI) per CONF-05
    - TrojanParser: URL-decoded password, default TLS security
    - ShadowsocksParser: base64 method:password, SIP002, method validation per T-01-03-04
    - Hysteria2Parser: hysteria2:// and hy2:// alternate schemes, obfs params
    - All parsers: input length limit (10000), server name cap (50 chars), try-catch null safety
    - 60/60 tests passing, zero analyzer issues

commit b37053ee12feba903323c4ae688664b835fb6829
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:53:12 2026 +0400

    feat(01-04): build settings screen with theme/language controls and routing screen
    
    - Replace settings placeholder with ConsumerWidget using theme SegmentedButton (System/Light/Dark)
    - Add language selector via showModalBottomSheet with 4 languages (EN/FA/RU/ZH)
    - Add About section with version and open source licenses
    - Replace routing placeholder with StatefulWidget containing bypass LAN toggle (default ON)
    - Add routing placeholder card for future custom routing rules
    - All strings localized via AppLocalizations

commit b902a34d044c4e2b072bbd952684de8f79c81b24
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:52:38 2026 +0400

    test(01-03): add failing tests for all 5 protocol share link parsers
    
    - VlessParser: 10 tests (Reality, WebSocket, gRPC, non-ASCII, edge cases)
    - VmessParser: 10 tests (legacy base64-JSON, standard URI, padding, URL-safe base64)
    - TrojanParser: 8 tests (TCP/TLS, WebSocket, URL-encoded password, defaults)
    - ShadowsocksParser: 10 tests (base64 method:password, SIP002, method validation)
    - Hysteria2Parser: 8 tests (hysteria2://, hy2://, obfs params, non-ASCII)
    - ShareLinkParser: 13 tests (dispatch routing, raw JSON, whitespace, invalid input)

commit be596d0f8669560abc9061621a8d8e3574b93ceb
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:52:03 2026 +0400

    feat(01-04): build dashboard screen with connect button, server card, and traffic stats
    
    - Replace dashboard placeholder with ConsumerWidget using localized strings
    - Create 120dp circular connect button (disabled at 50% opacity, snackbar on tap)
    - Create active server card showing protocol badge or 'No server selected'
    - Create static traffic stats placeholder with download/upload speed labels

commit 57bfdbd9007700bce098c70cdafd18919cf04c46
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:48:50 2026 +0400

    docs(01-02): complete domain model, data layer and localization plan
    
    - SUMMARY.md with 3 tasks, 28 files, 4 commits
    - STATE.md: plan 3 of 5, 40% progress
    - ROADMAP.md: phase 01 progress updated
    - REQUIREMENTS.md: STOR-01, STOR-02, UI-03 marked complete

commit ae4abd01e0a7a693873dc4caba0c3fdfb0ed6c62
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:46:17 2026 +0400

    feat(01-02): wire providers, settings persistence, and l10n into app
    
    - SettingsLocalDatasource for theme/locale/active server via SharedPreferences
    - ThemeNotifier and LocaleNotifier providers with persistence
    - ServerListNotifier provider with add/delete server methods
    - ActiveServerNotifier provider tracking selected server
    - Hive initialization and SharedPreferences loading in main.dart
    - AppLocalizations with 4-language support wired into MaterialApp.router
    - flutter analyze clean (zero issues)

commit 11f872d17b80e00e27de6d843441972d5ef9c8e1
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:42:25 2026 +0400

    feat(01-02): implement ServerConfig entity, Hive model, repository and datasource
    
    - Freezed ServerConfig entity with all protocol fields (VLESS/VMess/Trojan/SS/Hysteria2)
    - HiveType(typeId: 0) model with explicit field indices and gaps for schema evolution
    - ServerLocalDatasource wrapping Hive box with error handling
    - ServerRepository abstract interface and impl with data validation (T-01-02-01)
    - Generated freezed, json_serializable, and hive_ce code
    - All 9 TDD tests passing

commit 70267c471d10950c7a7de3fb107c58e6d9ec785c
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:37:52 2026 +0400

    test(01-02): add failing tests for ServerConfig entity and Hive model
    
    - ServerConfig creation, defaults, copyWith, toJson/fromJson round-trip
    - ServerConfigModel toDomain/fromDomain mapping and HiveField index gaps

commit dc4e18dac27fc2dd9066dceebe383e8b19cd5300
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:36:49 2026 +0400

    feat(01-02): add 4-language ARB localization and error class hierarchy
    
    - ARB files for English, Persian (RTL), Russian, Chinese with 40+ UI strings
    - Generated AppLocalizations for all 4 locales via flutter gen-l10n
    - Sealed Failure hierarchy: ParseFailure, StorageFailure, ClipboardFailure
    - ParseException and StorageException for data layer error handling

commit 440e05a514afdea83d531b11ba3454573405f137
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:33:44 2026 +0400

    docs(01-01): complete project foundation plan
    
    - SUMMARY.md with task commits, deviations, decisions
    - STATE.md advanced to plan 2/5, 20% progress
    - ROADMAP.md updated with plan progress
    - REQUIREMENTS.md: UI-01 marked complete

commit c043210bd1a8adfe202c84a08222bbceb77240f5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:31:31 2026 +0400

    feat(01-01): create router, navigation shell, and app entry points
    
    - GoRouter with StatefulShellRoute.indexedStack for 4-tab navigation
    - NavigationShell with Material 3 NavigationBar (Dashboard, Servers, Routing, Settings)
    - Placeholder screens in feature directories for future replacement
    - ArmaApp (ConsumerWidget) with MaterialApp.router, teal theme, system theme mode
    - main.dart with ProviderScope wrapping ArmaApp
    - flutter analyze lib/ reports zero issues

commit da92ceb5e66cba6672f7894051e7f719144969ed
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:30:13 2026 +0400

    feat(01-01): create theme system and constants
    
    - AppTheme with light/dark ThemeData using teal seed color (0xFF00897B)
    - Material 3 card themes with 12dp radius, elevation variants
    - AppColors with 5 protocol badge colors and protocolColor() mapper
    - ProtocolType enum with label, scheme, and fromScheme() factory
    - AppConstants with app name, version, snackbar durations

commit 4d7012cf8772ef6c4c3052bc9967408f09f03dec
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:29:27 2026 +0400

    chore(01-01): install Phase 1 dependencies, configure Android, scaffold directories
    
    - Replace pubspec.yaml with all Phase 1 deps (Riverpod, go_router, Hive CE, freezed, etc.)
    - Remove cupertino_icons, add flutter_localizations and generate: true
    - Create l10n.yaml for flutter gen-l10n support
    - Update analysis_options.yaml with custom_lint plugin
    - Set Android applicationId/namespace to com.arma.vpn, minSdk to 24
    - Create full directory scaffold (core, features, shared)
    - Add minimal app_en.arb for l10n bootstrap
    - Deviation [Rule 3]: Resolved analyzer version conflict by removing explicit custom_lint
      (available transitively via riverpod_lint), downgrading json_serializable/hive_ce_generator

commit 37691e5034f5e24f19e5b74cb6889c963cd5ba49
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:25:47 2026 +0400

    docs(state): begin phase 1 execution

commit 8eefbbc29dd3fba0b30d21d668cff35b3dad1659
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:24:05 2026 +0400

    docs(state): phase 1 planned — 5 plans across 4 waves

commit afe2e96728c3d0991acc58aa2e2752d6ff3d42c6
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:18:08 2026 +0400

    docs(01): create phase plan — 5 plans across 4 waves

commit 3828c038f72268ef921f2e0d4ca6958e2dd8a985
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 03:01:06 2026 +0400

    docs(01): research phase domain — Flutter foundation, share link parsing, hive_ce storage, localization

commit 7b6c90f9355eec7996d9fc13e2a6beddd06af7d5
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:53:03 2026 +0400

    docs(state): record phase 1 UI-SPEC session

commit b707f34bf888dbe12fbbeb0e565449b7ade2bb55
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:49:55 2026 +0400

    docs(01): fix UI-SPEC copywriting, typography, and spacing per checker

commit 132e16e97011cba2298b4ddf02d6a78e21b6896e
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:43:43 2026 +0400

    docs(01): UI design contract

commit e8812d72e8993c63337e3eff831c121e755082cc
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:38:18 2026 +0400

    docs(state): record phase 1 context session

commit a9d3ad35f2695e3a273ea19e0b726f66909f059a
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:38:13 2026 +0400

    docs(01): capture phase context

commit cde1440b928fcdb0e4c279f0fd429681b48ba23b
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:24:03 2026 +0400

    docs: create roadmap (4 phases)

commit e59d330bceb13ff9215e05dc6d91038a89c185e6
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:18:10 2026 +0400

    docs: define v1 requirements

commit 8558ea2d090fa644baa5def64ae27620f8e4cca4
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 02:13:04 2026 +0400

    docs: research proxy/VPN client ecosystem

commit 5492b3f8b32be0505c285688252ad35ef1046fea
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 01:53:06 2026 +0400

    chore: add project config

commit 208c6004f37ed280808335a3bdbeb14ae68f30bf
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 01:49:09 2026 +0400

    docs: initialize project

commit 39dea5ea2f804bb9fb257572bc4a342dbbfa3fe3
Author: Artush Ghazaryan <artush.ghazaryan@softconstruct.com>
Date:   Sun Apr 5 01:38:14 2026 +0400

    docs: map existing codebase
