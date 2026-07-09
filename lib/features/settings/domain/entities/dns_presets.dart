/// DNS service presets with filtering options.
///
/// Provides predefined configurations for popular DNS services:
/// - Finalmask, AdGuard, NextDNS, Cloudflare, OpenDNS, Quad9
/// Each with support for filtering (ad-blocking, malware, adult content)
class DnsPreset {
  final String id;
  final String name;
  final String doH; // DNS over HTTPS URL
  final String doT; // DNS over TLS address:port
  final bool supportsFiltering;
  final String description;

  const DnsPreset({
    required this.id,
    required this.name,
    required this.doH,
    required this.doT,
    required this.supportsFiltering,
    required this.description,
  });
}

/// Collection of DNS presets available in the app
class DnsPresets {
  static const finalmask = DnsPreset(
    id: 'finalmask',
    name: 'Finalmask',
    doH: 'https://finalmask.com/dns-query',
    doT: 'finalmask.com:853',
    supportsFiltering: true,
    description: 'Privacy-focused DNS with filtering',
  );

  static const adguard = DnsPreset(
    id: 'adguard',
    name: 'AdGuard DNS',
    doH: 'https://dns.adguard-dns.com/dns-query',
    doT: 'dns.adguard-dns.com:853',
    supportsFiltering: true,
    description: 'Ad-blocking and malware filtering',
  );

  static const adguardFamily = DnsPreset(
    id: 'adguard-family',
    name: 'AdGuard Family',
    doH: 'https://family.adguard-dns.com/dns-query',
    doT: 'family.adguard-dns.com:853',
    supportsFiltering: true,
    description: 'AdGuard with parental controls',
  );

  static const nextdns = DnsPreset(
    id: 'nextdns',
    name: 'NextDNS',
    doH: 'https://dns.nextdns.io',
    doT: 'dns.nextdns.io:853',
    supportsFiltering: true,
    description: 'Customizable DNS with analytics',
  );

  static const cloudflare = DnsPreset(
    id: 'cloudflare',
    name: 'Cloudflare DNS',
    doH: 'https://1.1.1.1/dns-query',
    doT: '1.1.1.1:853',
    supportsFiltering: false,
    description: 'Fast and reliable DNS',
  );

  static const cloudflareMalware = DnsPreset(
    id: 'cloudflare-malware',
    name: 'Cloudflare (Malware Blocking)',
    doH: 'https://1.1.1.2/dns-query',
    doT: '1.1.1.2:853',
    supportsFiltering: true,
    description: 'Cloudflare with malware filtering',
  );

  static const cloudflareFamily = DnsPreset(
    id: 'cloudflare-family',
    name: 'Cloudflare (Family)',
    doH: 'https://1.1.1.3/dns-query',
    doT: '1.1.1.3:853',
    supportsFiltering: true,
    description: 'Cloudflare with adult content blocking',
  );

  static const opendns = DnsPreset(
    id: 'opendns',
    name: 'OpenDNS',
    doH: 'https://doh.opendns.com/dns-query',
    doT: 'dns.opendns.com:853',
    supportsFiltering: true,
    description: 'Security-focused DNS with filtering',
  );

  static const opendnsFamily = DnsPreset(
    id: 'opendns-family',
    name: 'OpenDNS Family Shield',
    doH: 'https://family.opendns.com/dns-query',
    doT: 'familyshield.opendns.com:853',
    supportsFiltering: true,
    description: 'OpenDNS with family protection',
  );

  static const quad9 = DnsPreset(
    id: 'quad9',
    name: 'Quad9',
    doH: 'https://www.quad9.net/dns-query',
    doT: 'dot.quad9.net:853',
    supportsFiltering: true,
    description: 'Malware and phishing protection',
  );

  static const google = DnsPreset(
    id: 'google',
    name: 'Google DNS',
    doH: 'https://dns.google/dns-query',
    doT: 'dns.google:853',
    supportsFiltering: false,
    description: 'Google Public DNS',
  );

  static const list = [
    finalmask,
    adguard,
    adguardFamily,
    nextdns,
    cloudflare,
    cloudflareMalware,
    cloudflareFamily,
    opendns,
    opendnsFamily,
    quad9,
    google,
  ];

  /// Find preset by ID
  static DnsPreset? findById(String id) {
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// DNS filtering options
class DnsFilteringOptions {
  final bool blockAds;
  final bool blockMalware;
  final bool blockAdultContent;
  final bool blockTrackers;
  final String customBlockList; // Optional custom block list URL

  const DnsFilteringOptions({
    this.blockAds = false,
    this.blockMalware = false,
    this.blockAdultContent = false,
    this.blockTrackers = false,
    this.customBlockList = '',
  });

  DnsFilteringOptions copyWith({
    bool? blockAds,
    bool? blockMalware,
    bool? blockAdultContent,
    bool? blockTrackers,
    String? customBlockList,
  }) => DnsFilteringOptions(
    blockAds: blockAds ?? this.blockAds,
    blockMalware: blockMalware ?? this.blockMalware,
    blockAdultContent: blockAdultContent ?? this.blockAdultContent,
    blockTrackers: blockTrackers ?? this.blockTrackers,
    customBlockList: customBlockList ?? this.customBlockList,
  );
}
