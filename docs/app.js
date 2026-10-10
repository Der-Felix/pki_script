// ==============================================================================
// OpenSSL Homelab PKI Suite - Modern Documentation Engine
// Bilingual (DE/EN) Auto-detection, OS Detection, Animate.css & TOC Spy
// ==============================================================================

const i18nData = {
  de: {
    // Header & Meta
    pageTitle: "OpenSSL Homelab PKI Suite • Modulare X.509 Infrastruktur",
    searchPlaceholder: "Presets oder Anleitungen durchsuchen...",
    readyBadge: "Bereit",
    starGithub: "Auf GitHub bewerten",
    tocTitle: "Auf dieser Seite",
    langLabel: "Sprache:",

    // Sidebar Headings & Links
    navGettingStarted: "Erste Schritte",
    navProfiles: "Zertifikatsprofile",
    navEnterprise: "Unternehmens-Deployments",
    navOperations: "Betrieb & Sicherheit",
    linkOverview: "Übersicht & Philosophie",
    linkArch: "PKI-Architektur & Sicherheit",
    linkBuilder: "Interaktiver Generator",
    linkQuickstart: "30-Sekunden Schnellstart",
    linkPresets: "12 Produktions-Presets",
    linkSan: "SAN-Pflicht & Standards",
    link8021x: "802.1X EAP-TLS (WLAN / LAN)",
    linkWeb: "Web-Ingress (Nginx / Caddy)",
    linkHypervisors: "Proxmox VE & TrueNAS",
    linkTrust: "Root-Zertifikat importieren",
    linkRevoke: "Widerruf & CRLs",
    linkBackup: "Notfallwiederherstellung",
    linkCron: "Cron & Headless CLI",
    linkUpdates: "Updates & Wartung",
    navStandards: "Standards & Praxis",
    linkRfc: "Warum RFC-Standards?",
    linkTips: "Praxis-Tipps & Tricks",
    linkDiscussions: "GitHub Discussions",
    headerDiscussions: "Discussions",

    // Hero Section
    heroPill: "OpenSSL 3.x Nativ • Strikt nach RFC 5280",
    heroTitle: "Kompromisslose PKI für <span>Homelab & Enterprise</span>",
    heroSub: "Eine dateibasierte Public Key Infrastructure. Konzipiert für isolierte Root CAs, delegierte Zwischenzertifizierungsstellen, Apple/RFC-konforme Zertifikate, 802.1X EAP-TLS und automatisierte CLI-Bereitstellung.",
    badge2Tier: "2-Stufige CA-Hierarchie",
    badgeChain: "Automatische Chain-Bundles",
    badgeP12: "PKCS#12 (.p12) Passwortgeschützt",
    badgeNoDeps: "Keine externen Abhängigkeiten",

    // Section 1: Overview
    secOverviewTitle: "Übersicht & Designphilosophie",
    secOverviewP1: "Viele Homelab-Setups nutzen entweder einzelne selbstsignierte Zertifikate (die ständig ablaufen und überall manuell erneuert werden müssen) oder schwerfällige GUI-Systeme (Vault, Smallstep), die Hintergrunddienste, Datenbanken und unnötige Komplexität erfordern.",
    secOverviewP2: "Diese Suite basiert auf sauberem POSIX/Bash in 17 spezialisierten Bibliotheken unter lib/. Sie nutzt standardisierte Unix-Dateistrukturen, moderne OpenSSL 3.x Kryptografie und erzeugt vollständige Bundles: fullchain.pem, combined.pem, passwortgeschützte cert.p12-Archive sowie schlüsselfertige GUIDE.txt-Anleitungen.",
    calloutWhyFileTitle: "Warum eine dateibasierte PKI?",
    calloutWhyFileP: "Alle Zustände liegen transparent auf der Festplatte. Zertifikate lassen sich mit normalen OpenSSL-Befehlen prüfen, per Git, rsync oder Borg sichern und auf Raspberry Pis, verschlüsselten USB-Sticks oder Linux-Servern völlig ohne Hintergrunddienste betreiben.",

    // Section 2: Architecture
    secArchTitle: "2-Tier CA-Architektur & Sicherheit",
    secArchP1: "In einem sicheren Modell darf die Root CA niemals direkte End-Zertifikate ausstellen. Wird ein Root-CA-Schlüssel kompromittiert, müssen die Vertrauensanker auf jedem einzelnen Gerät, Smartphone, Switch und Server im gesamten Netzwerk manuell gelöscht und neu ausgerollt werden.",
    archRootTitle: "Root CA (Offline / Tresor)",
    archRootMeta: "RSA 4096 • 20 Jahre Gültigkeit • Signiert NUR Intermediates & CRLs",
    archServerTitle: "Server-CA (Ausstellend)",
    archServerMeta: "pathlen:0 • EKU: serverAuth",
    archClientTitle: "Client-CA (Ausstellend)",
    archClientMeta: "pathlen:0 • EKU: clientAuth",
    archLeafWeb: "Web / Ingress",
    archLeafPve: "Proxmox / NAS",
    archLeafVpn: "VPN Gateway",
    archLeaf8021x: "802.1X EAP-TLS",
    archLeafMtls: "mTLS API Peers",
    archLeafSmime: "S/MIME E-Mail",
    archKeyRulesTitle: "Zentrale Sicherheitsregeln",
    archRule1: "1. Pfadlängen-Beschränkung (pathlen:0): Die Intermediate CAs erhalten die X.509-Erweiterung basicConstraints = critical, CA:TRUE, pathlen:0. Dies verhindert kryptografisch, dass Intermediate CAs weitere Unter-CAs erstellen können.",
    archRule2: "2. Rollentrennung via EKU: Server-Zertifikate erhalten strikt serverAuth. Client-Zertifikate erhalten strikt clientAuth. Dadurch kann ein Web-Zertifikat niemals für Client-Zugriffe oder Code-Ausführung missbraucht werden.",
    archRule3: "3. Cold-Storage Sicherheit: Da die Root CA nur alle 10 Jahre die Intermediates signiert, kann ihr privater Schlüssel offline auf verschlüsselten Speichermedien verbleiben. Im Alltag arbeiten nur die Intermediate CAs.",

    // Section 3: Playground
    secBuilderTitle: "Interaktiver Befehlsgenerator",
    secBuilderP: "Wähle deinen Befehlsmodus und passe Parameter an. Der Generator baut den exakten, produktionsreifen CLI-Befehl mit automatischer SAN-Zuweisung und Validierung in Echtzeit:",
    lblBuilderMode: "Befehlsmodus",
    builderModeIssue: "Ausstellen (issue)",
    builderModeQuick: "Schnellstart (quick)",
    builderModeRenew: "Erneuern (renew)",
    builderModeRevoke: "Widerrufen (revoke)",
    builderModeVerify: "Prüfen (verify)",
    builderModeUpdate: "Suite Updaten (update)",
    lblQuickChips: "Schnellauswahl:",
    lblPreset: "Profil / Vorlage",
    lblCn: "Common Name (CN / Host)",
    lblDns: "Subj. Alt DNS (Kommagetrennt)",
    lblIp: "Subj. Alt IPs (Kommagetrennt)",
    lblKey: "Schlüsseltyp",
    lblDays: "Gültigkeit (Tage)",
    lblRevokeReason: "Widerrufsgrund",
    optRevokeKeyCompromise: "keyCompromise (Schlüssel kompromittiert)",
    optRevokeSuperseded: "superseded (Ersetzt durch neues Zertifikat)",
    optRevokeCessation: "cessationOfOperation (Dienst außer Betrieb)",
    optRevokeAffiliation: "affiliationChanged (Subjektangaben geändert)",
    optRevokeUnspecified: "unspecified (Allgemeiner Widerruf)",
    lblP12: "Passwortgeschütztes PKCS#12 Bundle (.p12 für Windows/Apple) erzeugen",
    lblRevokeOld: "Vorheriges Zertifikat automatisch widerrufen (--revoke-old)",
    lblVerifyHost: "Zusätzlich prüfen, ob das Zertifikat zum Hostnamen passt (--host)",
    lblUpdateYes: "Nicht-interaktives Update (-y, ohne manuelle Bestätigung)",
    lblUpdateVersionOnly: "Nur installierte Version & Commit ausgeben (pki.sh version)",
    btnCopy: "Kopieren",
    copiedText: "Kopiert!",
    explainIssue: "Erstellt ein RFC 5280 & CA/B-konformes X.509 Endstellen-Zertifikat. Dateien liegen unter <code>pki/issued/&lt;CN&gt;/</code> inklusive <code>fullchain.pem</code>.",
    explainQuick: "Führt eine automatische Reverse-DNS- und IP-Auflösung für den Host durch und generiert das Zertifikat mit allen erkannten SANs in einem Schritt.",
    explainRenew: "Erneuert ein bestehendes Zertifikat. Kann das alte Zertifikat optional automatisch auf die CRL setzen (<code>--revoke-old</code>).",
    explainRevoke: "Setzt das Zertifikat auf die CRL der zuständigen CA, generiert eine frische <code>crl.pem</code> und verhindert weitere TLS-Verbindungen.",
    explainVerify: "Validiert die kryptografische Kette (Leaf &rarr; Intermediate &rarr; Root), den CRL-Sperrstatus, den Zertifikatszweck und die Übereinstimmung mit dem privaten Schlüssel. Mit <code>--host</code> wird zusätzlich offline geprüft, ob Hostname bzw. IP zu den SANs des Zertifikats passen &ndash; es wird kein Live-TLS-Handshake durchgeführt.",
    explainUpdate: "Führt <code>git pull --ff-only origin main</code> aus. Deine CAs, Schlüssel und Zertifikate in <code>pki/</code> sind strikt getrennt und werden <strong>niemals überschrieben</strong>.",
    explainVersion: "Liest die Versionsnummer der Suite sowie den aktuellen Git-Commit und Branch aus.",

    // Section 4: Quickstart
    secQuickTitle: "30-Sekunden Schnellstart",
    secQuickP: "Root CA, zwei ausstellende Intermediate CAs und dein erstes verifiziertes Zertifikat in unter einer Minute:",
    quickStep1: "1. Repository klonen & System prüfen",
    quickStep2: "2. CA-Hierarchie initialisieren",
    quickStep2P: "Der init-Befehl erstellt die Root CA und beide Intermediate CAs in einem einzigen Durchlauf:",
    quickStep3: "3. Server-Zertifikat mit 1-Klick DNS-Erkennung ausstellen",
    quickStep3P: "Der quick-Befehl ermittelt Host-Aliase und lokale IP-Adressen automatisch über DNS und trägt sie als SAN ein:",
    quickStep4: "4. Kryptografische Kette & Schlüssel überprüfen",

    // Section 5: Presets
    secPresetsTitle: "12 Produktions-Presets",
    secPresetsP: "Jedes Profil erzwingt exakte kryptografische Beschränkungen und RFC-konforme Key-Usages:",

    // Section 6: SAN Rules
    secSanTitle: "Strikte SAN-Pflicht (Warum CommonName tot ist)",
    secSanP1: "Viele ältere Skripte schreiben den Hostnamen nur in das Feld CommonName (CN) und lassen Subject Alternative Names weg. In modernen TLS-Umgebungen führt dies garantiert zu Fehlern.",
    calloutSanTitle: "Zwingende Standards",
    calloutSanP: "Seit Google Chrome 58, Apple iOS 13, macOS Catalina und Go 1.15 wird commonName für die Host-Validierung komplett ignoriert. Jedes Zertifikat MUSS zwingend eine subjectAltName-Erweiterung besitzen.",
    sanRuleDnsIp: "Wichtig: DNS-SAN ≠ IP-SAN! Greifst du über https://192.168.1.10 zu, reicht ein DNS-Name nicht – das Zertifikat muss explizit IP:192.168.1.10 enthalten.",

    // Section 7: 802.1X
    sec8021xTitle: "802.1X EAP-TLS Netzwerk-Authentifizierung (WLAN / LAN)",
    sec8021xP: "EAP-TLS ist der Goldstandard für Firmen-WLANs (WPA2/WPA3-Enterprise) und dynamische Switch-Ports. Passwörter werden eliminiert – die Authentifizierung erfolgt rein kryptografisch zwischen Gerät und RADIUS-Server.",
    eapStep1: "1. FreeRADIUS Server-Zertifikat ausstellen",
    eapStep2: "2. Client-Zertifikate für Geräte & Benutzer ausstellen",
    eapStep3: "3. Bereitstellung auf Endgeräten",

    // Section 8: Web
    secWebTitle: "Web-Ingress & Reverse-Proxy Einbindung",
    secWebP: "Jedes ausgestellte Zertifikat enthält eine automatisch generierte GUIDE.txt mit fertigen Konfigurationsblöcken:",

    // Section 9: Hypervisors
    secHyperTitle: "Proxmox VE & TrueNAS SCALE Einbindung",
    secHyperP: "Ersetze das selbstsignierte Cluster-Zertifikat durch dein offizielles CA-Bündel:",

    // Section 10: Client Trust & OS Detection
    secTrustTitle: "Root CA auf Endgeräten importieren (Einmalig pro Gerät)",
    secTrustP: "Sobald das öffentliche Root-Zertifikat (pki/publish/root.crt) auf deinen Geräten installiert ist, vertrauen Browser, Apps und Befehlszeilentools allen deinen Homelab-Zertifikaten ohne Warnung.",
    osDetectedBanner: "🟢 Erkanntes Betriebssystem:",
    osDetectedPrompt: "Empfohlener 1-Klick Import-Befehl für dein aktuelles System:",

    // Section 11: Revocation
    secRevokeTitle: "Zertifikats-Widerruf & CRL-Listen",
    secRevokeP: "Wurde ein privater Schlüssel kompromittiert oder ein Gerät gestohlen, widerrufe das Zertifikat sofort:",

    // Section 12: Recovery
    secBackupTitle: "Datensicherung & Offline-Lagerung",
    secBackupP: "Da die PKI rein dateibasiert ist, genügt ein verschlüsseltes Archiv zur Sicherung:",

    // Section 13: Cron
    secCronTitle: "Automatisierte nächtliche Zertifikatserneuerung",
    secCronP: "Automatisiere die Erneuerung in Cron-Jobs oder SaltStack-States:",

    // Section 14: RFC Standards
    secRfcTitle: "Warum RFC-Standards? Das X.509 & TLS Fundament",
    secRfcP1: "In der Kryptografie ist globale Einigkeit über Datenformate und Prüfregeln alles. Ohne die Requests for Comments (RFCs) der Internet Engineering Task Force (IETF) gäbe es im Internet keine Interoperabilität. Ein Zertifikat, das auf einem Linux-Server erzeugt wird, muss von Windows Schannel, Apple SecureTransport, Google Chrome, Firefox und curl nach exakt denselben Regeln validiert werden.",
    secRfcWhyTitle: "Warum sind RFCs für dein Homelab unverzichtbar?",
    secRfcWhyP: "Viele selbstgebastelte Skripte erzeugen Zertifikate, die auf den ersten Blick funktionieren, aber modernen Systemen den Dienst verweigern: Fehlende SAN-Felder lösen Sicherheitswarnungen aus, falsche Key-Usage-Bits blockieren den TLS-Handshake und überlange Gültigkeiten führen zu harten Abbrüchen. Diese Suite implementiert RFC-Standards kompromisslos:",
    rfc5280Title: "RFC 5280: Das X.509 & CRL Grundgesetz",
    rfc5280Desc: "Definiert den Aufbau von Version-3-Zertifikaten, Pflichtfelder und standardisierte Erweiterungen wie basicConstraints (CA:TRUE vs. FALSE, pathlen:0), keyUsage und CRL-Verteilungspunkte.",
    rfc2818Title: "RFC 2818: HTTP Over TLS (HTTPS)",
    rfc2818Desc: "Erklärt den CommonName für die Host-Identifizierung im Web für obsolet und schreibt Subject Alternative Names (SAN, DNS: und IP:) zwingend vor.",
    rfc8446Title: "RFC 8446 / 5246: TLS 1.3 & 1.2 Handshake",
    rfc8446Desc: "Regelt den kryptografischen TLS-Handshake. Schreibt vor, dass Server im ServerHello ihre Zwischenzertifikate (fullchain.pem), aber NIEMALS das Root-Zertifikat mitsenden.",
    rfc5216Title: "RFC 5216: EAP-TLS Netzwerk-Authentifizierung",
    rfc5216Desc: "Der Standard für 802.1X (RADIUS / WPA2-Enterprise). Erzwingt strikte Rollentrennung: RADIUS benötigt EKU serverAuth, Endgeräte benötigen EKU clientAuth.",
    rfc8555Title: "RFC 8555: ACME Automatisierung",
    rfc8555Desc: "Das Protokoll hinter Let's Encrypt für automatisierte Zertifikatsausstellung und Challenge-Validierung über HTTP-01 und DNS-01.",
    rfcCabTitle: "CA/Browser Forum Baseline Requirements",
    rfcCabDesc: "Zwingender Industriestandard aller Browserhersteller (Apple, Google, Microsoft): Maximale Gültigkeit von 398 Tagen für Leaf-Zertifikate und SHA-256 Signaturen.",

    // Section 15: Tips & Tricks
    secTipsTitle: "Praxis-Tipps & Tricks für Homelab & Produktion",
    secTipsP: "Erprobte Erfahrungswerte, Kniffe und typische Fallstricke beim Betrieb einer eigenen X.509 Public Key Infrastructure:",
    tip1Title: "Die '10-Jahre CA, 397-Tage Leaf' Regel",
    tip1Body: "Seit September 2020 lehnen Safari, Chrome und iOS Leaf-Zertifikate mit mehr als 398 Tagen Gültigkeit ab. Deine Root & Intermediate CAs dürfen 10–20 Jahre gültig sein – Leaf-Zertifikate immer auf max. 397 Tage ausstellen (<code>--days 397</code>).",
    tip2Title: "Der SAN-Fallstrick: DNS-Name vs. IP-Adresse",
    tip2Body: "Ein Aufruf über <code>https://192.168.1.10</code> schlägt fehl, wenn im Zertifikat nur <code>DNS:web.lan</code> steht! Browser prüfen strikt die Eingabe. Gib bei Servern immer DNS-Namen UND IP-Adressen an: <code>--dns web01.lan --ip 192.168.1.10</code>.",
    tip3Title: "Blitzschnelle Zertifikats-Inspektion im Terminal",
    tip3Body: "Statt lange OpenSSL-Befehle einzutippen, nutze <code>pki.sh inspect cert.crt</code> oder den Shell-Alias: <code>openssl x509 -in cert.crt -noout -text | grep -E 'Subject:|Issuer:|Not After|DNS:|IP:'</code>.",
    tip4Title: "Zero-Downtime Reload für Nginx, Caddy & Traefik",
    tip4Body: "Starte Webserver bei Zertifikatserneuerungen niemals mit <code>restart</code> neu! Nutze <code>systemctl reload nginx</code> oder <code>caddy reload</code>: Bestehende TCP-Verbindungen bleiben offen, neue TLS-Handshakes laden unterbrechungsfrei das neue Zertifikat.",
    tip5Title: "Java Keystore Trust (Unifi Controller, Elasticsearch, Minecraft)",
    tip5Body: "Java-Anwendungen nutzen nicht den OS-Zertifikatsspeicher, sondern den Java Keystore. Importiere die Root CA mit: <code>keytool -import -trustcacerts -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -alias homelab-root -file root.crt</code>.",
    tip6Title: "PKCS#12 (.p12) für 1-Klick-Installation auf Windows & Apple",
    tip6Body: "Mit <code>--p12</code> erzeugt die PKI ein passwortgeschütztes <code>cert.p12</code>-Bundle (Zertifikat + Privatschlüssel + Zwischenzertifikate). Unter Windows und macOS/iOS genügt ein Doppelklick zur sofortigen Installation in den richtigen Speicher.",
    tip7Title: "Git-Sicherheit & Cold-Storage für die Root CA",
    tip7Body: "Versioniere dein <code>pki/</code>-Verzeichnis, aber schließe alle <code>*.key</code>-Dateien in der <code>.gitignore</code> aus. Sichere <code>pki/root-ca/private/root.key</code> auf zwei verschlüsselten USB-Sticks und lösche die Datei vom Live-Server (Cold Storage).",

    // Section 14b: Updates & Maintenance
    secUpdatesTitle: "Updates, Wartung & Sicherheit",
    secUpdatesP: "Die OpenSSL Homelab PKI Suite wird kontinuierlich weiterentwickelt (neue RFC-Standards, OpenSSL 3.x Features und Presets). So hältst du deine Umgebung mühelos aktuell:",
    updatePillar1Title: "1-Befehl CLI Update",
    updatePillar1P: "Mit <code>./pki.sh update</code> aktualisiert sich die Suite via Fast-Forward Git Merge direkt von GitHub.",
    updatePillar2Title: "100% Datensicherheit (pki/ Isolation)",
    updatePillar2P: "Git verwaltet ausschließlich die Skripte in <code>lib/</code>, <code>pki.sh</code> und <code>docs/</code>. Deine privaten Schlüssel, CAs, Seriennummern und Zertifikate in <code>pki/</code> sind in <code>.gitignore</code> geschützt und werden <strong>niemals überschrieben</strong>.",
    updatePillar3Title: "GitHub Release Benachrichtigungen",
    updatePillar3P: "Möchtest du über neue Releases und Sicherheitsupdates per E-Mail oder Push informiert werden? Klicke auf GitHub oben rechts auf <strong>Watch &rarr; Custom &rarr; Releases</strong>.",
    updatePillar4Title: "Headless & Cron-Kompatibel",
    updatePillar4P: "Nutze <code>./pki.sh update -y</code> für automatische Updates ohne interaktive Bestätigung. Mit <code>./pki.sh version</code> kannst du installierte Version und Git-Commit jederzeit einsehen.",
    btnWatchReleases: "GitHub Repository öffnen & beobachten",

    // Section 16: Community & Discussions
    secCommTitle: "Community & GitHub Discussions",
    secCommP: "Hast du Fragen zu deinem Setup, möchtest du deine Homelab-Architektur teilen oder neue Zertifikats-Profile vorschlagen? Nutze das offizielle Forum auf GitHub Discussions:",
    btnJoinDiscussions: "GitHub Discussions öffnen",
    commCard1Title: "💬 Fragen & Antworten (Q&A)",
    commCard1P: "Hilfe bei Fehlern, Client-Trust-Stores oder 802.1X-RADIUS-Konfigurationen.",
    commCard2Title: "💡 Feature-Vorschläge",
    commCard2P: "Schlage neue Profile (z.B. Kubernetes, WireGuard, Cockpit) oder CLI-Flags vor.",
    commCard3Title: "🛠️ Zeige dein Setup",
    commCard3P: "Teile deine Cluster- und Homelab-Topologien mit anderen Enthusiasten.",
    tocDiscussionsTitle: "Homelab Community",
    tocDiscussionsP: "Fragen stellen, Feedback geben oder Setup teilen:",
    tocDiscussionsBtn: "GitHub Discussions",

    // Footer
    footerLeft: "OpenSSL Homelab PKI Suite • Nach RFC 5280 Standards entwickelt",
    footerRight: "GitHub: Der-Felix/pki_script"
  },
  en: {
    // Header & Meta
    pageTitle: "OpenSSL Homelab PKI Suite • Modular X.509 Infrastructure",
    searchPlaceholder: "Search presets or guides...",
    readyBadge: "Ready",
    starGithub: "Star on GitHub",
    tocTitle: "On this page",
    langLabel: "Language:",

    // Sidebar Headings & Links
    navGettingStarted: "Getting Started",
    navProfiles: "Certificate Profiles",
    navEnterprise: "Enterprise Deployments",
    navOperations: "Operations & Security",
    linkOverview: "Overview & Philosophy",
    linkArch: "PKI Architecture & Security",
    linkBuilder: "Interactive Generator",
    linkQuickstart: "30-Second Quickstart",
    linkPresets: "12 Production Presets",
    linkSan: "SAN Rules & Standards",
    link8021x: "802.1X EAP-TLS (Wi-Fi / LAN)",
    linkWeb: "Web Ingress (Nginx / Caddy)",
    linkHypervisors: "Proxmox VE & TrueNAS",
    linkTrust: "Client Trust Stores",
    linkRevoke: "Revocation & CRLs",
    linkBackup: "Disaster Recovery",
    linkCron: "Cron & Headless CLI",
    linkUpdates: "Updates & Maintenance",
    navStandards: "Standards & Best Practices",
    linkRfc: "Why RFC Standards?",
    linkTips: "Tips & Tricks Guide",
    linkDiscussions: "GitHub Discussions",
    headerDiscussions: "Discussions",

    // Hero Section
    heroPill: "OpenSSL 3.x Native • RFC 5280 Strict",
    heroTitle: "Zero-compromise PKI for <span>Homelab & Enterprise</span>",
    heroSub: "A modular, file-based Public Key Infrastructure engine. Designed for air-gapped Root CAs, delegated intermediate authorities, Apple/RFC-compliant leaf certificates, 802.1X EAP-TLS, and automated headless deployment.",
    badge2Tier: "2-Tier CA Hierarchy",
    badgeChain: "Automated Chain Bundles",
    badgeP12: "PKCS#12 (.p12) Protected",
    badgeNoDeps: "Zero External Dependencies",

    // Section 1: Overview
    secOverviewTitle: "Overview & Design Philosophy",
    secOverviewP1: "Most homelab PKI setups either rely on single self-signed certificates (which break constantly and must be manually trusted on every device upon renewal) or heavyweight GUI platforms (Vault, Smallstep) that introduce daemon dependencies, Postgres databases, and resource overhead.",
    secOverviewP2: "This suite is built in clean POSIX/Bash across 17 specialized libraries under lib/. It utilizes standard Unix directory layouts, OpenSSL 3.x modern cryptography, and delivers complete bundles: fullchain.pem, combined.pem, password-protected cert.p12 archives, and auto-generated copy-paste deployment instructions (GUIDE.txt).",
    calloutWhyFileTitle: "Why File-Based PKI?",
    calloutWhyFileP: "All state is stored cleanly on disk. You can audit certificates with plain OpenSSL commands, back up the directory with Git, rsync, restic, or Borg, and run on offline Raspberry Pis, air-gapped flash drives, or cloud instances with zero background services consuming memory.",

    // Section 2: Architecture
    secArchTitle: "Two-Tier CA Architecture & Security",
    secArchP1: "In a production security model, the Root CA must never issue leaf certificates directly. If a Root CA private key is ever exposed, every certificate trust anchor across your laptops, phones, switches, and servers must be manually wiped and replaced.",
    archRootTitle: "Root CA (Offline / Storage)",
    archRootMeta: "RSA 4096 • 20-Year Validity • Signs ONLY Intermediates & CRLs",
    archServerTitle: "Server-CA (Issuing)",
    archServerMeta: "pathlen:0 • EKU: serverAuth",
    archClientTitle: "Client-CA (Issuing)",
    archClientMeta: "pathlen:0 • EKU: clientAuth",
    archLeafWeb: "Web / Ingress",
    archLeafPve: "Proxmox / NAS",
    archLeafVpn: "VPN Gateway",
    archLeaf8021x: "802.1X EAP-TLS",
    archLeafMtls: "mTLS API Peers",
    archLeafSmime: "S/MIME Email",
    archKeyRulesTitle: "Key Architectural Constraints",
    archRule1: "1. Path Length Constraint (pathlen:0): The Intermediate CAs are issued with X.509 extension basicConstraints = critical, CA:TRUE, pathlen:0. This cryptographic rule ensures an intermediate CA can issue end-entity leaf certificates, but cannot issue additional sub-CAs under any circumstances.",
    archRule2: "2. Role Segregation via Extended Key Usage (EKU): Web servers receive strictly serverAuth. Client certificates receive strictly clientAuth. This prevents leaf certificates from being abused across security boundaries.",
    archRule3: "3. Cold-Storage Root Safety: Because the Root CA signs only the Intermediates (every 10 years), the Root CA private key can be kept completely offline (e.g. on an encrypted flash drive or cold disk). Daily certificate operations only touch the Intermediate CAs.",

    // Section 3: Playground
    secBuilderTitle: "Interactive Command Generator",
    secBuilderP: "Select your command mode and adjust parameters. The builder constructs the exact production-ready CLI command with automated SAN assignment and validation in real-time:",
    lblBuilderMode: "Command Mode",
    builderModeIssue: "Issue Certificate",
    builderModeQuick: "Quick 1-Click",
    builderModeRenew: "Renew Certificate",
    builderModeRevoke: "Revoke Certificate",
    builderModeVerify: "Verify Chain",
    builderModeUpdate: "Update Suite",
    lblQuickChips: "Quick Presets:",
    lblPreset: "Preset Profile",
    lblCn: "Common Name (CN / Host)",
    lblDns: "Subject Alt DNS (comma separated)",
    lblIp: "Subject Alt IPs (comma separated)",
    lblKey: "Private Key Type",
    lblDays: "Validity (Days)",
    lblRevokeReason: "Revocation Reason",
    optRevokeKeyCompromise: "keyCompromise (Key suspected compromised)",
    optRevokeSuperseded: "superseded (Replaced by new cert)",
    optRevokeCessation: "cessationOfOperation (Service decommissioned)",
    optRevokeAffiliation: "affiliationChanged (Subject details changed)",
    optRevokeUnspecified: "unspecified (General revocation)",
    lblP12: "Generate encrypted PKCS#12 bundle (.p12 for Windows/iOS/macOS)",
    lblRevokeOld: "Revoke previous certificate automatically (--revoke-old)",
    lblVerifyHost: "Also check that the certificate matches the hostname (--host)",
    lblUpdateYes: "Non-interactive update (-y, bypass manual confirmation)",
    lblUpdateVersionOnly: "Only check installed version and commit (pki.sh version)",
    btnCopy: "Copy",
    copiedText: "Copied!",
    explainIssue: "Issues an RFC 5280 & CA/B Forum compliant end-entity certificate. Files are written to <code>pki/issued/&lt;CN&gt;/</code> including fullchain.pem.",
    explainQuick: "Performs automatic DNS reverse lookup and local IP detection for the specified host, populating all found SANs automatically.",
    explainRenew: "Renews an existing certificate with a fresh validity window while maintaining chain validation. Optionally, the old certificate can be revoked automatically and put on the CRL (<code>--revoke-old</code>).",
    explainRevoke: "Adds the certificate to the intermediate CA's Certificate Revocation List (CRL) and publishes a fresh <code>crl.pem</code>.",
    explainVerify: "Validates the cryptographic signature chain (Leaf &rarr; Intermediate &rarr; Root), CRL revocation status, certificate purpose and private-key match. With <code>--host</code> it additionally checks offline that the hostname or IP matches the certificate's SANs &ndash; no live TLS handshake is performed.",
    explainUpdate: "Runs <code>git pull --ff-only origin main</code>. Your CAs, keys, and issued certs in <code>pki/</code> are strictly isolated and <strong>never overwritten</strong>.",
    explainVersion: "Displays the installed suite version along with Git commit hash and current branch.",

    // Section 4: Quickstart
    secQuickTitle: "30-Second Quickstart",
    secQuickP: "Get a full production-grade Root CA, two issuing intermediate authorities, and your first verified certificate up and running in under a minute:",
    quickStep1: "1. Clone & Check Dependencies",
    quickStep2: "2. Initialize Root CA and Intermediate Authorities",
    quickStep2P: "The init command creates the offline Root CA and both issuing CAs in one single operation:",
    quickStep3: "3. Issue a TLS Server Certificate with 1-Click DNS Discovery",
    quickStep3P: "The quick command automatically performs forward and reverse DNS lookups, resolving all host aliases and local IP addresses into SAN extensions:",
    quickStep4: "4. Verify Cryptographic Integrity",

    // Section 5: Presets
    secPresetsTitle: "12 Production Presets",
    secPresetsP: "Each profile applies strict cryptographic constraints, RFC-compliant extensions, and tailored key usages:",

    // Section 6: SAN Rules
    secSanTitle: "Strict SAN Enforcement (Why CommonName is Dead)",
    secSanP1: "Many legacy scripts still put the hostname in the certificate Subject CommonName (CN) and omit Subject Alternative Names. In modern TLS, this guarantees connection failure.",
    calloutSanTitle: "Mandatory Standards",
    calloutSanP: "Since Google Chrome 58, Apple iOS 13, macOS Catalina, and Go 1.15, the commonName field is completely ignored for hostname validation. A certificate must have an explicit subjectAltName extension.",
    sanRuleDnsIp: "Important: DNS SAN ≠ IP SAN! If you connect to https://192.168.1.10, having a DNS SAN is not enough; the certificate must contain an explicit IP:192.168.1.10 entry.",

    // Section 7: 802.1X
    sec8021xTitle: "802.1X EAP-TLS Network Authentication (Wi-Fi / LAN)",
    sec8021xP: "EAP-TLS is the highest security standard for wireless (WPA2/WPA3-Enterprise) and dynamic switch port admission. Passwords are never used. Instead, authentication relies on mutual cryptographic verification between the user's device and the RADIUS server.",
    eapStep1: "1. Issue the FreeRADIUS Server Certificate",
    eapStep2: "2. Issue User & Device Client Certificates",
    eapStep3: "3. Client Deployment",

    // Section 8: Web
    secWebTitle: "Web Ingress & Reverse Proxy Integration",
    secWebP: "Every issued certificate folder includes auto-generated configuration blocks in GUIDE.txt. Switch tabs below to see tested configuration snippets for all major web servers:",

    // Section 9: Hypervisors
    secHyperTitle: "Proxmox VE & TrueNAS SCALE Deployment",
    secHyperP: "Replace the self-signed cluster certificate with your issued authority bundle:",

    // Section 10: Client Trust & OS Detection
    secTrustTitle: "Importing Root CA into Client Trust Stores (Once per device)",
    secTrustP: "Once you install the public Root CA (pki/publish/root.crt) on your devices, every certificate issued by your Intermediate CAs will be automatically trusted across Chrome, Safari, Edge, curl, and native apps with zero security warnings.",
    osDetectedBanner: "🟢 Detected Operating System:",
    osDetectedPrompt: "Recommended 1-click import command for your current device:",

    // Section 11: Revocation
    secRevokeTitle: "Revocation & Certificate Revocation Lists (CRL)",
    secRevokeP: "If a private key is leaked, a device is stolen, or an employee leaves, revoke the certificate immediately:",

    // Section 12: Recovery
    secBackupTitle: "Disaster Recovery & Air-Gapped Storage",
    secBackupP: "Because the PKI is purely file-based, backup and recovery is as simple as creating an encrypted archive:",

    // Section 13: Cron
    secCronTitle: "Headless Automation & Cron Renewal",
    secCronP: "Automate certificate renewal in cron jobs, Ansible playbooks, or SaltStack states with environment variables:",

    // Section 14: RFC Standards
    secRfcTitle: "Why RFC Standards? The X.509 & TLS Blueprint",
    secRfcP1: "In cryptography, universal consensus on data formats and validation algorithms is non-negotiable. Without Requests for Comments (RFCs) curated by the Internet Engineering Task Force (IETF), secure cross-vendor networking would be impossible. A certificate generated on a Linux host must be validated identically by Windows Schannel, Apple SecureTransport, Google Chrome, Firefox, and curl without ambiguity.",
    secRfcWhyTitle: "Why RFC Standards Matter in Your Homelab",
    secRfcWhyP: "Many ad-hoc scripts create certificates that look functional but fail abruptly against modern operating systems: missing SANs trigger security warnings, improper Key Usage bits prevent TLS handshakes, and excessive validity lengths cause hard rejections. This suite adheres strictly to production RFC standards:",
    rfc5280Title: "RFC 5280: The X.509 & CRL Core Specification",
    rfc5280Desc: "Defines the canonical format of Version 3 certificates, mandatory fields, and extensions including basicConstraints (CA:TRUE vs. FALSE, pathlen:0), keyUsage, and Certificate Revocation Lists (CRLs).",
    rfc2818Title: "RFC 2818: HTTP Over TLS (HTTPS)",
    rfc2818Desc: "Formally deprecated commonName for web identity verification and mandated Subject Alternative Names (SAN, DNS: and IP:) for all HTTPS hosts.",
    rfc8446Title: "RFC 8446 / 5246: TLS 1.3 & 1.2 Handshakes",
    rfc8446Desc: "Governs the cryptographic handshake. Dictates that servers send full intermediate chains (fullchain.pem) in ServerHello, but NEVER transmit the Root CA certificate.",
    rfc5216Title: "RFC 5216: EAP-TLS Network Authentication",
    rfc5216Desc: "The bedrock standard for 802.1X (RADIUS / WPA2-Enterprise). Enforces strict role separation: RADIUS servers require EKU serverAuth; client endpoints require EKU clientAuth.",
    rfc8555Title: "RFC 8555: ACME Automation",
    rfc8555Desc: "The automated certificate management protocol powering Let's Encrypt and Step-CA for zero-touch issuance and HTTP-01 / DNS-01 challenge verification.",
    rfcCabTitle: "CA/Browser Forum Baseline Requirements",
    rfcCabDesc: "The mandatory baseline enforced by all major platform vendors (Apple, Google, Microsoft): maximum 398-day validity for leaf certificates and SHA-256 signatures.",

    // Section 15: Tips & Tricks
    secTipsTitle: "Battle-Tested Tips & Tricks for Homelab & Enterprise",
    secTipsP: "Practical engineering insights, operational shortcuts, and common pitfalls learned from deploying X.509 PKIs:",
    tip1Title: "The '10-Year CA, 397-Day Leaf' Rule",
    tip1Body: "Since September 2020, Apple Safari, Google Chrome, and iOS reject leaf certificates valid for longer than 398 days. Your Root and Intermediate CAs can be valid for 10–20 years, but leaf certificates must always be capped at 397 days (<code>--days 397</code>).",
    tip2Title: "The Common SAN Trap: DNS Name vs. IP Address",
    tip2Body: "Connecting to <code>https://192.168.1.10</code> will trigger a certificate error if the certificate only contains <code>DNS:web.lan</code>! Clients strictly match the address bar input. Always pass both DNS and IP addresses: <code>--dns web01.lan --ip 192.168.1.10</code>.",
    tip3Title: "Instant Certificate Inspection in Terminal",
    tip3Body: "Avoid typing verbose OpenSSL commands. Use <code>pki.sh inspect cert.crt</code> or a quick shell alias: <code>openssl x509 -in cert.crt -noout -text | grep -E 'Subject:|Issuer:|Not After|DNS:|IP:'</code>.",
    tip4Title: "Zero-Downtime Reload for Nginx, Caddy & Traefik",
    tip4Body: "Never use <code>restart</code> when updating certificates on live ingress! Use <code>systemctl reload nginx</code> or <code>caddy reload</code>: existing connections stay open, while new handshakes immediately serve the fresh certificate.",
    tip5Title: "Java Keystore Trust (Unifi Controller, Elasticsearch, Minecraft)",
    tip5Body: "Java applications do not query the operating system certificate store; they rely on their own cacerts keystore. Import your Root CA with: <code>keytool -import -trustcacerts -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -alias homelab-root -file root.crt</code>.",
    tip6Title: "PKCS#12 (.p12) for 1-Click Install on Windows & Apple",
    tip6Body: "Passing <code>--p12</code> packages the leaf certificate, private key, and intermediate chain into an encrypted <code>cert.p12</code> bundle. Double-click the file on Windows or Apple devices and enter the passphrase for instant import into the user store.",
    tip7Title: "Git Security & Cold-Storage for the Root CA",
    tip7Body: "Version control your <code>pki/</code> repository, but keep all <code>*.key</code> files excluded in <code>.gitignore</code>. Back up <code>pki/root-ca/private/root.key</code> to two encrypted USB drives, then remove it from the live server (Cold Storage).",

    // Section 14b: Updates & Maintenance
    secUpdatesTitle: "Updates, Maintenance & Security",
    secUpdatesP: "The OpenSSL Homelab PKI Suite is actively maintained with RFC updates, OpenSSL 3.x security hardening, and new presets. Keep your deployment up-to-date safely:",
    updatePillar1Title: "1-Command CLI Update",
    updatePillar1P: "Running <code>./pki.sh update</code> pulls latest improvements via Fast-Forward Git Merge.",
    updatePillar2Title: "100% Data Safety (pki/ Isolation)",
    updatePillar2P: "Git only tracks bash scripts in <code>lib/</code>, <code>pki.sh</code>, and <code>docs/</code>. Your private keys, Root/Intermediate CAs, serial numbers, and certificates in <code>pki/</code> are strictly isolated and <strong>never touched</strong>.",
    updatePillar3Title: "GitHub Release Notifications",
    updatePillar3P: "To receive email or mobile push alerts when new versions or security advisories are published, click <strong>Watch &rarr; Custom &rarr; Releases</strong> on GitHub.",
    updatePillar4Title: "Headless & Cron-Friendly",
    updatePillar4P: "Use <code>./pki.sh update -y</code> for unattended cron updates without prompts. Run <code>./pki.sh version</code> anytime to inspect current version and commit hash.",
    btnWatchReleases: "Open & Watch Repository on GitHub",

    // Section 16: Community & Discussions
    secCommTitle: "Community & GitHub Discussions",
    secCommP: "Have questions about your setup, want to share your homelab architecture, or propose new certificate presets? Join the official forum on GitHub Discussions:",
    btnJoinDiscussions: "Open GitHub Discussions",
    commCard1Title: "💬 Questions & Answers (Q&A)",
    commCard1P: "Get help with trust store issues, RADIUS configurations, or validation errors.",
    commCard2Title: "💡 Feature Requests",
    commCard2P: "Propose new presets (e.g. Kubernetes, WireGuard, Cockpit) or CLI flags.",
    commCard3Title: "🛠️ Show & Tell",
    commCard3P: "Share your cluster and homelab topologies with other enthusiasts.",
    tocDiscussionsTitle: "Homelab Community",
    tocDiscussionsP: "Ask questions, give feedback, or share your setup:",
    tocDiscussionsBtn: "GitHub Discussions",

    // Footer
    footerLeft: "OpenSSL Homelab PKI Suite • Engineered to RFC 5280 standards",
    footerRight: "GitHub: Der-Felix/pki_script"
  }
};

let currentLang = 'en';

document.addEventListener('DOMContentLoaded', () => {
  initLanguage();
  initOSDetection();
  initScrollAnimations();
  initMobileMenu();
  initCopyButtons();
  initTabSwitchers();
  initPresetSearch();
  initTocScrollSpy();
  initCommandBuilder();
});

// Auto-detect browser/system language with manual toggle override
function initLanguage() {
  const stored = localStorage.getItem('pki_lang');
  if (stored && (stored === 'de' || stored === 'en')) {
    currentLang = stored;
  } else {
    const navLang = (navigator.language || navigator.userLanguage || 'en').toLowerCase();
    currentLang = navLang.startsWith('de') ? 'de' : 'en';
  }

  applyLanguage(currentLang);

  // Setup all language buttons (header and mobile sidebar)
  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const selected = btn.getAttribute('data-lang');
      if (selected) {
        window.setLanguage(selected);
      }
    });
  });
}

window.setLanguage = function(lang) {
  if (!lang || !i18nData[lang]) return;
  currentLang = lang;
  try {
    localStorage.setItem('pki_lang', lang);
  } catch (e) {}
  applyLanguage(lang);
  initOSDetection(); // Re-render OS banner in selected language
};

function applyLanguage(lang) {
  const dict = i18nData[lang] || i18nData.en;

  document.documentElement.lang = lang;

  // Update text nodes
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (dict[key]) {
      el.innerHTML = dict[key];
    }
  });

  // Update placeholders
  document.querySelectorAll('[data-i18n-ph]').forEach(el => {
    const key = el.getAttribute('data-i18n-ph');
    if (dict[key]) {
      el.setAttribute('placeholder', dict[key]);
    }
  });

  // Update language buttons active state across all buttons
  document.querySelectorAll('.lang-btn').forEach(btn => {
    if (btn.getAttribute('data-lang') === lang) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  if (typeof window.updateBuilderCommand === 'function') {
    window.updateBuilderCommand();
  }
}

// Device & Operating System Auto-Detection
function initOSDetection() {
  const ua = navigator.userAgent || '';
  const platform = navigator.platform || '';
  let osName = 'Linux';
  let osKey = 'linux';
  let command = 'sudo cp pki/publish/root.crt /usr/local/share/ca-certificates/homelab-root.crt && sudo update-ca-certificates';
  let osIcon = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect><rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect></svg>`;

  if (/iPad|iPhone|iPod/.test(ua)) {
    osName = 'Apple iOS';
    osKey = 'ios';
    command = '# AirDrop or download root.crt -> Settings -> Profile Downloaded -> General -> About -> Certificate Trust Settings -> Enable Full Trust';
    osIcon = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>`;
  } else if (/Android/.test(ua)) {
    osName = 'Android';
    osKey = 'android';
    command = '# Settings -> Security -> Encryption & credentials -> Install a certificate -> CA certificate -> select root.crt';
    osIcon = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line></svg>`;
  } else if (/Win/.test(platform) || /Windows/.test(ua)) {
    osName = 'Windows';
    osKey = 'windows';
    command = 'Import-Certificate -FilePath .\\pki\\publish\\root.crt -CertStoreLocation Cert:\\LocalMachine\\Root';
    osIcon = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="8" height="8"></rect><rect x="13" y="3" width="8" height="8"></rect><rect x="3" y="13" width="8" height="8"></rect><rect x="13" y="13" width="8" height="8"></rect></svg>`;
  } else if (/Mac/.test(platform) || /Macintosh/.test(ua)) {
    osName = 'macOS';
    osKey = 'macos';
    command = 'sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain pki/publish/root.crt';
    osIcon = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2a10 10 0 1 0 10 10H12V2z"></path></svg>`;
  }

  const container = document.getElementById('os-detected-slot');
  if (!container) return;

  const dict = i18nData[currentLang] || i18nData.en;

  container.innerHTML = `
    <div class="os-detected-card animate__animated animate__fadeIn">
      <div class="os-detected-header">
        <div class="os-detected-title">
          ${osIcon}
          <span>${dict.osDetectedBanner} <strong>${osName}</strong></span>
        </div>
        <span class="meta-chip os-chip">Device Auto-Matched</span>
      </div>
      <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 8px;">${dict.osDetectedPrompt}</p>
      <div class="code-card" style="margin: 0;">
        <div class="code-top">
          <span>${osName} Terminal</span>
          <button class="btn-copy">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
            <span>${dict.btnCopy}</span>
          </button>
        </div>
        <pre><code style="color: #38bdf8;">${command}</code></pre>
      </div>
    </div>
  `;

  // Re-attach copy handler to the dynamic card
  initCopyButtons();
}

// Scroll-Triggered Animation Observer (from animate-css skill)
function initScrollAnimations() {
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const isRtl = document.documentElement.dir === 'rtl' || document.body.dir === 'rtl';

  const rtlFlip = {
    fadeInLeft: 'fadeInRight', fadeInRight: 'fadeInLeft',
    slideInLeft: 'slideInRight', slideInRight: 'slideInLeft',
    backInLeft: 'backInRight', backInRight: 'backInLeft',
    bounceInLeft: 'bounceInRight', bounceInRight: 'bounceInLeft'
  };

  const animElements = document.querySelectorAll('.scroll-animate');

  animElements.forEach(el => {
    const threshold = parseFloat(el.dataset.threshold || 0.12);

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (!entry.isIntersecting) return;

        let anim = el.dataset.animate || 'fadeInUp';
        if (isRtl && rtlFlip[anim]) anim = rtlFlip[anim];

        if (reducedMotion) {
          el.style.opacity = '1';
        } else {
          const delay = parseInt(el.dataset.delay || 0, 10);
          setTimeout(() => {
            el.classList.add('animate__animated', 'animate__' + anim, 'animate__fast');
            el.style.opacity = '1';
          }, delay);
        }

        observer.unobserve(el);
      });
    }, { threshold });

    observer.observe(el);
  });
}

// Mobile Sidebar Drawer Toggle with Backdrop
function initMobileMenu() {
  const toggleBtn = document.getElementById('mobile-toggle-btn');
  const closeBtn = document.getElementById('sidebar-close-btn');
  const sidebar = document.querySelector('aside.app-sidebar');

  function openSidebar() {
    if (!sidebar) return;
    sidebar.classList.add('open');
    toggleBackdrop(true);
  }

  function closeSidebar() {
    if (!sidebar) return;
    sidebar.classList.remove('open');
    toggleBackdrop(false);
  }

  if (toggleBtn && sidebar) {
    toggleBtn.addEventListener('click', (e) => {
      e.preventDefault();
      if (sidebar.classList.contains('open')) {
        closeSidebar();
      } else {
        openSidebar();
      }
    });
  }

  if (closeBtn) {
    closeBtn.addEventListener('click', (e) => {
      e.preventDefault();
      closeSidebar();
    });
  }

  document.querySelectorAll('.sidebar-link').forEach(link => {
    link.addEventListener('click', () => {
      if (window.innerWidth <= 900) {
        closeSidebar();
      }
    });
  });

  function toggleBackdrop(show) {
    let backdrop = document.getElementById('mobile-backdrop');
    if (!backdrop && show) {
      backdrop = document.createElement('div');
      backdrop.id = 'mobile-backdrop';
      backdrop.className = 'mobile-backdrop';
      document.body.appendChild(backdrop);
      backdrop.addEventListener('click', () => {
        closeSidebar();
      });
    }
    if (backdrop) {
      backdrop.style.display = show ? 'block' : 'none';
    }
  }
}

// Copy Code to Clipboard with Micro-feedback
function initCopyButtons() {
  document.querySelectorAll('.btn-copy').forEach(btn => {
    // Avoid double-binding
    if (btn.dataset.hasListener) return;
    btn.dataset.hasListener = 'true';

    btn.addEventListener('click', async () => {
      const parent = btn.closest('.code-card') || btn.closest('.builder-output');
      if (!parent) return;

      const codeElement = parent.querySelector('code');
      if (!codeElement) return;

      const textToCopy = codeElement.innerText.trim();

      try {
        await navigator.clipboard.writeText(textToCopy);
        const originalHtml = btn.innerHTML;
        btn.classList.add('copied');
        btn.innerHTML = `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg> Copied!`;
        
        setTimeout(() => {
          btn.innerHTML = originalHtml;
          btn.classList.remove('copied');
        }, 2200);
      } catch (err) {
        console.error('Failed to copy to clipboard:', err);
      }
    });
  });
}

// Multi-Tab Switcher
function initTabSwitchers() {
  document.querySelectorAll('.tab-container').forEach(container => {
    const buttons = container.querySelectorAll('.tab-btn');
    const panes = container.querySelectorAll('.tab-content');

    buttons.forEach(btn => {
      btn.addEventListener('click', () => {
        const targetId = btn.getAttribute('data-tab');

        buttons.forEach(b => b.classList.remove('active'));
        panes.forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        const activePane = container.querySelector(`#${targetId}`);
        if (activePane) {
          activePane.classList.add('active');
        }
      });
    });
  });
}

// Live Search for Presets
function initPresetSearch() {
  const searchInput = document.getElementById('search-input');
  if (!searchInput) return;

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    const presetBoxes = document.querySelectorAll('.preset-box');

    presetBoxes.forEach(box => {
      const text = box.innerText.toLowerCase();
      if (!query || text.includes(query)) {
        box.style.display = 'flex';
      } else {
        box.style.display = 'none';
      }
    });
  });
}

// Table of Contents & Navigation ScrollSpy
function initTocScrollSpy() {
  const sections = Array.from(document.querySelectorAll('main.app-main section[id]'));
  const allNavLinks = Array.from(document.querySelectorAll('.sidebar-link, .toc-link'));

  if (!sections.length) return;

  function setActive(activeId) {
    if (!activeId) return;
    allNavLinks.forEach(link => {
      const href = link.getAttribute('href');
      if (href === `#${activeId}`) {
        link.classList.add('active');
      } else {
        link.classList.remove('active');
      }
    });
  }

  // Instant active state on click
  allNavLinks.forEach(link => {
    link.addEventListener('click', () => {
      const href = link.getAttribute('href');
      if (href && href.startsWith('#')) {
        const targetId = href.substring(1);
        setActive(targetId);
      }
    });
  });

  function updateActiveSection() {
    const scrollPos = window.scrollY || window.pageYOffset;
    const windowHeight = window.innerHeight;
    const docHeight = document.documentElement.scrollHeight;

    // Check if user is scrolled to the very bottom of the page (within 160px)
    if (scrollPos + windowHeight >= docHeight - 160) {
      const lastSection = sections[sections.length - 1];
      if (lastSection) {
        setActive(lastSection.id);
        return;
      }
    }

    // Offset below fixed header
    const offset = 140;
    let currentId = sections[0].id;

    for (let i = 0; i < sections.length; i++) {
      const sec = sections[i];
      const top = sec.offsetTop;
      if (scrollPos + offset >= top) {
        currentId = sec.id;
      } else {
        break;
      }
    }

    setActive(currentId);
  }

  let ticking = false;
  window.addEventListener('scroll', () => {
    if (!ticking) {
      window.requestAnimationFrame(() => {
        updateActiveSection();
        ticking = false;
      });
      ticking = true;
    }
  }, { passive: true });

  // Initial calculation
  updateActiveSection();
}

// POSIX-safe single-quoting for user-supplied text that ends up in a shell command.
// Inside single quotes nothing is interpreted ($(...), backticks, ", \ ...), so the only
// character that needs handling is the single quote itself: close, escaped quote, reopen.
function shQuote(s) {
  return "'" + String(s).replace(/'/g, "'\\''") + "'";
}

// Command builder defaults. These are the values updateCommand() treats as "not set"
// (so no --key / --days flag is emitted) and what a chip resets the form to.
const BUILDER_DEFAULT_KEY = 'rsa3072';
const BUILDER_DEFAULT_DAYS = '397';

// Preset dropdown auto-fill, keyed by the <option> value. `p12` is optional: presets that
// omit it leave the "PKCS#12" checkbox as the user set it. Presets without an entry
// (server, server-client, vpn-client, codesign) don't touch the fields at all.
const PRESET_FILL = {
  'wildcard':      { cn: '*.homelab.lan',        dns: '*.homelab.lan,homelab.lan', ip: '' },
  'client':        { cn: 'felix-laptop',         dns: '',                          ip: '', p12: true },
  'network-8021x': { cn: 'felix-laptop',         dns: '',                          ip: '', p12: true },
  'radius-server': { cn: 'radius01.homelab.lan', dns: 'radius01.homelab.lan',      ip: '192.168.1.15' },
  'vpn-server':    { cn: 'vpn.homelab.lan',      dns: 'vpn.homelab.lan',           ip: '192.168.1.1' },
  'smime':         { cn: 'Felix S/MIME',         dns: '',                          ip: '', p12: true }
};

// Quick-start chips, keyed by data-chip. Each one also selects the preset and always sets
// the PKCS#12 checkbox. Where a chip matches a dropdown preset it reuses that entry.
const CHIP_PRESETS = {
  'nginx':    { preset: 'server',        cn: 'nginx01.homelab.lan', dns: 'nginx01.homelab.lan,web.homelab.lan', ip: '192.168.1.10', p12: false },
  'wildcard': { preset: 'wildcard',      ...PRESET_FILL['wildcard'], p12: false },
  'client':   { preset: 'client',        ...PRESET_FILL['client'] },
  '8021x':    { preset: 'network-8021x', ...PRESET_FILL['network-8021x'], cn: 'felix-phone' },
  'proxmox':  { preset: 'server',        cn: 'pve01.homelab.lan',   dns: 'pve01.homelab.lan,pve.lan',           ip: '192.168.1.5',  p12: false },
  'radius':   { preset: 'radius-server', ...PRESET_FILL['radius-server'], p12: false }
};

// Interactive CLI Command Playground & Generator (Multi-Mode)
function initCommandBuilder() {
  const modeBar = document.getElementById('builder-mode-bar');
  const chipsBar = document.getElementById('builder-chips-bar');
  const presetSel = document.getElementById('build-preset');
  const cnInput = document.getElementById('build-cn');
  const dnsInput = document.getElementById('build-dns');
  const ipInput = document.getElementById('build-ip');
  const keySel = document.getElementById('build-key');
  const daysInput = document.getElementById('build-days');
  const reasonSel = document.getElementById('build-reason');

  const p12Check = document.getElementById('build-p12');
  const revokeOldCheck = document.getElementById('build-revoke-old');
  const hostCheck = document.getElementById('build-host');
  const updateYesCheck = document.getElementById('build-update-yes');
  const updateVersionCheck = document.getElementById('build-update-version');

  const grpPreset = document.getElementById('grp-preset');
  const grpCn = document.getElementById('grp-cn');
  const grpDns = document.getElementById('grp-dns');
  const grpIp = document.getElementById('grp-ip');
  const grpKey = document.getElementById('grp-key');
  const grpDays = document.getElementById('grp-days');
  const grpReason = document.getElementById('grp-reason');

  const lblChkP12 = document.getElementById('lbl-chk-p12');
  const lblChkRevokeOld = document.getElementById('lbl-chk-revoke-old');
  const lblChkHost = document.getElementById('lbl-chk-host');
  const lblChkUpdateYes = document.getElementById('lbl-chk-update-yes');
  const lblChkUpdateVersion = document.getElementById('lbl-chk-update-version');

  const outputCode = document.getElementById('builder-output-code');
  const explainText = document.getElementById('builder-explain-text');

  if (!outputCode) return;

  let currentMode = 'issue';

  // Single source of truth for what is visible: [element, display value when shown, test(mode)].
  // Input groups are shown with '' (stylesheet default), checkbox labels with 'inline-flex'.
  const SHOW_GROUP = '';
  const SHOW_LABEL = 'inline-flex';
  const inModes = (...modes) => mode => modes.includes(mode);
  const VISIBILITY = [
    [grpPreset,           SHOW_GROUP, inModes('issue')],
    [grpCn,               SHOW_GROUP, mode => mode !== 'update'],
    [grpDns,              SHOW_GROUP, inModes('issue')],
    [grpIp,               SHOW_GROUP, inModes('issue')],
    [grpKey,              SHOW_GROUP, inModes('issue')],
    [grpDays,             SHOW_GROUP, inModes('issue', 'renew')],
    [grpReason,           SHOW_GROUP, inModes('revoke')],
    [lblChkP12,           SHOW_LABEL, inModes('issue', 'quick')],
    [lblChkRevokeOld,     SHOW_LABEL, inModes('renew')],
    [lblChkHost,          SHOW_LABEL, inModes('verify')],
    // "-y" only applies to a real update, not to the "version only" check
    [lblChkUpdateYes,     SHOW_LABEL, mode => mode === 'update' && !!updateVersionCheck && !updateVersionCheck.checked],
    [lblChkUpdateVersion, SHOW_LABEL, inModes('update')]
  ];

  // Derives all show/hide state from currentMode and the current checkbox state.
  function refreshVisibility() {
    VISIBILITY.forEach(([el, shown, isShown]) => {
      if (el) el.style.display = isShown(currentMode) ? shown : 'none';
    });
  }

  function setMode(mode) {
    currentMode = mode;
    if (modeBar) {
      modeBar.querySelectorAll('.builder-mode-btn').forEach(btn => {
        if (btn.getAttribute('data-mode') === mode) {
          btn.classList.add('active');
        } else {
          btn.classList.remove('active');
        }
      });
    }

    refreshVisibility();
    updateCommand();
  }

  // Sets the preset-driven fields. Only keys present in `fill` are applied: `preset` (the
  // dropdown value, chips only) and `p12` are optional, cn/dns/ip are always given.
  function applyFill(fill) {
    if (presetSel && fill.preset !== undefined) presetSel.value = fill.preset;
    if (cnInput) cnInput.value = fill.cn;
    if (dnsInput) dnsInput.value = fill.dns;
    if (ipInput) ipInput.value = fill.ip;
    if (p12Check && fill.p12 !== undefined) p12Check.checked = fill.p12;
  }

  function updateCommand() {
    const dict = i18nData[currentLang] || i18nData.en;
    const cn = (cnInput && cnInput.value.trim()) || 'web01.homelab.lan';

    let parts = ['./pki.sh'];
    let explanationHtml = '';

    if (currentMode === 'issue') {
      const preset = (presetSel && presetSel.value) || 'server';
      const dns = dnsInput ? dnsInput.value.trim() : '';
      const ip = ipInput ? ipInput.value.trim() : '';
      const key = keySel ? keySel.value : BUILDER_DEFAULT_KEY;
      const days = daysInput ? daysInput.value.trim() : BUILDER_DEFAULT_DAYS;
      const p12 = p12Check ? p12Check.checked : false;

      // Every free-text value goes through shQuote(); --days is only emitted when purely numeric.
      parts.push('issue', preset, `--cn ${shQuote(cn)}`);
      if (dns) parts.push(`--dns ${shQuote(dns)}`);
      if (ip) parts.push(`--ip ${shQuote(ip)}`);
      if (key && key !== BUILDER_DEFAULT_KEY) parts.push(`--key ${key}`);
      if (/^\d+$/.test(days) && days !== BUILDER_DEFAULT_DAYS) parts.push(`--days ${days}`);
      if (p12) parts.push('--p12');

      explanationHtml = dict.explainIssue;
    } else if (currentMode === 'quick') {
      const p12 = p12Check ? p12Check.checked : false;
      parts.push('quick', shQuote(cn));
      if (p12) parts.push('--p12');
      explanationHtml = dict.explainQuick;
    } else if (currentMode === 'renew') {
      const days = daysInput ? daysInput.value.trim() : BUILDER_DEFAULT_DAYS;
      const revokeOld = revokeOldCheck ? revokeOldCheck.checked : false;
      parts.push('renew', shQuote(cn));
      if (/^\d+$/.test(days) && days !== BUILDER_DEFAULT_DAYS) parts.push(`--days ${days}`);
      if (revokeOld) parts.push('--revoke-old');
      explanationHtml = dict.explainRenew;
    } else if (currentMode === 'revoke') {
      const reason = (reasonSel && reasonSel.value) || 'keyCompromise';
      parts.push('revoke', shQuote(cn), `--reason ${reason}`);
      explanationHtml = dict.explainRevoke;
    } else if (currentMode === 'verify') {
      // verify_cert: chain + CRL + purpose + key match; --host adds an offline hostname/IP-vs-SAN check
      const checkHost = hostCheck ? hostCheck.checked : false;
      parts.push('verify', shQuote(cn));
      if (checkHost) parts.push(`--host ${shQuote(cn)}`);
      explanationHtml = dict.explainVerify;
    } else if (currentMode === 'update') {
      const isVersionOnly = updateVersionCheck ? updateVersionCheck.checked : false;
      const isYes = updateYesCheck ? updateYesCheck.checked : true;
      if (isVersionOnly) {
        parts.push('version');
        explanationHtml = dict.explainVersion;
      } else {
        parts.push('update');
        if (isYes) parts.push('-y');
        explanationHtml = dict.explainUpdate;
      }
    }

    outputCode.textContent = parts.join(' ');
    if (explainText) {
      explainText.innerHTML = explanationHtml;
    }
  }

  window.updateBuilderCommand = updateCommand;

  // Mode button events
  if (modeBar) {
    modeBar.querySelectorAll('.builder-mode-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const mode = btn.getAttribute('data-mode');
        if (mode) setMode(mode);
      });
    });
  }

  // Preset Chips events
  if (chipsBar) {
    chipsBar.querySelectorAll('.builder-chip-btn').forEach(chip => {
      chip.addEventListener('click', () => {
        const fill = CHIP_PRESETS[chip.getAttribute('data-chip')];
        if (!fill) return;
        applyFill(fill);
        // A chip is a complete starting point: don't let key type / validity left over
        // from a previous mode or manual edit leak into the generated command.
        if (keySel) keySel.value = BUILDER_DEFAULT_KEY;
        if (daysInput) daysInput.value = BUILDER_DEFAULT_DAYS;
        setMode('issue'); // switches to issue mode, refreshes visibility and the command
      });
    });
  }

  // Helper buttons events
  document.querySelectorAll('[data-add-dns]').forEach(btn => {
    btn.addEventListener('click', () => {
      const val = btn.getAttribute('data-add-dns');
      if (dnsInput && val) {
        const cur = dnsInput.value.trim();
        const items = cur ? cur.split(',').map(s => s.trim()) : [];
        if (!items.includes(val)) {
          items.push(val);
          dnsInput.value = items.join(',');
          updateCommand();
        }
      }
    });
  });

  document.querySelectorAll('[data-add-ip]').forEach(btn => {
    btn.addEventListener('click', () => {
      const val = btn.getAttribute('data-add-ip');
      if (ipInput && val) {
        const cur = ipInput.value.trim();
        const items = cur ? cur.split(',').map(s => s.trim()) : [];
        if (!items.includes(val)) {
          items.push(val);
          ipInput.value = items.join(',');
          updateCommand();
        }
      }
    });
  });

  // Input listeners
  // (presetSel is not in this list: its dedicated handler below fills the fields first and
  // then updates the command, so listening here too would only render the stale state.)
  const allInputs = [
    cnInput, dnsInput, ipInput, keySel, daysInput,
    reasonSel, p12Check, revokeOldCheck,
    hostCheck, updateYesCheck, updateVersionCheck
  ];
  allInputs.forEach(el => {
    if (el) {
      el.addEventListener('input', updateCommand);
      el.addEventListener('change', () => {
        refreshVisibility(); // "version only" hides the -y checkbox
        updateCommand();
      });
    }
  });

  // Preset dropdown auto-fill
  if (presetSel) {
    presetSel.addEventListener('change', () => {
      const fill = PRESET_FILL[presetSel.value];
      if (fill) applyFill(fill);
      updateCommand();
    });
  }

  // Initial call
  setMode('issue');
}
