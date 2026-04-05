# Happ Proxy - Full Flutter Clone Specification

## 1. Project Overview
**App Name**: Arma Proxy & Vpn Client
**Primary Target Platforms**: Android (Mobile App) & Web (Promotional/Documentation Site)
**Framework**: Flutter (Dart)
**Core Engine**: Xray-core (via FFI or Android Platform Channels using `VpnService`)
**Architecture Pattern**: Clean Architecture + MVVM
**State Management**: Riverpod (recommended for testability and scalable states)
**Local Storage**: Hive or Isar (for storing configuration strings, routing rules, and subscriptions)

### Objective
To build a fully functional, privacy-first proxy utility mobile application based on the Xray-core, alongside a responsive documentation/download website (cloning the GitBook style of happ.su). The app does NOT provide VPN servers; it strictly acts as a client for user-provided configurations.

---

## 2. Technical Capabilities & Core Functionalities

### 2.1 Supported Protocols
The app must parse, configure, and connect to servers using the following protocols:
- **VLESS** (including Reality and XTLS support)
- **VMess** (V2ray)
- **Trojan**
- **Shadowsocks**
- **Socks / HTTP**
- **Hysteria2**

### 2.2 Core VPN / Proxy Engine (Android)
- **Xray-core Integration**: Implement Android `VpnService` to capture device traffic. Use `tun2socks` and a compiled Android binary (AAR) of Xray-core (e.g., using `libv2ray` or custom Go-Mobile bindings).
- **Traffic Routing**: Implement flexible routing rules (Bypass LAN, Proxy specific domains/IPs, Direct routing).
- **DNS Handling**: Support custom DNS configuration and JSON server DNS blocking.

### 2.3 Subscription & Configuration Management
- **Subscription Links**: Parse base64 encoded subscription URLs.
- **Hidden & Encrypted Subscriptions**: Support encrypted config formats.
- **Addition Methods**: Add via QR Code (camera), Clipboard import, Manual JSON entry, and Subscription URL.
- **User-Agent Customization**: Allow users to set custom User-Agent parameters for fetching subscriptions.

### 2.4 Multi-Selection & Advanced Management
- **Bulk Deletion**: Support long-press to enter multi-selection mode, allowing users to select multiple configurations and delete them simultaneously.
- **Latency Testing**: Real-time ping and TCPing tests for individual nodes or all nodes in a subscription.
- **Traffic Monitoring**: Live upload and download speed calculation.

---

## 3. UI/UX Specifications (Android App)

### 3.1 Design System
- **Theme**: Clean, minimalist UI supporting both Light and Dark modes.
- **Colors**: Deep Blue/Indigo primary color (trust/security), clean white/dark gray background cards.
- **Typography**: System default (Roboto/San Francisco), clean sans-serif.

### 3.2 Screens & Layouts

#### A. Dashboard (Home Screen)
- **Header**: App Logo/Name and Settings Gear Icon.
- **Connection Card**:
    - Large, satisfying Connect/Disconnect toggle switch or circular button.
    - Connection State text: "Disconnected", "Connecting...", "Connected".
- **Traffic Statistics**: Real-time Upload (TX) and Download (RX) speeds (e.g., `↓ 1.2 MB/s  ↑ 45 KB/s`).
- **Active Node Selector**: A prominent card showing the currently selected proxy server. Tapping it opens the bottom sheet or navigates to the Node List.

#### B. Configurations / Nodes Screen
- **List View**: Displays all servers categorized by Subscription Group or Tags.
- **Node Item**: Shows Server Name, Protocol Badge (e.g., `VLESS`, `Trojan`), and Latency (ms).
- **Interactions**:
    - Tap to select as active node.
    - Swipe left to edit.
    - Long press to activate Multi-Select Mode (to bulk delete).
- **FAB (Floating Action Button)**: Expandable FAB with options:
    - 📷 Scan QR Code
    - 📋 Import from Clipboard
    - 🔗 Add Subscription URL
    - ✍️ Manual Configuration

#### C. Routing & Rules Screen
- **Toggles**: Enable/Disable Routing, Bypass LAN, Bypass Mainland (or specific regions).
- **Custom Rules List**: Segmented control for `Proxy`, `Direct`, and `Block`. Users can add domain suffixes (e.g., `domain:example.com`) or IPs (e.g., `geoip:private`).

#### D. Settings Screen
- **General**: Theme toggles, App Language.
- **Xray Settings**: Toggles for Sniffing, Mux (Multiplexing), Fragment handling.
- **Subscription Settings**: Toggle "Auto-update on App Launch".
- **Advanced**: Clear cached stories/logs, Export App Logs.

---

## 4. UI/UX Specifications (Web Site Clone - happ.su)

The website acts as a documentation and distribution hub built with Flutter Web (or deployed as a static HTML/CSS site). It mimics a GitBook layout.

### 4.1 Layout Structure
- **Sidebar (Left)**:
    - Navigation links: Home, Privacy Policy, Terms of Services, FAQ, Developer Documentation, Contacts.
- **Main Content Area (Center/Right)**:
    - **Header**: Language selector (En/Ru), GitHub link.
    - **Hero Section**: App description emphasizing cross-platform support and Xray-core power.
    - **Download Grid**: Clean cards/buttons for iOS, Android (Play Store + APK), Desktop (Windows, macOS, Linux), and TV.
    - **Donations Block**: Crypto and Card payment badges.
    - **Footer**: Copyright info, Company Name, Privacy links, Cookie consent banner.

---

## 5. Development Phases for Claude AI CLI

When prompting the AI, execute the development in these strict phases to ensure stability:

### Phase 1: Project Setup & State Management
- Initialize Flutter project with `riverpod`, `go_router`, and `hive`.
- Set up the UI theme (Light/Dark) and standard component library (buttons, cards, inputs).
- Build the static UI for Dashboard, Node List, and Settings (mocked data).

### Phase 2: Configuration & Subscription Logic
- Implement data models for Xray Configurations (Server, Protocol, Port, UUID, Network type, TLS settings).
- Write parsing logic for standard V2ray/Xray share links (`vless://`, `vmess://`, `trojan://`).
- Implement Hive local storage to save, read, edit, and bulk-delete configurations.

### Phase 3: Android Platform Channels & VpnService
- **Crucial Step**: Create Kotlin platform channels to communicate with an Android native Xray-core wrapper.
- Implement Android `VpnService` to capture traffic.
- Map the Dart configuration models to the Xray JSON structure and pass it to the native engine.

### Phase 4: Utilities & Polish
- Implement Ping / Latency testing logic (HTTP ping to a reliable URL like `gstatic.com/generate_204`).
- Add QR code scanning capability using `mobile_scanner`.
- Implement dynamic traffic tracking (listen to native bytes sent/received and update the Dashboard UI).

### Phase 5: Web Site (Standalone / Router branch)
- If building the website in the same repository, configure routing so that web browsers load the GitBook-style documentation and download links, while mobile devices run the actual proxy app interface.