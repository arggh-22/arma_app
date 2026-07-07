# JSON Subscription Specification for ARMA VPN Mobile Application

This document describes the JSON configuration subscription format returned by the server when queried by the Arma mobile application, and outlines integration requirements for the mobile app developer.

---

## 1. General Overview

When querying the subscription link (sub link) with the `format=json` query parameter (or when the JSON format is configured as default for the ARMA client in the admin panel), the server returns an HTTP response with the `Content-Type: application/json; charset=utf-8` header.

The response body is a **JSON array of objects**, where each object represents a fully functional, ready-to-run configuration file for the **Xray** core (or a compatible client).

### Main fields in the configuration object:
1. **`remarks`** (string): User-facing name of the profile/server (e.g., `🔋 Лёгкий (Авто-выбор)`, `🇩🇪 Германия ✅`). This must be displayed in the mobile application UI as the primary connection title.
2. **`meta`** (object): Additional metadata from the server:
   * **`serverDescription`** (string): Subtitle or description badge (e.g., `быстрый⚡`, `VLESS • TCP • REALITY`). It is recommended to render this in the UI in a smaller font below the connection title or as a status badge.
3. **`dns`** (object): DNS server settings.
4. **`inbounds`** (array): Local ports (typically Socks on `10808` and HTTP on `10809` with sniffing enabled) that the mobile app should start on the device to route local traffic (or override them with the application's own VPN tunnel routing).
5. **`outbounds`** (array): List of outbound proxy servers and technical endpoints (including standard `direct` and `block` tags).
6. **`routing`** (object): Traffic routing rules on the client side (defining which domains/IPs go straight via `direct`, which ones are blocked via `block`, and which are sent to the proxy).
7. **`burstObservatory`** (object) *(present only in profiles with auto-balancing enabled)*: Settings for measuring ping latencies to the backend servers.

---

## 2. Application Logic and Handlers

The mobile application must perform the following actions:
1. Fetch the JSON subscription payload via the subscription URL.
2. Deserialize the array of configuration profiles.
3. Present the list of available connections to the user in the UI, using the `remarks` value for titles and `meta.serverDescription` for subtitles/badges.
4. When the user selects a card/connection, pass the entire corresponding Xray config block (the object from the array) directly to the local Xray/Sing-box core to establish the VPN tunnel.
5. **Important (HTTP Headers)**: Along with the JSON payload, the server sends custom HTTP headers that the client application must parse and process:
   - `subscription-userinfo`: Contains a string formatted like `upload=0; download=12345678; total=53687091200; expire=1783353600`. The application must parse `download` (bytes used), `total` (total allowance in bytes), and `expire` (UNIX timestamp of the expiration date) to draw traffic usage progress bars and display expiration dates in the UI.
   - `profile-title`: The profile/brand name encoded in Base64 (e.g., `ARMA VPN`).
   - `profile-update-interval`: The automatic background subscription refresh interval in hours (e.g., `"2"` or `"24"`). The application should schedule periodic background subscription checks based on this value.
   - `profile-update-always`: A boolean flag (`"true"` or `"false"`). If `"true"`, the application must force-update and pull a fresh config from the server every time the user opens the application.
   - `support-url`: The support URL link (e.g., Telegram link to a support bot or manager). Should be opened when the user clicks the "Support" or "Contact Support" button in the app.
   - `profile-web-page-url`: The personal cabinet / web cabinet page URL (e.g., to top up balance or renew the subscription). Should be opened when the user clicks a "Renew Subscription" or "My Cabinet" button.
   - `announce`: Important administrator notice text encoded in Base64. If this header is present in the response, the app must display it as a popup banner to the user.

---

## 3. Example JSON Response from Server

Below is an example of the array structure returned by the server:

```json
[
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "cdn-de.net-infra.systems",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "reality",
          "realitySettings": {
            "serverName": "cdn-de.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "edge",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "proxy-2",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "cdn-au.net-infra.systems",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "reality",
          "realitySettings": {
            "serverName": "cdn-au.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "chrome",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "proxy-3",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "edge-01.cdn-assets-delivery.net",
              "port": 8080,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "none",
          "wsSettings": {
            "path": "/api/v3/updates/websocket",
            "headers": {
              "Host": "edge-01.cdn-assets-delivery.net"
            }
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainMatcher": "hybrid",
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        },
        {
          "type": "field",
          "network": "tcp,udp",
          "balancerTag": "Balancer_2"
        }
      ],
      "balancers": [
        {
          "tag": "Balancer_2",
          "selector": ["proxy"],
          "strategy": {
            "type": "leastPing"
          }
        }
      ]
    },
    "burstObservatory": {
      "pingConfig": {
        "timeout": "3s",
        "interval": "2m",
        "sampling": 2,
        "destination": "http://www.gstatic.com/generate_204",
        "connectivity": ""
      },
      "subjectSelector": ["proxy"]
    },
    "remarks": "🔋 Лёгкий (Авто-выбор)",
    "meta": {
      "serverDescription": "быстрый⚡"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "edge-01.cdn-assets-delivery.net",
              "port": 8080,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "none",
          "wsSettings": {
            "path": "/api/v3/updates/websocket",
            "headers": {
              "Host": "edge-01.cdn-assets-delivery.net"
            }
          }
        }
      },
      {
        "tag": "proxy-2",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "edge-02.cdn-assets-delivery.net",
              "port": 8080,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "none",
          "wsSettings": {
            "path": "/api/v3/updates/websocket",
            "headers": {
              "Host": "edge-02.cdn-assets-delivery.net"
            }
          }
        }
      },
      {
        "tag": "proxy-3",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "static-v1.cdn-assets-delivery.net",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "tls",
          "wsSettings": {
            "path": "/assets/js/chunks/vendor.runtime.min.js",
            "headers": {
              "Host": "static-v1.cdn-assets-delivery.net"
            }
          },
          "tlsSettings": {
            "serverName": "static-v1.cdn-assets-delivery.net",
            "fingerprint": "firefox"
          }
        }
      },
      {
        "tag": "proxy-4",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "77.91.94.218",
              "port": 8080,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "none",
          "wsSettings": {
            "path": "/api/v3/updates/websocket",
            "headers": {
              "Host": "77.91.94.218"
            }
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainMatcher": "hybrid",
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        },
        {
          "type": "field",
          "network": "tcp,udp",
          "balancerTag": "Balancer_3"
        }
      ],
      "balancers": [
        {
          "tag": "Balancer_3",
          "selector": ["proxy"],
          "strategy": {
            "type": "leastPing"
          }
        }
      ]
    },
    "burstObservatory": {
      "pingConfig": {
        "timeout": "3s",
        "interval": "1m",
        "sampling": 2,
        "destination": "http://www.gstatic.com/generate_204",
        "connectivity": ""
      },
      "subjectSelector": ["proxy"]
    },
    "remarks": "🛡️ Обход  (Авто-выбор)",
    "meta": {
      "serverDescription": "Обход блокировки"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "srv-101.net-infra.systems",
              "port": 8443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": ""
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "xhttp",
          "security": "reality",
          "xhttpSettings": {
            "path": "/static-lib-assets",
            "host": "srv-101.net-infra.systems",
            "mode": "auto",
            "scMaxEachPostBytes": 1000000,
            "scMaxConcurrentPosts": 100,
            "scMinPostsIntervalMs": 30,
            "xPaddingBytes": "50-500",
            "noGRPCHeader": false
          },
          "realitySettings": {
            "serverName": "srv-101.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "edge",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "proxy-2",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "srv-110.net-infra.systems",
              "port": 8443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": ""
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "xhttp",
          "security": "reality",
          "xhttpSettings": {
            "path": "/static-lib-assets",
            "host": "srv-110.net-infra.systems",
            "mode": "auto",
            "scMaxEachPostBytes": 1000000,
            "scMaxConcurrentPosts": 100,
            "scMinPostsIntervalMs": 30,
            "xPaddingBytes": "50-500",
            "noGRPCHeader": false
          },
          "realitySettings": {
            "serverName": "srv-110.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "firefox",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainMatcher": "hybrid",
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        },
        {
          "type": "field",
          "network": "tcp,udp",
          "balancerTag": "Balancer_1"
        }
      ],
      "balancers": [
        {
          "tag": "Balancer_1",
          "selector": ["proxy"],
          "strategy": {
            "type": "leastPing"
          }
        }
      ]
    },
    "burstObservatory": {
      "pingConfig": {
        "timeout": "3s",
        "interval": "2m",
        "sampling": 2,
        "destination": "http://www.gstatic.com/generate_204",
        "connectivity": ""
      },
      "subjectSelector": ["proxy"]
    },
    "remarks": "🌐 Устойчивый (Авто-выбор)",
    "meta": {
      "serverDescription": "Авто-выбор"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "77.91.94.218",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": ""
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "xhttp",
          "security": "reality",
          "xhttpSettings": {
            "path": "/static-lib-assets",
            "host": "77.91.94.218",
            "mode": "auto",
            "scMaxEachPostBytes": 1000000,
            "scMaxConcurrentPosts": 100,
            "scMinPostsIntervalMs": 30,
            "xPaddingBytes": "50-500",
            "noGRPCHeader": false
          },
          "realitySettings": {
            "serverName": "gw-01.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "firefox",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "🛡️ Обход блокировок | 2 ✅",
    "meta": {
      "serverDescription": "VLESS • XHTTP • REALITY"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "77.91.94.218",
              "port": 8443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "reality",
          "realitySettings": {
            "serverName": "it-basis.ru",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "firefox",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "🤖 ИИ • Соцсети + GPT ✅",
    "meta": {
      "serverDescription": "VLESS • TCP • REALITY"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "159.195.47.67",
              "port": 7443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": ""
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "xhttp",
          "security": "reality",
          "xhttpSettings": {
            "path": "/static-lib-assets",
            "host": "159.195.47.67",
            "mode": "auto",
            "scMaxEachPostBytes": 1000000,
            "scMaxConcurrentPosts": 100,
            "scMinPostsIntervalMs": 30,
            "xPaddingBytes": "50-500",
            "noGRPCHeader": false
          },
          "realitySettings": {
            "serverName": "gw-01.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "firefox",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "📶 Wi-Fi | Игры | Низкий пинг ✅",
    "meta": {
      "serverDescription": "VLESS • XHTTP • REALITY"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "cdn-de.net-infra.systems",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "reality",
          "realitySettings": {
            "serverName": "cdn-de.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "edge",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "🇩🇪 Германия ✅",
    "meta": {
      "serverDescription": "VLESS • TCP • REALITY"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "cdn-nl.net-infra.systems",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "reality",
          "realitySettings": {
            "serverName": "cdn-nl.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "firefox",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "🇳🇱 Нидерланды ✅",
    "meta": {
      "serverDescription": "VLESS • TCP • REALITY"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "cdn-au.net-infra.systems",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "reality",
          "realitySettings": {
            "serverName": "cdn-au.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "chrome",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "🇦🇹 Австрия ✅",
    "meta": {
      "serverDescription": "VLESS • TCP • REALITY"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "cdn-nl.net-infra.systems",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "none",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "reality",
          "realitySettings": {
            "serverName": "cdn-nl.net-infra.systems",
            "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
            "fingerprint": "edge",
            "shortId": "448dc4dd731f2f16"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "▶️ YouTube без рекламы ✅",
    "meta": {
      "serverDescription": "VLESS • TCP • REALITY"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "edge-01.cdn-assets-delivery.net",
              "port": 8080,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "none",
          "wsSettings": {
            "path": "/api/v3/updates/websocket",
            "headers": {
              "Host": "edge-01.cdn-assets-delivery.net"
            }
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "test",
    "meta": {
      "serverDescription": "VLESS • WS"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "edge-02.cdn-assets-delivery.net",
              "port": 8080,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "none",
          "wsSettings": {
            "path": "/api/v3/updates/websocket",
            "headers": {
              "Host": "edge-02.cdn-assets-delivery.net"
            }
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "test-2",
    "meta": {
      "serverDescription": "VLESS • WS"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "static-v1.cdn-assets-delivery.net",
              "port": 443,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "tls",
          "wsSettings": {
            "path": "/assets/js/chunks/vendor.runtime.min.js",
            "headers": {
              "Host": "static-v1.cdn-assets-delivery.net"
            }
          },
          "tlsSettings": {
            "serverName": "static-v1.cdn-assets-delivery.net",
            "fingerprint": "firefox"
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "test-3",
    "meta": {
      "serverDescription": "VLESS • WS • TLS"
    }
  },
  {
    "dns": {
      "servers": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
      "queryStrategy": "UseIP"
    },
    "inbounds": [
      {
        "tag": "socks",
        "protocol": "socks",
        "port": 10808,
        "listen": "127.0.0.1",
        "settings": {
          "udp": true,
          "auth": "noauth"
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      },
      {
        "tag": "http",
        "protocol": "http",
        "port": 10809,
        "listen": "127.0.0.1",
        "settings": {
          "allowTransparent": false
        },
        "sniffing": {
          "enabled": true,
          "routeOnly": false,
          "destOverride": ["http", "tls", "quic"]
        }
      }
    ],
    "outbounds": [
      {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
          "vnext": [
            {
              "address": "77.91.94.218",
              "port": 8080,
              "users": [
                {
                  "id": "ce05fed6-222f-4368-8a24-62f12ec5b94d",
                  "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
                  "flow": "xtls-rprx-vision"
                }
              ]
            }
          ]
        },
        "streamSettings": {
          "network": "ws",
          "security": "none",
          "wsSettings": {
            "path": "/api/v3/updates/websocket",
            "headers": {
              "Host": "77.91.94.218"
            }
          }
        }
      },
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "block",
        "protocol": "blackhole"
      }
    ],
    "routing": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "outboundTag": "direct",
          "ip": ["geoip:private", "geoip:ru"],
          "domain": ["geosite:category-ru"]
        },
        {
          "type": "field",
          "protocol": ["bittorrent"],
          "outboundTag": "block"
        }
      ]
    },
    "remarks": "test-4",
    "meta": {
      "serverDescription": "VLESS • WS"
    }
  }
]

---

## 4. Special Protocols: Post-Quantum Cryptography and XHTTP

To bypass modern DPI-based censorship and blockades, the subscription includes advanced configurations. The mobile developer must ensure that the integrated **Xray-core** (or Sing-box) build fully supports the following technologies:

### A. Post-Quantum Cryptography: VLESS + WS + VLESSENC (mlkem768)

In some backend servers in the example configuration above, you will notice an unusual `encryption` value:
`"encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc"`

* **What it is**: A hybrid post-quantum key encapsulation mechanism (Kyber/ML-KEM-768 combined with classical X25519) for the VLESS protocol with additional traffic obfuscation and encryption (`VLESSENC`).
* **How to handle on the client**:
  1. The string value of `encryption` must be passed to the Xray core as-is inside the `users` array object of the outbound setting:
     ```json
     "users": [
       {
         "id": "ce05fed6-...",
         "encryption": "mlkem768x25519plus.xorpub.0rtt.Lod-82gub_PgYO0JxUdvEYHAlZtVJxb0u76G0bU02jc",
         "flow": "xtls-rprx-vision"
       }
     ]
     ```
  2. **Core Requirement**: The original/standard Xray-core release does not support the `mlkem*` cryptography family inside the `encryption` field. To prevent core startup crashes (`unknown encryption method`), you must compile and integrate a **custom Xray-core fork that includes Post-Quantum Cryptography (PQ)** support.

### B. Protocol: VLESS + XHTTP + VLESSENC

Some configurations in the list utilize the new `xhttp` transport layer with Reality security:
```json
"streamSettings": {
  "network": "xhttp",
  "security": "reality",
  "xhttpSettings": {
    "path": "/static-lib-assets",
    "host": "srv-101.net-infra.systems",
    "mode": "auto",
    "scMaxEachPostBytes": 1000000,
    "scMaxConcurrentPosts": 100,
    "scMinPostsIntervalMs": 30,
    "xPaddingBytes": "50-500",
    "noGRPCHeader": false
  },
  "realitySettings": {
    "serverName": "srv-101.net-infra.systems",
    "publicKey": "cHQemdkif2o9tH3V4hu5s71p2UZfPv56Vjfo4Xm1Hhc",
    "fingerprint": "edge",
    "shortId": "448dc4dd731f2f16"
  }
}
```

* **What it is**: The `xhttp` (Extensible HTTP) transport is a next-generation DPI evasion technology that mimics standard HTTP POST/GET request patterns. It fragments traffic and obfuscates it as static assets loading (such as images, js bundles, css styles).
* **How to handle on the client**:
  1. The `xhttpSettings` object and its parameters (such as `scMaxEachPostBytes`, `xPaddingBytes`, `mode`, etc.) must be passed to the Xray core precisely as they are formatted in the JSON config array.
  2. **Core Requirement**: Support for the `xhttp` transport was introduced in recent Xray releases (v1.10.0+ / v2.0.0+). The developer must ensure that the Xray-core library embedded in the mobile client is updated to version **1.10.0+** and compiled with `xhttp` enabled.

### Summary of Mobile Client Core Requirements:
> ⚠️ **Critical**: The Arma VPN mobile client must use a compiled binary of **Xray-core** (or Sing-box) that:
> 1. Supports the **`xhttp`** transport protocol (core version >= 1.10.0).
> 2. Is compiled with **Post-Quantum Cryptography** cipher suite (`mlkem768x25519plus`).
