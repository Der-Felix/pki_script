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
    secBuilderP: "Wähle dein Profil und gib Hostnamen oder IPs ein. Der Generator baut den exakten, produktionsreifen CLI-Befehl mit automatischer SAN-Zuweisung in Echtzeit:",
    lblPreset: "Profil / Vorlage",
    lblCn: "Common Name (CN)",
    lblDns: "Subj. Alt DNS (Kommagetrennt)",
    lblIp: "Subj. Alt IPs (Kommagetrennt)",
    lblKey: "Schlüsseltyp",
    lblDays: "Gültigkeit (Tage)",
    lblP12: "Passwortgeschütztes PKCS#12 Bundle (.p12 für Windows/Apple) erzeugen",
    btnCopy: "Kopieren",
    copiedText: "Kopiert!",

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
    secBuilderP: "Select your deployment profile and input your parameters. The builder constructs the exact production-ready CLI command with automated SAN parsing:",
    lblPreset: "Preset Profile",
    lblCn: "Common Name (CN)",
    lblDns: "Subject Alt DNS (comma separated)",
    lblIp: "Subject Alt IPs (comma separated)",
    lblKey: "Private Key Type",
    lblDays: "Validity (Days)",
    lblP12: "Generate encrypted PKCS#12 bundle (.p12 for Windows/iOS/macOS)",
    btnCopy: "Copy",
    copiedText: "Copied!",

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

// Interactive CLI Command Playground & Generator
function initCommandBuilder() {
  const presetSel = document.getElementById('build-preset');
  const cnInput = document.getElementById('build-cn');
  const dnsInput = document.getElementById('build-dns');
  const ipInput = document.getElementById('build-ip');
  const keySel = document.getElementById('build-key');
  const daysInput = document.getElementById('build-days');
  const p12Check = document.getElementById('build-p12');
  const outputCode = document.getElementById('builder-output-code');

  if (!presetSel || !outputCode) return;

  function updateCommand() {
    const preset = presetSel.value || 'server';
    const cn = (cnInput && cnInput.value.trim()) || 'web01.homelab.lan';
    const dns = dnsInput ? dnsInput.value.trim() : '';
    const ip = ipInput ? ipInput.value.trim() : '';
    const key = keySel ? keySel.value : 'rsa3072';
    const days = daysInput ? daysInput.value.trim() : '397';
    const p12 = p12Check ? p12Check.checked : false;

    let parts = ['./pki.sh', 'issue', preset, `--cn "${cn}"`];

    if (dns) parts.push(`--dns "${dns}"`);
    if (ip) parts.push(`--ip "${ip}"`);
    if (key && key !== 'rsa3072') parts.push(`--key-type ${key}`);
    if (days && days !== '397' && days !== '') parts.push(`--days ${days}`);
    if (p12) parts.push('--p12');

    outputCode.textContent = parts.join(' ');
  }

  [presetSel, cnInput, dnsInput, ipInput, keySel, daysInput, p12Check].forEach(el => {
    if (el) {
      el.addEventListener('input', updateCommand);
      el.addEventListener('change', updateCommand);
    }
  });

  presetSel.addEventListener('change', () => {
    const val = presetSel.value;
    if (val === 'wildcard') {
      if (cnInput) cnInput.value = '*.homelab.lan';
      if (dnsInput) dnsInput.value = '*.homelab.lan,homelab.lan';
      if (ipInput) ipInput.value = '';
    } else if (val === 'client' || val === 'network-8021x') {
      if (cnInput) cnInput.value = 'felix-laptop';
      if (dnsInput) dnsInput.value = '';
      if (ipInput) ipInput.value = '';
      if (p12Check) p12Check.checked = true;
    } else if (val === 'radius-server') {
      if (cnInput) cnInput.value = 'radius01.homelab.lan';
      if (dnsInput) dnsInput.value = 'radius01.homelab.lan';
      if (ipInput) ipInput.value = '192.168.1.15';
    } else if (val === 'vpn-server') {
      if (cnInput) cnInput.value = 'vpn.homelab.lan';
      if (dnsInput) dnsInput.value = 'vpn.homelab.lan';
      if (ipInput) ipInput.value = '192.168.1.1';
    } else if (val === 'smime') {
      if (cnInput) cnInput.value = 'Felix S/MIME';
      if (dnsInput) dnsInput.value = '';
      if (ipInput) ipInput.value = '';
      if (p12Check) p12Check.checked = true;
    }
    updateCommand();
  });

  updateCommand();
}
