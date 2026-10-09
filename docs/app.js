// ==============================================================================
// OpenSSL Homelab PKI Suite - Interactive Documentation Engine
// ==============================================================================

document.addEventListener('DOMContentLoaded', () => {
  initMobileMenu();
  initCopyButtons();
  initTabSwitchers();
  initPresetSearch();
  initScrollSpy();
  initCommandBuilder();
});

// Mobile Sidebar Drawer Toggle
function initMobileMenu() {
  const toggleBtn = document.getElementById('mobile-toggle-btn');
  const sidebar = document.querySelector('aside.app-sidebar');

  if (toggleBtn && sidebar) {
    toggleBtn.addEventListener('click', () => {
      sidebar.classList.toggle('open');
    });

    // Close on navigation link click on mobile
    document.querySelectorAll('.sidebar-link').forEach(link => {
      link.addEventListener('click', () => {
        if (window.innerWidth <= 900) {
          sidebar.classList.remove('open');
        }
      });
    });
  }
}

// Copy Code to Clipboard with Micro-feedback
function initCopyButtons() {
  document.querySelectorAll('.btn-copy').forEach(btn => {
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

// Multi-Tab Switcher (Nginx, Traefik, Caddy, Apache, HAProxy, Proxmox)
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

// Active Nav Link Spy on Scroll
function initScrollSpy() {
  const navLinks = document.querySelectorAll('.sidebar-link');
  const sections = document.querySelectorAll('section[id]');

  if (!sections.length) return;

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.getAttribute('id');
        navLinks.forEach(link => {
          if (link.getAttribute('href') === `#${id}`) {
            link.classList.add('active');
          } else {
            link.classList.remove('active');
          }
        });
      }
    });
  }, {
    rootMargin: '-20% 0px -70% 0px',
    threshold: 0
  });

  sections.forEach(sec => observer.observe(sec));
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

    if (dns) {
      parts.push(`--dns "${dns}"`);
    }

    if (ip) {
      parts.push(`--ip "${ip}"`);
    }

    if (key && key !== 'rsa3072') {
      parts.push(`--key-type ${key}`);
    }

    if (days && days !== '397' && days !== '') {
      parts.push(`--days ${days}`);
    }

    if (p12) {
      parts.push('--p12');
    }

    outputCode.textContent = parts.join(' ');
  }

  // Event Listeners
  [presetSel, cnInput, dnsInput, ipInput, keySel, daysInput, p12Check].forEach(el => {
    if (el) {
      el.addEventListener('input', updateCommand);
      el.addEventListener('change', updateCommand);
    }
  });

  // Dynamic default presets
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

  // Initial trigger
  updateCommand();
}
