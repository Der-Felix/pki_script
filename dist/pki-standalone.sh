#!/usr/bin/env bash
###############################################################################
# pki-standalone.sh - OpenSSL PKI Suite (Compiled Standalone Script)
# Automatically compiled from modular library modules via build.sh
###############################################################################
umask 077
set -o errexit -o pipefail -o errtrace

SCRIPT_NAME=$(basename "$0")
SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)/$SCRIPT_NAME


###############################################################################
# MODULE: lib/core.sh
###############################################################################
###############################################################################
# lib/core.sh - Core utilities, logging, formatting, and validation helpers
###############################################################################

VERSION="1.1.0"
HR="##############################################################################"
DIVIDER="──────────────────────────────────────────────────────────────────────────────"

# Global runtime variables
PKI_DIR="${PKI_DIR:-$PWD/pki}"
ASSUME_YES=0
INTERACTIVE=0
I_NO_CSR_SAN=0
R_REVOKE_OLD=0
B_FORCE=0
PASSIN=()
KPASSIN=()
SPLIT=()
PARTIAL_DIR=""
STEP_N=0
STEP_TOTAL=0

###############################################################################
# Colors and Output Helpers
###############################################################################
setup_colors() {
    if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
        C_RED=$'\033[31m'
        C_GRN=$'\033[32m'
        C_YEL=$'\033[33m'
        C_BLU=$'\033[34m'
        C_MAG=$'\033[35m'
        C_CYN=$'\033[36m'
        C_BLD=$'\033[1m'
        C_DIM=$'\033[2m'
        C_RST=$'\033[0m'
    else
        C_RED="" C_GRN="" C_YEL="" C_BLU="" C_MAG="" C_CYN="" C_BLD="" C_DIM="" C_RST=""
    fi
}
setup_colors

info()    { printf '%s[INFO]%s  %s\n'   "$C_BLU" "$C_RST" "$*" >&2; }
ok()      { printf '%s[ OK ]%s  %s\n'   "$C_GRN" "$C_RST" "$*" >&2; }
warn()    { printf '%s[WARN]%s  %s\n'   "$C_YEL" "$C_RST" "$*" >&2; }
err()     { printf '%s[ERROR]%s %s\n'   "$C_RED" "$C_RST" "$*" >&2; }
die()     { err "$*"; exit 1; }

step()    { STEP_N=$((STEP_N+1)); printf '%s[%d/%d]%s %s\n' "$C_GRN" "$STEP_N" "$STEP_TOTAL" "$C_RST" "$*" >&2; }
kv()      { printf '  %-16s %s\n' "$1:" "$2" >&2; }

banner() {
    printf '\n%s%s\n# %s\n%s%s\n' "$C_BLD" "$HR" "$1" "$HR" "$C_RST" >&2
}

section() {
    printf '\n%s######## %s%s\n' "$C_BLD" "$1" "$C_RST" >&2
}

divider() {
    printf '%s%s%s\n' "$C_DIM" "$DIVIDER" "$C_RST" >&2
}

###############################################################################
# String and Date Helpers
###############################################################################
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }
trim()  { local s=$1; s=${s#"${s%%[![:space:]]*}"}; s=${s%"${s##*[![:space:]]}"}; printf '%s' "$s"; }
now()   { date '+%Y-%m-%d %H:%M:%S'; }
stamp() { date '+%Y%m%d-%H%M%S'; }

# "YYYY-MM-DD HH:MM:SS" (UTC) -> Epoch (supports both GNU date and BSD/macOS date)
to_epoch() {
    date -u -d "$1" +%s 2>/dev/null || date -u -j -f "%Y-%m-%d %H:%M:%S" "$1" +%s 2>/dev/null
}

# Split delimited list "a, b c;d" -> Array SPLIT=(a b c d)
split_list() {
    SPLIT=()
    local IFS=$' \t,;'
    read -r -a SPLIT <<< "$1" || true
}

# Append element to comma-separated list if not already present
add_uniq() {
    local list=$1 item=$2
    case ",$list," in *",$item,"*) printf '%s' "$list"; return;; esac
    if [ -z "$list" ]; then printf '%s' "$item"; else printf '%s,%s' "$list" "$item"; fi
}

###############################################################################
# Validation Helpers
###############################################################################
is_int() { case $1 in ''|*[!0-9]*) return 1;; *) return 0;; esac; }

is_ipv4() {
    local re='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$' i
    [[ $1 =~ $re ]] || return 1
    for i in 1 2 3 4; do [ "${BASH_REMATCH[$i]}" -le 255 ] || return 1; done
}

is_ipv6() {
    local re='^[0-9a-fA-F:.]*:[0-9a-fA-F:.]*$'
    [[ $1 =~ $re ]] && [[ $1 == *:*:* ]]
}

is_hostname() {
    local l='[a-z0-9_]([a-z0-9_-]{0,61}[a-z0-9_])?'
    local re="^(\*\.)?${l}(\.${l})*$"
    [[ $1 =~ $re ]]
}

is_email() { local re='^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'; [[ $1 =~ $re ]]; }
is_uri()   { local re='^[a-zA-Z][a-zA-Z0-9+.-]*:[^[:space:]]+$'; [[ $1 =~ $re ]]; }
is_name()  { local re='^[a-z0-9][a-z0-9._@-]*$'; [[ $1 =~ $re ]]; }

# Free text input check against characters that would break metadata files
check_safe() {
    case $2 in *'"'*|*'\'*|*'$'*|*'`'*) die "$1 must not contain characters \" \\ \$ \`: $2";; esac
}

# Derive directory name from CN: "*.lan" -> "wildcard.lan", "Felix Muster" -> "felix-muster"
name_from_cn() {
    local n; n=$(lower "$1")
    n=${n//\*/wildcard}
    # Transliterate umlauts before transforming disallowed characters
    n=$(printf '%s' "$n" | sed -e 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/Ä/ae/g; s/Ö/oe/g; s/Ü/ue/g; s/ß/ss/g')
    n=$(printf '%s' "$n" | sed -e 's/[^a-z0-9._@-]/-/g' -e 's/--*/-/g' -e 's/^[-.]*//' -e 's/[-.]*$//')
    printf '%s' "$n"
}

# Escape special characters for openssl -subj (/ + and \ are reserved)
dn_escape() { printf '%s' "$1" | sed -e 's/[\\/+]/\\&/g'; }

# CIDR -> Subnet Mask (IPv4 only), for nameConstraints
cidr2mask() {
    local bits=$1 mask="" i oct
    for i in 1 2 3 4; do
        if [ "$bits" -ge 8 ]; then oct=255; bits=$((bits-8))
        else oct=$(( 256 - (1 << (8-bits)) )); [ "$bits" -eq 0 ] && oct=0; bits=0; fi
        mask="${mask:+$mask.}$oct"
    done
    printf '%s' "$mask"
}

# Convert IPv4 to 32-bit integer for subnet calculation
ip2int() { local IFS=.; set -- $1; printf '%s' $(( ($1<<24) + ($2<<16) + ($3<<8) + $4 )); }

# Action logging into $PKI_DIR/log/pki.log
log_action() {
    [ -d "$PKI_DIR/log" ] || return 0
    printf '%s  %s\n' "$(now)" "$*" >> "$PKI_DIR/log/pki.log"
}

# Check if a command is available
have() { command -v "$1" >/dev/null 2>&1; }

# Execute command with timeout (if timeout utility is available)
with_timeout() { if have timeout; then timeout 3 "$@"; else "$@"; fi; }

###############################################################################
# MODULE: lib/config.sh
###############################################################################
###############################################################################
# lib/config.sh - PKI configuration management and safe Key/Value file parsing
###############################################################################

CONF_KEYS="PKI_COUNTRY PKI_STATE PKI_LOCALITY PKI_ORG PKI_OU DEFAULT_CA DEFAULT_LEAF_KEY DEFAULT_CA_KEY ROOT_DAYS INTERMEDIATE_DAYS CRL_DAYS AIA_BASE_URL WARN_DAYS"

# Default settings for a new PKI
set_conf_defaults() {
    PKI_COUNTRY="US"
    PKI_STATE=""
    PKI_LOCALITY=""
    PKI_ORG="Homelab"
    PKI_OU=""
    DEFAULT_CA=""
    DEFAULT_LEAF_KEY="rsa3072"
    DEFAULT_CA_KEY="rsa4096"
    ROOT_DAYS=7300
    INTERMEDIATE_DAYS=3650
    CRL_DAYS=30
    AIA_BASE_URL=""
    WARN_DAYS=30
}

# Safely parse Key/Value files (pki.conf, cert.meta, ca.meta, templates).
# Files are NEVER executed with "source". Only whitelisted keys are ingested.
load_kv() {
    local file=$1 prefix=$2; shift 2
    local allowed=" $* " line key val re='^[[:space:]]*([A-Z_][A-Z0-9_]*)[[:space:]]*=(.*)$'
    local reDq='^"([^"]*)"' reSq="^'([^']*)'"
    [ -r "$file" ] || die "File not readable: $file"
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line%$'\r'}
        case $(trim "$line") in ''|'#'*) continue;; esac
        if ! [[ $line =~ $re ]]; then warn "$file: ignored line: $line"; continue; fi
        key=${BASH_REMATCH[1]}; val=$(trim "${BASH_REMATCH[2]}")
        if   [[ $val =~ $reDq ]]; then val=${BASH_REMATCH[1]}
        elif [[ $val =~ $reSq ]]; then val=${BASH_REMATCH[1]}
        else val=$(trim "${val%%#*}"); fi
        case $allowed in
            *" $key "*) printf -v "${prefix}${key}" '%s' "$val" ;;
            *) warn "$file: unknown key '$key' ignored" ;;
        esac
    done < "$file"
}

# Load global configuration from $PKI_DIR/pki.conf
load_config() {
    set_conf_defaults
    # shellcheck disable=SC2086
    [ -f "$PKI_DIR/pki.conf" ] && load_kv "$PKI_DIR/pki.conf" "" $CONF_KEYS
    return 0
}

# Write global configuration to $PKI_DIR/pki.conf
write_config() {
    mkdir -p "$PKI_DIR"
    cat > "$PKI_DIR/pki.conf" <<EOF
###############################################################################
# pki.conf - Global PKI configuration (generated by pki.sh $VERSION)
# Format: KEY="value" - Safely parsed, not executed as shell script.
###############################################################################

######## Subject fields inherited by new certificates
PKI_COUNTRY="$PKI_COUNTRY"          # 2-letter country code (ISO 3166-1 alpha-2)
PKI_STATE="$PKI_STATE"              # State or Province (optional)
PKI_LOCALITY="$PKI_LOCALITY"        # City / Locality (optional)
PKI_ORG="$PKI_ORG"                  # Organization name
PKI_OU="$PKI_OU"                    # Organizational Unit (optional)

######## Default settings
DEFAULT_CA="$DEFAULT_CA"            # Intermediate CA used when --ca is omitted
DEFAULT_LEAF_KEY="$DEFAULT_LEAF_KEY"   # rsa2048 | rsa3072 | rsa4096 | ed25519
DEFAULT_CA_KEY="$DEFAULT_CA_KEY"       # Default key type for new CAs
ROOT_DAYS="$ROOT_DAYS"              # Validity of Root CA in days
INTERMEDIATE_DAYS="$INTERMEDIATE_DAYS"  # Validity of Intermediate CAs in days
CRL_DAYS="$CRL_DAYS"                # Validity of CRLs - regenerate before expiry!
WARN_DAYS="$WARN_DAYS"              # Days before expiration to trigger warnings

######## Publishing (optional)
# Base HTTP URL hosting publish/ directory (CRL Distribution Point & AIA caIssuers)
# e.g., http://pki.lan -> http://pki.lan/server-ca.crl
AIA_BASE_URL="$AIA_BASE_URL"
EOF
    chmod 600 "$PKI_DIR/pki.conf" 2>/dev/null || true
}

# Ensure PKI has been initialized
require_pki() {
    [ -f "$PKI_DIR/root/certs/ca.crt" ] || die "No PKI found in $PKI_DIR. Initialize first: pki init (or set --dir / \$PKI_DIR)"
}

# Read single key from a .meta file
meta_get() {
    awk -F'"' -v k="$2" '$0 ~ "^"k"=" {print $2; exit}' "$1/cert.meta" 2>/dev/null
}

###############################################################################
# MODULE: lib/crypto.sh
###############################################################################
###############################################################################
# lib/crypto.sh - OpenSSL 3.x discovery, invocation, and cryptographic helpers
###############################################################################

# Discover OpenSSL 3.x in PATH or common installation locations
find_openssl() {
    local c
    for c in "${OPENSSL:-}" openssl /opt/homebrew/opt/openssl@3/bin/openssl \
             /usr/local/opt/openssl@3/bin/openssl /usr/bin/openssl /usr/local/bin/openssl; do
        [ -n "$c" ] || continue
        command -v "$c" >/dev/null 2>&1 || continue
        if "$c" version 2>/dev/null | grep -q '^OpenSSL 3'; then
            OPENSSL=$(command -v "$c")
            return 0
        fi
    done
    die "OpenSSL 3.x not found (LibreSSL is not supported).
  Linux: Install package 'openssl' (v3).
  macOS: 'brew install openssl@3'.
  Or set path manually: OPENSSL=/path/to/openssl"
}

# Run OpenSSL commands. Captures and formats errors nicely.
# When PKI_DEBUG=1 is set, all output is printed.
ssl() {
    local out rc=0
    out=$("$OPENSSL" "$@" 2>&1) || rc=$?
    if [ "$rc" -ne 0 ]; then
        err "openssl $1 failed (Exit $rc):"
        printf '%s\n' "$out" | sed 's/^/        /' >&2
        return "$rc"
    fi
    if [ "${PKI_DEBUG:-0}" = 1 ] && [ -n "$out" ]; then
        printf '%s\n' "$out" | sed 's/^/    [openssl] /' >&2
    fi
    return 0
}

# Validate supported key algorithms
valid_keytype() {
    case $1 in
        rsa2048|rsa3072|rsa4096|ed25519) return 0 ;;
        *) return 1 ;;
    esac
}

# Generate private key
#   gen_key <output> <type> <yes|no encrypt> <ENV-Var with password>
gen_key() {
    local out=$1 type=$2 enc=$3 passvar=${4:-} args=()
    case $type in
        rsa2048|rsa3072|rsa4096)
            args=(-algorithm RSA -pkeyopt "rsa_keygen_bits:${type#rsa}")
            ;;
        ed25519)
            args=(-algorithm ED25519)
            ;;
        *)
            die "Unknown key type '$type' (allowed: rsa2048, rsa3072, rsa4096, ed25519)"
            ;;
    esac

    if [ "$enc" = yes ]; then
        args+=(-aes-256-cbc)
        [ -n "$passvar" ] && [ -n "${!passvar:-}" ] || die "Internal error: no password provided for key generation"
        args+=(-pass "env:$passvar")
    fi

    ssl genpkey "${args[@]}" -out "$out" || die "Failed to generate key: $out"
    chmod 600 "$out"
}

# Certificate end date in Epoch seconds
cert_end_epoch() {
    local d; d=$("$OPENSSL" x509 -in "$1" -noout -enddate -dateopt iso_8601 2>/dev/null) || return 1
    d=${d#notAfter=}; to_epoch "${d%Z}"
}

# Expiration date formatted as YYYY-MM-DD
cert_end_date() {
    local d; d=$("$OPENSSL" x509 -in "$1" -noout -enddate -dateopt iso_8601 2>/dev/null) || { printf '?'; return; }
    d=${d#notAfter=}; printf '%s' "${d%% *}"
}

# Remaining validity in days (negative = expired)
cert_days_left() {
    local e; e=$(cert_end_epoch "$1") || { printf '?'; return; }
    printf '%s' $(( (e - $(date -u +%s)) / 86400 ))
}

# Certificate serial number
cert_serial() {
    local s; s=$("$OPENSSL" x509 -in "$1" -noout -serial)
    printf '%s' "${s#serial=}"
}

# Extract Common Name (CN) from certificate
cert_cn() {
    "$OPENSSL" x509 -in "$1" -noout -subject -nameopt multiline,utf8,-esc_msb 2>/dev/null \
        | awk -F' = ' '/commonName/{print $2; exit}'
}

# SHA-256 fingerprint
cert_fingerprint() {
    "$OPENSSL" x509 -in "$1" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2
}

# Status of serial in CA index database: V (valid) / R (revoked) / E (expired) / ""
index_status() {
    awk -F'\t' -v s="$2" '
        function norm(x){ x=toupper(x); sub(/^0+/,"",x); return x }
        norm($4)==norm(s){ st=$1 } END{ print st }' "$1/index.txt"
}

# Build subject DN string for openssl -subj
build_subj() {
    local s=""
    [ -n "$PKI_COUNTRY" ]  && s="$s/C=$(dn_escape "$PKI_COUNTRY")"
    [ -n "$PKI_STATE" ]    && s="$s/ST=$(dn_escape "$PKI_STATE")"
    [ -n "$PKI_LOCALITY" ] && s="$s/L=$(dn_escape "$PKI_LOCALITY")"
    [ -n "$PKI_ORG" ]      && s="$s/O=$(dn_escape "$PKI_ORG")"
    [ -n "${2:-$PKI_OU}" ] && s="$s/OU=$(dn_escape "${2:-$PKI_OU}")"
    s="$s/CN=$(dn_escape "$1")"
    printf '%s' "$s"
}

# Minimal req configuration (avoids dependency on host /etc/ssl/openssl.cnf)
write_req_cnf() {
    mkdir -p "$PKI_DIR"
    cat > "$PKI_DIR/.req.cnf" <<'EOF'
# Minimal OpenSSL configuration for "openssl req" - generated by pki.sh
[ req ]
distinguished_name = req_dn
string_mask        = utf8only
utf8               = yes
prompt             = no
[ req_dn ]
CN = placeholder
EOF
    chmod 600 "$PKI_DIR/.req.cnf" 2>/dev/null || true
}

# Generate self-signed certificate (Root CA or --ca selfsigned)
# Combines .req.cnf + extension file for backwards compatibility with OpenSSL < 3.2
#   req_selfsign <key> <subj> <days> <extfile> <section> <out> [passin-args...]
req_selfsign() {
    local key=$1 subj=$2 days=$3 ext=$4 sect=$5 out=$6 tmp rc=0; shift 6
    tmp=$(mktemp "${TMPDIR:-/tmp}/pki-req.XXXXXX")
    cat "$PKI_DIR/.req.cnf" "$ext" > "$tmp"
    ssl req -x509 -new -utf8 -config "$tmp" -key "$key" "$@" -subj "$subj" -days "$days" \
        -extensions "$sect" -out "$out" || rc=$?
    rm -f "$tmp"
    return $rc
}

###############################################################################
# MODULE: lib/passwords.sh
###############################################################################
###############################################################################
# lib/passwords.sh - Secure password handling, caching, and key encryption
###############################################################################

# Check if private key is encrypted
key_is_encrypted() {
    grep -q 'ENCRYPTED' "$1" 2>/dev/null
}

# Test whether the password stored in environment variable $2 unlocks key $1
key_pass_ok() {
    "$OPENSSL" pkey -in "$1" -passin "env:$2" -noout >/dev/null 2>&1
}

# Variable name for temporary in-memory CA password cache
pw_cache_var() {
    printf 'PKI_PWCACHE_%s' "$(upper "$1" | tr '.@-' '___')"
}

# Check if user has predefined an environment variable for CA (PKI_CA_PASS_<NAME> or PKI_CA_PASS)
user_pass_var() {
    local v
    v="PKI_CA_PASS_$(upper "$1" | tr '.@-' '___')"
    if [ -n "${!v:-}" ]; then
        printf '%s' "$v"
    elif [ -n "${PKI_CA_PASS:-}" ]; then
        printf 'PKI_CA_PASS'
    fi
}

# Masked password input from terminal or stdin
read_secret() { # <var> <prompt>
    local __rs_v __rs_ok=0
    printf '%s' "$2" >&2
    if [ -t 0 ]; then
        IFS= read -rs __rs_v || __rs_ok=1
    else
        IFS= read -r __rs_v || __rs_ok=1
    fi
    printf '\n' >&2
    [ "$__rs_ok" = 0 ] || die "End of input (EOF) - operation aborted. When non-interactive, set passwords via PKI_CA_PASS / PKI_KEY_PASS / PKI_P12_PASS."
    printf -v "$1" '%s' "$__rs_v"
}

# Double prompt confirmation for NEW password
new_pass() { # <var> <purpose>
    local __np_a __np_b
    while :; do
        read_secret __np_a "  Enter new password for $2 (min 4 characters): "
        if [ ${#__np_a} -lt 4 ]; then
            warn "Too short - OpenSSL requires at least 4 characters"
            continue
        fi
        read_secret __np_b "  Confirm password: "
        [ "$__np_a" = "$__np_b" ] && break
        warn "Passwords do not match - please re-enter"
    done
    export "$1=$__np_a"
}

# Prompt and verify password for an EXISTING key (max 3 attempts)
unlock_key() { # <var> <keyfile> <purpose>
    local __uk_p __uk_i
    for __uk_i in 1 2 3; do
        read_secret __uk_p "  Password for $3: "
        export "$1=$__uk_p"
        if key_pass_ok "$2" "$1"; then
            return 0
        fi
        warn "Incorrect password (attempt $__uk_i/3)"
    done
    unset "$1"
    die "Aborted after 3 failed attempts - unable to unlock $3. No changes were made."
}

# Prepare -passin arguments for CA private key -> sets array PASSIN
ca_passin() {
    local ca=$1 key uv cv
    key="$(ca_dir "$ca")/private/ca.key"
    PASSIN=()
    key_is_encrypted "$key" || return 0
    uv=$(user_pass_var "$ca")
    if [ -n "$uv" ]; then
        key_pass_ok "$key" "$uv" || die "The password in \$$uv does not match CA key '$ca'"
        PASSIN=(-passin "env:$uv")
        return 0
    fi
    cv=$(pw_cache_var "$ca")
    [ -n "${!cv:-}" ] || unlock_key "$cv" "$key" "CA '$ca'"
    PASSIN=(-passin "env:$cv")
}

# Set password variable for a NEW CA key -> sets NEWPASSVAR
ca_newpass() { # <ca> <description>
    NEWPASSVAR=$(user_pass_var "$1")
    if [ -z "$NEWPASSVAR" ]; then
        NEWPASSVAR=$(pw_cache_var "$1")
        new_pass "$NEWPASSVAR" "$2"
    fi
}

# Prepare -passin for leaf private key -> sets array KPASSIN (if encrypted)
key_passin() {
    KPASSIN=()
    key_is_encrypted "$1" || return 0
    if [ -n "${PKI_KEY_PASS:-}" ]; then
        key_pass_ok "$1" PKI_KEY_PASS || die "The password in \$PKI_KEY_PASS does not match $1"
    else
        unlock_key PKI_KEY_PASS "$1" "the private key of '$(basename "$(dirname "$1")")'"
    fi
    KPASSIN=(-passin env:PKI_KEY_PASS)
}

# Ensure password for .p12 archive export
ensure_p12_pass() {
    [ -n "${PKI_P12_PASS:-}" ] || new_pass PKI_P12_PASS "the .p12 archive (prompted when importing into Windows/macOS/clients)"
}

# Atomically clean up partially initialized directory on abort
cleanup_partial() {
    if [ -n "${PARTIAL_DIR:-}" ] && [ -d "$PARTIAL_DIR" ]; then
        rm -rf "$PARTIAL_DIR"
        warn "Aborted - safely removed partial directory: ${PARTIAL_DIR#"$PKI_DIR"/}"
    fi
    PARTIAL_DIR=""
}

###############################################################################
# MODULE: lib/presets.sh
###############################################################################
###############################################################################
# lib/presets.sh - Certificate Profiles & Presets (KU, EKU, SANs, Validity)
###############################################################################

PRESETS="server wildcard client server-client user vpn-server vpn-client smime codesign ocsp timestamp custom"

# Loads profile definition for a preset into global P_* variables
load_preset() {
    P_DESC=""
    P_USE=""
    P_KU_RSA=""
    P_KU_ED=""
    P_EKU=""
    P_EKU_CRIT=no
    P_DAYS=365
    P_SAN_REQ=""
    P_SAN_ASK=""
    P_EXTRA=""
    P_PURPOSE=any
    P_CN_AUTO=""

    case $1 in
        server)
            P_DESC="TLS Server: Web server, reverse proxy, LDAPS, Proxmox, UniFi, Mail (SMTP/IMAP), Databases"
            P_USE="nginx/Traefik/Caddy: fullchain.pem + key.pem | HAProxy: combined.pem | Windows/IIS: cert.p12"
            P_KU_RSA="digitalSignature, keyEncipherment"
            P_KU_ED="digitalSignature"
            P_EKU="serverAuth"
            P_DAYS=397
            P_SAN_REQ="dns|ip"
            P_SAN_ASK="dns ip"
            P_PURPOSE=sslserver
            P_CN_AUTO=dns
            ;;
        wildcard)
            P_DESC="TLS Server Wildcard: *.domain + base domain (e.g., *.homelab.lan and homelab.lan)"
            P_USE="Same as server - one certificate covering all subdomains at that level (e.g. app1.lan, app2.lan)"
            P_KU_RSA="digitalSignature, keyEncipherment"
            P_KU_ED="digitalSignature"
            P_EKU="serverAuth"
            P_DAYS=397
            P_SAN_REQ="dns|ip"
            P_SAN_ASK="dns ip"
            P_PURPOSE=sslserver
            P_CN_AUTO=dns
            ;;
        client)
            P_DESC="TLS Client Auth: mTLS, 802.1X EAP-TLS (WiFi/Wired 802.1X), browser login, API clients"
            P_USE="Browser/Windows/macOS/iOS: import cert.p12 | curl/scripts: --cert cert.pem --key key.pem"
            P_KU_RSA="digitalSignature, keyEncipherment"
            P_KU_ED="digitalSignature"
            P_EKU="clientAuth"
            P_DAYS=730
            P_SAN_ASK="dns email"
            P_PURPOSE=sslclient
            ;;
        server-client)
            P_DESC="Dual Server + Client: mTLS peers, cluster nodes, etcd, Syslog TLS, SaltStack, MQTT broker/client"
            P_USE="Services that accept inbound connections and initiate outbound mutual TLS connections"
            P_KU_RSA="digitalSignature, keyEncipherment"
            P_KU_ED="digitalSignature"
            P_EKU="serverAuth, clientAuth"
            P_DAYS=397
            P_SAN_REQ="dns|ip"
            P_SAN_ASK="dns ip"
            P_PURPOSE=sslserver
            P_CN_AUTO=dns
            ;;
        user)
            P_DESC="User Identity: Client authentication + S/MIME combined (Login + Email signing & encryption)"
            P_USE="Import cert.p12 into mail client and operating system keychain / certificate store"
            P_KU_RSA="digitalSignature, nonRepudiation, keyEncipherment"
            P_KU_ED="digitalSignature, nonRepudiation"
            P_EKU="clientAuth, emailProtection"
            P_DAYS=730
            P_SAN_REQ="email"
            P_SAN_ASK="email"
            P_PURPOSE=sslclient
            P_CN_AUTO=email
            ;;
        vpn-server)
            P_DESC="VPN Server: OpenVPN, IPsec/IKEv2 (strongSwan, Windows RRAS, MikroTik, pfSense/OPNsense)"
            P_USE="OpenVPN: cert/key + ca-bundle.pem | strongSwan: swanctl x509 + private"
            P_KU_RSA="digitalSignature, keyEncipherment"
            P_KU_ED="digitalSignature"
            P_EKU="serverAuth, 1.3.6.1.5.5.7.3.17, 1.3.6.1.5.5.8.2.2"
            P_DAYS=730
            P_SAN_REQ="dns|ip"
            P_SAN_ASK="dns ip"
            P_PURPOSE=sslserver
            P_CN_AUTO=dns
            ;;
        vpn-client)
            P_DESC="VPN Client: OpenVPN, IPsec/IKEv2 (user or device authentication)"
            P_USE="OpenVPN: embed inline into .ovpn configuration file | Windows/macOS/iOS: cert.p12"
            P_KU_RSA="digitalSignature, keyEncipherment"
            P_KU_ED="digitalSignature"
            P_EKU="clientAuth, 1.3.6.1.5.5.7.3.17"
            P_DAYS=730
            P_SAN_ASK="dns email"
            P_PURPOSE=sslclient
            ;;
        smime)
            P_DESC="S/MIME: Email signing and encryption (Outlook, Apple Mail, Thunderbird)"
            P_USE="Import cert.p12 into mail client; recipients must trust the Root or Intermediate CA"
            P_KU_RSA="digitalSignature, nonRepudiation, keyEncipherment"
            P_KU_ED="digitalSignature, nonRepudiation"
            P_EKU="emailProtection"
            P_DAYS=730
            P_SAN_REQ="email"
            P_SAN_ASK="email"
            P_PURPOSE=smimesign
            P_CN_AUTO=email
            ;;
        codesign)
            P_DESC="Code Signing: PowerShell scripts, binaries, packages, Git commit & container signatures"
            P_USE="PowerShell: Set-AuthenticodeSignature with cert.p12 | osslsigncode | openssl cms"
            P_KU_RSA="digitalSignature"
            P_KU_ED="digitalSignature"
            P_EKU="codeSigning"
            P_DAYS=1095
            P_PURPOSE=any
            ;;
        ocsp)
            P_DESC="OCSP Responder Signer: signs OCSP responses for the issuing CA"
            P_USE="pki ocsp-server --ca <ca> --signer <name>"
            P_KU_RSA="digitalSignature"
            P_KU_ED="digitalSignature"
            P_EKU="OCSPSigning"
            P_DAYS=365
            P_PURPOSE=ocsphelper
            P_EXTRA="noCheck = ignored"
            ;;
        timestamp)
            P_DESC="Time Stamping Authority (TSA, RFC 3161): signed timestamps for documents and code"
            P_USE="openssl ts -reply ... -signer cert.pem -inkey key.pem"
            P_KU_RSA="digitalSignature, nonRepudiation"
            P_KU_ED="digitalSignature, nonRepudiation"
            P_EKU="timeStamping"
            P_EKU_CRIT=yes
            P_DAYS=1825
            P_PURPOSE=timestampsign
            ;;
        custom)
            P_DESC="Custom Key Usage and Extended Key Usage configured freely"
            P_USE="Special scenarios - KU and EKU are stored in cert.meta for full renewal compatibility"
            P_KU_RSA="digitalSignature"
            P_KU_ED="digitalSignature"
            P_EKU=""
            P_DAYS=365
            P_SAN_ASK="dns ip email uri"
            P_PURPOSE=any
            ;;
        *)
            return 1
            ;;
    esac
}

# Determines preset family for config examples and deployment guides
preset_family() {
    case $1 in
        server|wildcard|server-client) echo server ;;
        vpn-server)                    echo vpnserver ;;
        client|user|vpn-client|smime)  echo client ;;
        codesign|ocsp|timestamp)       echo "$1" ;;
        *)                             echo custom ;;
    esac
}

# Prints an overview of all presets on the terminal
print_presets() {
    local p
    banner "Available Certificate Presets"
    for p in $PRESETS; do
        load_preset "$p"
        printf '\n%s%-16s%s %s\n' "$C_BLD" "● $p" "$C_RST" "$P_DESC"
        printf '  %-18s %s\n' "Usage:" "$P_USE"
        printf '  %-18s %s (RSA) / %s (Ed25519)\n' "keyUsage:" "${P_KU_RSA:--}" "${P_KU_ED:--}"
        printf '  %-18s %s%s\n' "EKU:" "${P_EKU:-customizable}" "$( [ "$P_EKU_CRIT" = yes ] && echo ' (critical)')"
        printf '  %-18s %s days\n' "Default validity:" "$P_DAYS"
        printf '  %-18s %s\n' "Required SANs:" "${P_SAN_REQ:-none (optional)}"
        [ -n "$P_EXTRA" ] && printf '  %-18s %s\n' "Extra flags:" "$P_EXTRA"
    done
    printf '\n'
    info "Tip: With '--ca selfsigned', any preset can also be generated as a standalone self-signed certificate without a CA."
}

###############################################################################
# MODULE: lib/ca.sh
###############################################################################
###############################################################################
# lib/ca.sh - Root CA & Intermediate CAs Management, Skeletons, and Metadata
###############################################################################

CA_META_KEYS="NAME TYPE CN SUBJECT KEY KEY_PASS DAYS PATHLEN PERMIT_DNS PERMIT_IP EKU_LIMIT OCSP_URL CREATED"

# Resolves directory for a CA (root or intermediate/<name>)
ca_dir() {
    if [ "$1" = root ]; then
        printf '%s' "$PKI_DIR/root"
    else
        printf '%s' "$PKI_DIR/intermediate/$1"
    fi
}

# Checks if a CA exists
ca_exists() {
    [ -f "$(ca_dir "$1")/certs/ca.crt" ]
}

# Lists all existing Intermediate CA names
list_intermediates() {
    local d
    [ -d "$PKI_DIR/intermediate" ] || return 0
    for d in "$PKI_DIR"/intermediate/*/; do
        [ -f "$d/certs/ca.crt" ] && basename "$d"
    done
    return 0
}

# Initializes directory skeleton and OpenSSL CA configuration for a CA
make_ca_skeleton() {
    local d=$1 name=$2
    mkdir -p "$d/certs" "$d/crl" "$d/newcerts" "$d/private" "$d/archive"
    chmod 700 "$d/private"
    : > "$d/index.txt"
    printf 'unique_subject = no\n' > "$d/index.txt.attr"
    printf '1000\n' > "$d/crlnumber"

    cat > "$d/ca.cnf" <<EOF
###############################################################################
# OpenSSL CA Configuration for: $name  (generated by pki.sh $VERSION)
# Used internally by "openssl ca" (signing, revoking, CRL generation).
###############################################################################
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $d
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
rand_serial       = yes                 # Random 160-bit serial numbers
crlnumber         = \$dir/crlnumber
private_key       = \$dir/private/ca.key
certificate       = \$dir/certs/ca.crt
crl               = \$dir/crl/ca.crl
default_md        = default             # SHA-256 for RSA, internal digest for Ed25519
default_days      = 365
default_crl_days  = ${CRL_DAYS:-30}
crl_extensions    = crl_ext
preserve          = no
policy            = policy_loose
unique_subject    = no
copy_extensions   = none                # Enforce extensions strictly from ext.cnf
email_in_dn       = no
name_opt          = ca_default
cert_opt          = ca_default

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ crl_ext ]
authorityKeyIdentifier = keyid:always
EOF
    chmod 600 "$d/ca.cnf" 2>/dev/null || true
}

# Writes metadata file for a CA
write_ca_meta() {
    local d=$1
    cat > "$d/ca.meta" <<EOF
###############################################################################
# Metadata for CA "$M_NAME" - managed by pki.sh
###############################################################################
NAME="$M_NAME"
TYPE="$M_TYPE"
CN="$M_CN"
SUBJECT="$M_SUBJECT"
KEY="$M_KEY"
KEY_PASS="$M_KEY_PASS"
DAYS="$M_DAYS"
PATHLEN="$M_PATHLEN"
PERMIT_DNS="$M_PERMIT_DNS"
PERMIT_IP="$M_PERMIT_IP"
EKU_LIMIT="$M_EKU_LIMIT"
OCSP_URL="$M_OCSP_URL"
CREATED="$M_CREATED"
EOF
    chmod 600 "$d/ca.meta" 2>/dev/null || true
}

# Loads metadata of a CA into M_* variables
load_ca_meta() {
    M_NAME="" M_TYPE="" M_CN="" M_SUBJECT="" M_KEY="" M_KEY_PASS="" M_DAYS=""
    M_PATHLEN="" M_PERMIT_DNS="" M_PERMIT_IP="" M_EKU_LIMIT="" M_OCSP_URL="" M_CREATED=""
    # shellcheck disable=SC2086
    load_kv "$(ca_dir "$1")/ca.meta" M_ $CA_META_KEYS
}

# Generates CRL Distribution Points and AIA lines for ext.cnf
aia_lines() {
    local issuer=$1 ocsp=${2:-} base=${AIA_BASE_URL%/}
    if [ -n "$base" ]; then
        printf 'crlDistributionPoints = URI:%s/%s.crl\n' "$base" "$issuer"
        if [ -n "$ocsp" ]; then
            printf 'authorityInfoAccess = OCSP;URI:%s, caIssuers;URI:%s/%s.crt\n' "$ocsp" "$base" "$issuer"
        else
            printf 'authorityInfoAccess = caIssuers;URI:%s/%s.crt\n' "$base" "$issuer"
        fi
    elif [ -n "$ocsp" ]; then
        printf 'authorityInfoAccess = OCSP;URI:%s\n' "$ocsp"
    fi
}

# Copies CA certificate and CRL to publish/ directory (in PEM and DER format)
publish_ca() {
    local ca=$1 d
    d=$(ca_dir "$ca")
    mkdir -p "$PKI_DIR/publish"
    chmod 755 "$PKI_DIR/publish" 2>/dev/null || true

    cp "$d/certs/ca.crt" "$PKI_DIR/publish/$ca.pem"
    "$OPENSSL" x509 -in "$d/certs/ca.crt" -outform der -out "$PKI_DIR/publish/$ca.crt"

    if [ -f "$d/crl/ca.crl" ]; then
        cp "$d/crl/ca.crl" "$PKI_DIR/publish/$ca.crl.pem"
        "$OPENSSL" crl -in "$d/crl/ca.crl" -outform der -out "$PKI_DIR/publish/$ca.crl"
    fi
    chmod 644 "$PKI_DIR/publish/"* 2>/dev/null || true
}

# Creates the Root CA
# Requires: R_CN R_KEY R_DAYS R_PASS(yes/no)
create_root() {
    local d="$PKI_DIR/root" subj
    [ -f "$d/certs/ca.crt" ] && die "Root CA already exists in $d"
    valid_keytype "$R_KEY" || die "Invalid key type: $R_KEY"
    is_int "$R_DAYS" || die "Validity days must be a number: $R_DAYS"
    check_safe "Root-CN" "$R_CN"

    banner "Creating Root CA: $R_CN"
    [ "$R_KEY" = ed25519 ] && warn "Ed25519 Root CA: Web browsers do NOT support Ed25519 signatures in TLS chains. For web certificates, select RSA (rsa4096)!"

    NEWPASSVAR=""
    if [ "$R_PASS" = yes ]; then
        info "The Root CA passphrase will be required whenever signing a new Intermediate CA or generating a Root CRL - store it safely!"
        ca_newpass root "the Root CA"
    fi

    # Create root directory layout
    mkdir -p "$PKI_DIR/log" "$PKI_DIR/issued" "$PKI_DIR/intermediate" "$PKI_DIR/publish" "$PKI_DIR/templates"
    write_config
    write_req_cnf

    PARTIAL_DIR=$d
    trap cleanup_partial EXIT
    make_ca_skeleton "$d" root

    gen_key "$d/private/ca.key" "$R_KEY" "$R_PASS" "$NEWPASSVAR"
    ok "Root key generated ($R_KEY$( [ "$R_PASS" = yes ] && echo ', AES-256 encrypted'))"

    cat > "$d/ext.cnf" <<EOF
###############################################################################
# Root CA Extensions
###############################################################################
[ v3_root ]
basicConstraints       = critical, CA:TRUE
keyUsage               = critical, keyCertSign, cRLSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always
EOF

    subj=$(build_subj "$R_CN")
    ca_passin root
    req_selfsign "$d/private/ca.key" "$subj" "$R_DAYS" "$d/ext.cnf" v3_root "$d/certs/ca.crt" "${PASSIN[@]}" \
        || die "Failed to generate Root CA certificate"
    chmod 644 "$d/certs/ca.crt"

    M_NAME=root; M_TYPE=root; M_CN=$R_CN; M_SUBJECT=$subj; M_KEY=$R_KEY; M_KEY_PASS=$R_PASS
    M_DAYS=$R_DAYS; M_PATHLEN=""; M_PERMIT_DNS=""; M_PERMIT_IP=""; M_EKU_LIMIT=""; M_OCSP_URL=""
    M_CREATED=$(now)
    write_ca_meta "$d"

    gen_crl root
    publish_ca root
    log_action "ROOT created CN='$R_CN' key=$R_KEY days=$R_DAYS"
    PARTIAL_DIR="" # Successfully finished

    ok "Root CA created successfully: $d/certs/ca.crt (valid until $(cert_end_date "$d/certs/ca.crt"))"
    info "SHA-256 Fingerprint: $(cert_fingerprint "$d/certs/ca.crt")"
}

# Writes extensions for an Intermediate CA
write_intermediate_ext() {
    local f=$1 i=0 item ip bits
    {
        printf '###############################################################################\n'
        printf '# Extensions for Intermediate CA "%s"\n' "$N_NAME"
        printf '###############################################################################\n'
        printf '[ v3_intermediate ]\n'
        printf 'basicConstraints       = critical, CA:TRUE, pathlen:%s\n' "${N_PATHLEN:-0}"
        printf 'keyUsage               = critical, digitalSignature, keyCertSign, cRLSign\n'
        printf 'subjectKeyIdentifier   = hash\n'
        printf 'authorityKeyIdentifier = keyid:always\n'
        [ -n "$N_EKU_LIMIT" ] && printf 'extendedKeyUsage       = %s\n' "$N_EKU_LIMIT"
        aia_lines root ""
        if [ -n "$N_PERMIT_DNS$N_PERMIT_IP" ]; then
            printf 'nameConstraints        = critical, @name_constraints\n'
            printf '\n[ name_constraints ]\n'
            split_list "$N_PERMIT_DNS"
            for item in "${SPLIT[@]}"; do
                printf 'permitted;DNS.%s = %s\n' "$i" "$(lower "$item")"
                i=$((i+1))
            done
            i=0
            split_list "$N_PERMIT_IP"
            for item in "${SPLIT[@]}"; do
                ip=${item%/*}; bits=${item#*/}
                [ "$bits" = "$item" ] && bits=32
                is_ipv4 "$ip" || die "nameConstraints: only IPv4 CIDR is currently supported: $item"
                printf 'permitted;IP.%s = %s/%s\n' "$i" "$ip" "$(cidr2mask "$bits")"
                i=$((i+1))
            done
        fi
    } > "$f"
}

# Creates a new Intermediate CA
# Requires: N_NAME N_CN N_KEY N_DAYS N_PASS N_PATHLEN N_PERMIT_DNS N_PERMIT_IP N_EKU_LIMIT N_OCSP_URL
create_intermediate() {
    local d subj
    is_name "$N_NAME" || die "Invalid CA name '$N_NAME' (allowed: a-z 0-9 . _ -)"
    [ "$N_NAME" = root ] || [ "$N_NAME" = selfsigned ] && die "The name '$N_NAME' is reserved"
    d=$(ca_dir "$N_NAME")
    [ -e "$d/certs/ca.crt" ] && die "Intermediate CA '$N_NAME' already exists"

    [ -z "$N_KEY" ]  && N_KEY=$DEFAULT_CA_KEY
    [ -z "$N_DAYS" ] && N_DAYS=$INTERMEDIATE_DAYS
    [ -z "$N_CN" ]   && N_CN="$PKI_ORG $N_NAME"
    valid_keytype "$N_KEY" || die "Invalid key type: $N_KEY"
    is_int "$N_DAYS" || die "Validity days must be a number: $N_DAYS"
    is_int "${N_PATHLEN:-0}" || die "pathlen must be an integer"
    check_safe "CN" "$N_CN"

    local rootleft
    rootleft=$(cert_days_left "$PKI_DIR/root/certs/ca.crt")
    if [ "$N_DAYS" -gt "$rootleft" ]; then
        warn "Validity shortened to Root CA remaining lifetime: $rootleft days"
        N_DAYS=$rootleft
    fi

    banner "Creating Intermediate CA: $N_NAME"
    [ "$N_KEY" = ed25519 ] && warn "Ed25519 CA: Web browsers cannot verify Ed25519 chains. Only suitable for non-browser purposes (VPN, internal microservices, mTLS)."

    # Resolve passwords in advance
    if key_is_encrypted "$PKI_DIR/root/private/ca.key"; then
        info "Root CA authorization required to sign the new Intermediate CA:"
        ca_passin root
    fi
    NEWPASSVAR=""
    [ "$N_PASS" = yes ] && ca_newpass "$N_NAME" "the Intermediate CA '$N_NAME'"

    [ -d "$d" ] && rm -rf "$d"
    PARTIAL_DIR=$d
    trap cleanup_partial EXIT

    make_ca_skeleton "$d" "$N_NAME"
    gen_key "$d/private/ca.key" "$N_KEY" "$N_PASS" "$NEWPASSVAR"
    write_intermediate_ext "$d/ext.cnf"

    subj=$(build_subj "$N_CN")
    ca_passin "$N_NAME"
    ssl req -new -utf8 -config "$PKI_DIR/.req.cnf" -key "$d/private/ca.key" "${PASSIN[@]}" -subj "$subj" -out "$d/ca.csr" \
        || die "CSR creation for Intermediate CA failed"

    ca_passin root
    ssl ca -batch -config "$PKI_DIR/root/ca.cnf" "${PASSIN[@]}" -extfile "$d/ext.cnf" -extensions v3_intermediate \
        -days "$N_DAYS" -notext -preserveDN -in "$d/ca.csr" -out "$d/certs/ca.crt" \
        || die "Signing by Root CA failed"
    ok "Signed by Root CA"
    chmod 644 "$d/certs/ca.crt"

    # Create full chain (Intermediate + Root)
    cat "$d/certs/ca.crt" "$PKI_DIR/root/certs/ca.crt" > "$d/certs/chain.pem"
    chmod 644 "$d/certs/chain.pem"

    M_NAME=$N_NAME; M_TYPE=intermediate; M_CN=$N_CN; M_SUBJECT=$subj; M_KEY=$N_KEY; M_KEY_PASS=$N_PASS
    M_DAYS=$N_DAYS; M_PATHLEN=${N_PATHLEN:-0}; M_PERMIT_DNS=$N_PERMIT_DNS; M_PERMIT_IP=$N_PERMIT_IP
    M_EKU_LIMIT=$N_EKU_LIMIT; M_OCSP_URL=$N_OCSP_URL; M_CREATED=$(now)
    write_ca_meta "$d"

    gen_crl "$N_NAME"
    gen_crl root
    publish_ca "$N_NAME"

    PARTIAL_DIR="" # Successfully completed

    if [ -z "$DEFAULT_CA" ]; then
        DEFAULT_CA=$N_NAME
        write_config
        info "Set as default CA (DEFAULT_CA in pki.conf)"
    fi

    log_action "INTERMEDIATE created name=$N_NAME CN='$N_CN' key=$N_KEY days=$N_DAYS"
    ok "Intermediate CA '$N_NAME' created successfully (valid until $(cert_end_date "$d/certs/ca.crt"))"
}

###############################################################################
# MODULE: lib/issue.sh
###############################################################################
###############################################################################
# lib/issue.sh - Leaf Certificate Issuance, SAN Normalization, and Bundles
###############################################################################

I_KEYS="PRESET NAME CN DNS IP EMAIL URI KEY DAYS CA OU KEY_PASS EXPORT_P12 EXPORT_DER P12_LEGACY CUSTOM_KU CUSTOM_EKU"

# Resets all variables for certificate issuance
reset_issue_vars() {
    I_PRESET="" I_NAME="" I_CN="" I_DNS="" I_IP="" I_EMAIL="" I_URI="" I_KEY=""
    I_DAYS="" I_CA="" I_OU="" I_KEY_PASS=no I_EXPORT_P12=no I_EXPORT_DER=no I_P12_LEGACY=no
    I_CUSTOM_KU="" I_CUSTOM_EKU="" I_DOMAIN=""
    I_FORCE=0 I_RENEW=0 I_KEEP_KEY=0 I_CSR_FILE=""
}

# Checks and normalizes SANs (lowercase DNS, deduplicate, move IPs from DNS field)
normalize_sans() {
    local x dns="" ip="" email="" uri="" cn
    # Modern TLS clients ignore CN if SAN is present; ensure CN is in SAN
    case $P_CN_AUTO in
        dns)
            cn=$(lower "$I_CN")
            if is_ipv4 "$cn" || is_ipv6 "$cn"; then
                ip=$cn; I_CN=$cn
            elif is_hostname "$cn"; then
                dns=$cn; I_CN=$cn
            fi
            ;;
        email)
            is_email "$I_CN" && email=$(lower "$I_CN")
            ;;
    esac

    split_list "$I_DNS"
    for x in "${SPLIT[@]}"; do
        x=$(lower "$x"); x=${x%.}
        if is_ipv4 "$x" || is_ipv6 "$x"; then
            warn "'$x' is an IP address -> automatically added as IP SAN"
            ip=$(add_uniq "$ip" "$x")
            continue
        fi
        is_hostname "$x" || die "Invalid DNS name: '$x'"
        dns=$(add_uniq "$dns" "$x")
    done

    split_list "$I_IP"
    for x in "${SPLIT[@]}"; do
        x=$(lower "$x")
        is_ipv4 "$x" || is_ipv6 "$x" || die "Invalid IP address: '$x'"
        ip=$(add_uniq "$ip" "$x")
    done

    split_list "$I_EMAIL"
    for x in "${SPLIT[@]}"; do
        x=$(lower "$x")
        is_email "$x" || die "Invalid email address: '$x'"
        email=$(add_uniq "$email" "$x")
    done

    split_list "$I_URI"
    for x in "${SPLIT[@]}"; do
        is_uri "$x" || die "Invalid URI: '$x'"
        uri=$(add_uniq "$uri" "$x")
    done

    I_DNS=$dns
    I_IP=$ip
    I_EMAIL=$email
    I_URI=$uri
}

# Validates Name Constraints against issuing CA prior to signing
check_name_constraints() {
    local ca=$1 x c ok bits net mask
    load_ca_meta "$ca"

    if [ -n "$M_PERMIT_DNS" ]; then
        split_list "$I_DNS"
        for x in "${SPLIT[@]}"; do
            ok=0; x=${x#\*.}
            for c in $(printf '%s' "$M_PERMIT_DNS" | tr ',' ' '); do
                c=$(lower "$c")
                case $c in
                    .*) case $x in *"$c") ok=1 ;; esac ;;
                    *)  [ "$x" = "$c" ] && ok=1; case $x in *".$c") ok=1 ;; esac ;;
                esac
            done
            [ "$ok" = 1 ] || die "DNS '$x' violates Name Constraints of CA '$ca' (Permitted: $M_PERMIT_DNS)"
        done
    fi

    if [ -n "$M_PERMIT_IP" ]; then
        split_list "$I_IP"
        for x in "${SPLIT[@]}"; do
            is_ipv4 "$x" || die "IP '$x' violates Name Constraints of CA '$ca' (Only IPv4 supported: $M_PERMIT_IP)"
            ok=0
            for c in $(printf '%s' "$M_PERMIT_IP" | tr ',' ' '); do
                net=${c%/*}; bits=${c#*/}; [ "$bits" = "$c" ] && bits=32
                mask=$(( bits == 0 ? 0 : (0xFFFFFFFF << (32-bits)) & 0xFFFFFFFF ))
                [ $(( $(ip2int "$x") & mask )) -eq $(( $(ip2int "$net") & mask )) ] && ok=1
            done
            [ "$ok" = 1 ] || die "IP '$x' violates Name Constraints of CA '$ca' (Permitted: $M_PERMIT_IP)"
        done
    fi
    return 0
}

# Generates extension configuration file for a leaf certificate
write_leaf_ext() {
    local f=$1 issuer=$2 ocsp=$3 ku eku x n
    if [ "$I_KEY" = ed25519 ]; then ku=$P_KU_ED; else ku=$P_KU_RSA; fi
    eku=$P_EKU

    {
        printf '###############################################################################\n'
        printf '# Extensions for "%s" (Preset: %s, CA: %s)\n' "$I_NAME" "$I_PRESET" "$issuer"
        printf '# Generated by pki.sh %s on %s\n' "$VERSION" "$(now)"
        printf '###############################################################################\n'
        printf '[ leaf_ext ]\n'
        printf 'basicConstraints       = critical, CA:FALSE\n'
        [ -n "$ku" ]  && printf 'keyUsage               = critical, %s\n' "$ku"
        if [ -n "$eku" ]; then
            if [ "$P_EKU_CRIT" = yes ]; then
                printf 'extendedKeyUsage       = critical, %s\n' "$eku"
            else
                printf 'extendedKeyUsage       = %s\n' "$eku"
            fi
        fi
        printf 'subjectKeyIdentifier   = hash\n'
        if [ "$issuer" != selfsigned ]; then
            printf 'authorityKeyIdentifier = keyid:always\n'
            if [ "$I_PRESET" = ocsp ]; then
                aia_lines "$issuer" ""
            else
                aia_lines "$issuer" "$ocsp"
            fi
        fi
        [ -n "$P_EXTRA" ] && printf '%s\n' "$P_EXTRA"
        if [ -n "$I_DNS$I_IP$I_EMAIL$I_URI" ]; then
            printf 'subjectAltName         = @alt_names\n\n[ alt_names ]\n'
            n=1; split_list "$I_DNS";   for x in "${SPLIT[@]}"; do printf 'DNS.%s   = %s\n' "$n" "$x"; n=$((n+1)); done
            n=1; split_list "$I_IP";    for x in "${SPLIT[@]}"; do printf 'IP.%s    = %s\n' "$n" "$x"; n=$((n+1)); done
            n=1; split_list "$I_EMAIL"; for x in "${SPLIT[@]}"; do printf 'email.%s = %s\n' "$n" "$x"; n=$((n+1)); done
            n=1; split_list "$I_URI";   for x in "${SPLIT[@]}"; do printf 'URI.%s   = %s\n' "$n" "$x"; n=$((n+1)); done
        fi
    } > "$f"
}

# Writes metadata file (also serves as reproducible template for renewal and batch issuing)
write_cert_meta() {
    local target=$1 certfile=$2
    cat > "$target" <<EOF
###############################################################################
# Metadata for "$I_NAME" - managed by pki.sh
# This file can be used as a template: pki batch <file>
###############################################################################
PRESET="$I_PRESET"
NAME="$I_NAME"
CN="$I_CN"
OU="$I_OU"
DNS="$I_DNS"
IP="$I_IP"
EMAIL="$I_EMAIL"
URI="$I_URI"
KEY="$I_KEY"
DAYS="$I_DAYS"
CA="$I_CA"
KEY_PASS="$I_KEY_PASS"
EXPORT_P12="$I_EXPORT_P12"
EXPORT_DER="$I_EXPORT_DER"
P12_LEGACY="$I_P12_LEGACY"
CUSTOM_KU="$I_CUSTOM_KU"
CUSTOM_EKU="$I_CUSTOM_EKU"
ISSUED="$(now)"
SERIAL="$(cert_serial "$certfile")"
EOF
    chmod 600 "$target" 2>/dev/null || true
}

# Generates certificate chains and bundle files
write_bundles() {
    local d=$1 ca=$2 cad
    if [ "$ca" = selfsigned ]; then
        : > "$d/chain.pem"
        cp "$d/cert.pem" "$d/fullchain.pem"
        cp "$d/cert.pem" "$d/ca-bundle.pem"
    elif [ "$ca" = root ]; then
        : > "$d/chain.pem"
        cp "$d/cert.pem" "$d/fullchain.pem"
        cp "$PKI_DIR/root/certs/ca.crt" "$d/ca-bundle.pem"
    else
        cad=$(ca_dir "$ca")
        cp "$cad/certs/ca.crt" "$d/chain.pem"
        cat "$d/cert.pem" "$cad/certs/ca.crt" > "$d/fullchain.pem"
        cp "$cad/certs/chain.pem" "$d/ca-bundle.pem"
    fi

    # Combined bundle for HAProxy
    if [ -f "$d/key.pem" ]; then
        cat "$d/key.pem" "$d/fullchain.pem" > "$d/combined.pem"
        chmod 600 "$d/combined.pem"
    fi
    chmod 644 "$d/cert.pem" "$d/chain.pem" "$d/fullchain.pem" "$d/ca-bundle.pem" 2>/dev/null || true
}

# Archives previous certificate material during renewal
archive_leaf() {
    local d=$1 keep_key=$2 a f
    a="$d/archive/$(stamp)"
    mkdir -p "$a"
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        if [ "$keep_key" = 1 ] && [ "$(basename "$f")" = key.pem ]; then
            cp "$f" "$a/"
            continue
        fi
        mv "$f" "$a/"
    done
    info "Previous certificate material archived: ${a#"$PKI_DIR"/}"
}

# Main issuance function
issue_cert() {
    local d cad subj ocsp="" left
    load_preset "$I_PRESET" || die "Unknown preset '$I_PRESET'. Available presets: $PRESETS"

    if [ "$I_PRESET" = custom ]; then
        [ -n "$I_CUSTOM_KU$I_CUSTOM_EKU" ] || die "Custom preset requires --ku and/or --eku"
        P_KU_RSA=$I_CUSTOM_KU; P_KU_ED=$I_CUSTOM_KU; P_EKU=$I_CUSTOM_EKU
    fi

    [ -z "$I_KEY" ]  && I_KEY=$DEFAULT_LEAF_KEY
    [ -z "$I_DAYS" ] && I_DAYS=$P_DAYS
    [ -z "$I_CA" ]   && I_CA=$DEFAULT_CA
    [ -z "$I_CA" ]   && die "No CA specified and no DEFAULT_CA set (--ca <name>)"
    valid_keytype "$I_KEY" || die "Invalid key type: $I_KEY"
    is_int "$I_DAYS" && [ "$I_DAYS" -gt 0 ] || die "Invalid validity in days: $I_DAYS"

    # Wildcard: construct CN and SANs from --domain
    if [ "$I_PRESET" = wildcard ]; then
        if [ -n "$I_DOMAIN" ]; then
            I_DOMAIN=$(lower "${I_DOMAIN#\*.}")
            I_CN="*.$I_DOMAIN"
        fi
        case $I_CN in
            \*.*) ;;
            *) die "Wildcard certificate requires --domain <domain> or --cn '*.<domain>'" ;;
        esac
        I_DNS=$(add_uniq "$I_DNS" "$(lower "$I_CN")")
        I_DNS=$(add_uniq "$I_DNS" "$(lower "${I_CN#\*.}")")
    fi

    [ -n "$I_CN" ] || die "No Common Name (--cn) specified"
    check_safe "CN" "$I_CN"; check_safe "OU" "$I_OU"
    [ "$I_CN" = "$(trim "$I_CN")" ] || I_CN=$(trim "$I_CN")

    normalize_sans

    case $P_SAN_REQ in
        "dns|ip") [ -n "$I_DNS$I_IP" ] || die "Preset '$I_PRESET' requires at least one DNS or IP SAN (--dns / --ip)" ;;
        email)    [ -n "$I_EMAIL" ]    || die "Preset '$I_PRESET' requires at least one email address (--email)" ;;
    esac

    # Ed25519 compatibility notice
    if [ "$I_KEY" = ed25519 ]; then
        case $I_PRESET in
            server|wildcard|server-client)
                warn "Ed25519 TLS server certificates are NOT supported by standard browsers (Chrome/Firefox/Safari)! Only use for internal APIs, CLI tools, or mutual TLS." ;;
            smime|user)
                warn "Ed25519 does not support key encryption (signatures only). For S/MIME email protection, RSA is recommended." ;;
            vpn-server|vpn-client)
                warn "Ed25519 with IPsec: Standard Windows/macOS built-in clients do not support it. OpenVPN and strongSwan do." ;;
            codesign)
                warn "Ed25519 is not supported by Microsoft Authenticode." ;;
        esac
    fi

    case $I_PRESET in
        server|wildcard|server-client|vpn-server)
            [ "$I_DAYS" -gt 825 ] && warn "Apple (macOS/iOS) rejects TLS server certificates with validity exceeding 825 days." ;;
    esac

    [ -z "$I_NAME" ] && I_NAME=$(name_from_cn "$I_CN")
    I_NAME=$(lower "$I_NAME")
    is_name "$I_NAME" || die "Invalid certificate name '$I_NAME' (allowed: a-z 0-9 . _ @ -)"
    d="$PKI_DIR/issued/$I_NAME"

    # Verify issuing CA
    if [ "$I_CA" != selfsigned ]; then
        ca_exists "$I_CA" || die "CA '$I_CA' does not exist. Available CAs: root $(list_intermediates | tr '\n' ' ')"
        cad=$(ca_dir "$I_CA")
        [ "$I_CA" = root ] && warn "Issuing directly from Root CA - recommended best practice is using an Intermediate CA."
        left=$(cert_days_left "$cad/certs/ca.crt")
        [ "$left" -le 0 ] && die "The issuing CA '$I_CA' has expired!"
        if [ "$I_DAYS" -gt "$left" ]; then
            warn "Certificate validity shortened to CA remaining lifetime: $left days"
            I_DAYS=$left
        fi
        check_name_constraints "$I_CA"
        load_ca_meta "$I_CA"
        ocsp=$M_OCSP_URL
    fi

    if [ -e "$d/cert.pem" ] && [ "$I_RENEW" != 1 ] && [ "$I_FORCE" != 1 ]; then
        die "Certificate '$I_NAME' already exists. Use --force to overwrite or run: pki renew $I_NAME"
    fi

    banner "Issuing Certificate: $I_NAME  [$I_PRESET]"
    kv "Common Name" "$I_CN"
    kv "Issuer"      "$I_CA"
    [ -n "$I_DNS" ]   && kv "DNS SANs"   "$(printf '%s' "$I_DNS"   | sed 's/,/, /g')"
    [ -n "$I_IP" ]    && kv "IP SANs"    "$(printf '%s' "$I_IP"    | sed 's/,/, /g')"
    [ -n "$I_EMAIL" ] && kv "Email"      "$(printf '%s' "$I_EMAIL" | sed 's/,/, /g')"
    [ -n "$I_URI" ]   && kv "URI"        "$(printf '%s' "$I_URI"   | sed 's/,/, /g')"
    if [ -n "$I_CSR_FILE" ]; then
        kv "Key" "Private key remains with requester (external CSR)"
    else
        kv "Key" "$I_KEY, $( [ "$I_KEY_PASS" = yes ] && echo 'encrypted with passphrase' || echo 'unencrypted')"
    fi
    kv "Validity"    "$I_DAYS days"
    printf '\n' >&2

    if [ "$I_KEY_PASS" = yes ]; then
        case $I_PRESET in
            server|wildcard|server-client|vpn-server|ocsp|timestamp)
                warn "Passphrase-encrypted private key: Services like Nginx, Apache, or Docker cannot restart unattended without password entry." ;;
        esac
    fi

    # Resolve passwords in advance
    [ "$I_CA" != selfsigned ] && ca_passin "$I_CA"
    if [ "$I_KEEP_KEY" = 1 ] && [ -f "$d/key.pem" ]; then
        key_passin "$d/key.pem"
    elif [ -z "$I_CSR_FILE" ] && [ "$I_KEY_PASS" = yes ] && [ -z "${PKI_KEY_PASS:-}" ]; then
        new_pass PKI_KEY_PASS "the private key of '$I_NAME'"
    fi
    [ "$I_EXPORT_P12" = yes ] && ensure_p12_pass

    if [ -e "$d/cert.pem" ]; then
        archive_leaf "$d" "$I_KEEP_KEY"
    fi
    mkdir -p "$d"

    STEP_N=0; STEP_TOTAL=5
    step "Input parameters verified"

    # 1) Generate or adopt private key
    if [ -n "$I_CSR_FILE" ]; then
        cp "$I_CSR_FILE" "$d/cert.csr"
        step "External CSR imported"
    else
        if [ "$I_KEEP_KEY" = 1 ] && [ -f "$d/key.pem" ]; then
            step "Reusing existing private key"
        else
            gen_key "$d/key.pem" "$I_KEY" "$I_KEY_PASS" PKI_KEY_PASS
            step "Private key generated ($I_KEY)"
        fi
    fi

    # 2) CSR and Extensions
    subj=$(build_subj "$I_CN" "$I_OU")
    write_leaf_ext "$d/ext.cnf" "$I_CA" "$ocsp"

    if [ "$I_CA" = selfsigned ]; then
        key_passin "$d/key.pem"
        req_selfsign "$d/key.pem" "$subj" "$I_DAYS" "$d/ext.cnf" leaf_ext "$d/cert.pem" "${KPASSIN[@]}" \
            || die "Failed to generate self-signed certificate"
        step "Self-signed certificate created (Serial $(cert_serial "$d/cert.pem"))"
    else
        if [ -z "$I_CSR_FILE" ]; then
            key_passin "$d/key.pem"
            ssl req -new -utf8 -config "$PKI_DIR/.req.cnf" -key "$d/key.pem" "${KPASSIN[@]}" -subj "$subj" -out "$d/cert.csr" \
                || die "CSR generation failed"
        fi
        ca_passin "$I_CA"
        ssl ca -batch -config "$cad/ca.cnf" "${PASSIN[@]}" -extfile "$d/ext.cnf" -extensions leaf_ext \
            -days "$I_DAYS" -notext -preserveDN -utf8 -subj "$subj" -in "$d/cert.csr" -out "$d/cert.pem" \
            || die "Signing by CA '$I_CA' failed"
        step "Signed by CA '$I_CA' (Serial $(cert_serial "$d/cert.pem"))"
    fi

    write_bundles "$d" "$I_CA"
    write_cert_meta "$d/cert.meta" "$d/cert.pem"

    [ "$I_EXPORT_P12" = yes ] && export_p12 "$I_NAME"
    [ "$I_EXPORT_DER" = yes ] && export_der "$I_NAME"
    step "Certificate chains & bundles generated"

    write_howto "$d"
    step "Ready to deploy! Documentation written to GUIDE.txt"

    log_action "ISSUE name=$I_NAME preset=$I_PRESET ca=$I_CA cn='$I_CN' serial=$(cert_serial "$d/cert.pem") dns='$I_DNS' ip='$I_IP' email='$I_EMAIL'"

    print_quick_usage "$d"
}

###############################################################################
# MODULE: lib/csr.sh
###############################################################################
###############################################################################
# lib/csr.sh - External Certificate Signing Request (CSR) Parsing and Signing
###############################################################################

# Reads and validates an external CSR and extracts CN, key type, and SANs
csr_info() {
    local csr=$1 txt
    "$OPENSSL" req -in "$csr" -noout -verify >/dev/null 2>&1 || die "CSR signature is invalid or file is not a valid CSR: $csr"
    CSR_CN=$("$OPENSSL" req -in "$csr" -noout -subject -nameopt multiline,utf8,-esc_msb | awk -F' = ' '/commonName/{print $2; exit}')
    txt=$("$OPENSSL" req -in "$csr" -noout -text)
    CSR_SAN=$(printf '%s\n' "$txt" | awk '/Subject Alternative Name/{getline; print; exit}' | sed 's/^ *//')
    CSR_KEY=$(printf '%s\n' "$txt" | awk -F': ' '/Public Key Algorithm/{print $2; exit}')
    CSR_DNS="" CSR_IP="" CSR_EMAIL="" CSR_URI=""

    local IFS=, e
    for e in $CSR_SAN; do
        e=$(trim "$e")
        case $e in
            DNS:*)          CSR_DNS=$(add_uniq "$CSR_DNS" "${e#DNS:}") ;;
            "IP Address:"*) CSR_IP=$(add_uniq "$CSR_IP" "${e#IP Address:}") ;;
            email:*)        CSR_EMAIL=$(add_uniq "$CSR_EMAIL" "${e#email:}") ;;
            URI:*)          CSR_URI=$(add_uniq "$CSR_URI" "${e#URI:}") ;;
        esac
    done
}

# Signs an external CSR
sign_csr() {
    local csr=$1 kt
    [ -f "$csr" ] || die "CSR file not found: $csr"
    csr_info "$csr"
    info "CSR contains: CN='$CSR_CN' Key=$CSR_KEY SAN='${CSR_SAN:-none}'"
    [ -z "$I_CN" ] && I_CN=$CSR_CN

    if [ "$I_NO_CSR_SAN" != 1 ]; then
        I_DNS="$CSR_DNS${I_DNS:+,$I_DNS}"
        I_IP="$CSR_IP${I_IP:+,$I_IP}"
        I_EMAIL="$CSR_EMAIL${I_EMAIL:+,$I_EMAIL}"
        I_URI="$CSR_URI${I_URI:+,$I_URI}"
    fi

    case $CSR_KEY in
        *ED25519*) kt=ed25519 ;;
        *)         kt=rsa ;;
    esac

    # Set key type for keyUsage compatibility
    I_KEY=$( [ "$kt" = ed25519 ] && echo ed25519 || echo rsa2048 )
    I_CSR_FILE=$csr

    [ "$I_CA" = selfsigned ] && die "An external CSR cannot be self-signed by definition"
    issue_cert
}

###############################################################################
# MODULE: lib/network.sh
###############################################################################
###############################################################################
# lib/network.sh - Hostname/IP Autodetection (DNS, /etc/hosts) & Quick Mode
###############################################################################

# Resolves all IPs for a hostname (excluding loopback 127.x/::1 and link-local fe80:)
lookup_ips() {
    local n=$1 out=""
    if have getent; then
        out=$(with_timeout getent ahosts "$n" 2>/dev/null | awk '{print $1}') || true
    elif have dscacheutil; then
        out=$(with_timeout dscacheutil -q host -a name "$n" 2>/dev/null | awk '/^ip(v6)?_address:/{print $2}') || true
    fi
    if [ -z "$out" ] && have host; then
        out=$(with_timeout host "$n" 2>/dev/null | awk '/has address|has IPv6 address/{print $NF}') || true
    fi
    printf '%s\n' "$out" | awk 'NF && $1 !~ /^127\./ && $1 != "::1" && tolower($1) !~ /^fe80:/' | sort -u
}

# Resolves FQDN for a short name
lookup_fqdn() {
    local n=$1 out=""
    if have getent; then
        out=$(with_timeout getent hosts "$n" 2>/dev/null | awk 'NR==1{for(i=2;i<=NF;i++) if($i ~ /\./){print $i; exit}}') || true
    fi
    if [ -z "$out" ] && have host; then
        out=$(with_timeout host "$n" 2>/dev/null | awk '/has address/{print $1; exit}') || true
    fi
    out=${out%.}
    lower "$out"
}

# Reverse-DNS lookup for an IP address
lookup_ptr() {
    local ip=$1 out=""
    if have getent; then
        out=$(with_timeout getent hosts "$ip" 2>/dev/null | awk 'NR==1{print $2}') || true
    fi
    if [ -z "$out" ] && have host; then
        out=$(with_timeout host "$ip" 2>/dev/null | awk '/domain name pointer/{print $NF; exit}') || true
    fi
    out=${out%.}
    lower "$out"
}

# autodetect <hostname|ip> -> populates AD_CN, AD_DNS, AD_IP
autodetect() {
    local in fq short x
    in=$(lower "$(trim "$1")")
    AD_CN="" AD_DNS="" AD_IP=""

    if is_ipv4 "$in" || is_ipv6 "$in"; then
        AD_IP=$in
        AD_CN=$in
        fq=$(lookup_ptr "$in")
        if [ -n "$fq" ] && is_hostname "$fq"; then
            AD_CN=$fq
            AD_DNS=$fq
            short=${fq%%.*}
            [ "$short" != "$fq" ] && AD_DNS="$AD_DNS,$short"
        fi
        return 0
    fi

    case $in in
        \**) warn "Please generate wildcard certificates using preset 'wildcard'"; return 1 ;;
    esac

    is_hostname "$in" || { warn "Invalid hostname: $in"; return 1; }

    case $in in
        *.*) fq=$in ;;
        *)   fq=$(lookup_fqdn "$in"); case $fq in *.*) ;; *) fq="" ;; esac ;;
    esac

    short=${in%%.*}
    AD_CN=${fq:-$in}
    AD_DNS=$AD_CN
    [ "$short" != "$AD_CN" ] && AD_DNS="$AD_DNS,$short"

    for x in $(lookup_ips "$AD_CN"); do
        AD_IP=$(add_uniq "$AD_IP" "$(lower "$x")")
    done
    return 0
}

# Interactive prompt: Display DNS auto-discovery findings and offer adoption
autodetect_offer() {
    local use
    info "Resolving network configuration for '$I_CN' via DNS ..."
    autodetect "$I_CN" || return 0
    if [ -z "$AD_IP" ] && [ "$AD_DNS" = "$(lower "$I_CN")" ]; then
        info "No additional domain names or IP addresses discovered on the network"
        return 0
    fi

    kv "CN"       "$AD_CN"
    kv "DNS SANs" "$(printf '%s' "$AD_DNS" | sed 's/,/, /g')"
    kv "IP SANs"  "$( [ -n "$AD_IP" ] && printf '%s' "$AD_IP" | sed 's/,/, /g' || echo '(none detected)')"

    ask_yn use "Accept detected network parameters?" y
    if [ "$use" = yes ]; then
        I_CN=$AD_CN
        I_DNS=$AD_DNS
        I_IP=$AD_IP
    fi
    return 0
}

# CLI Quick Mode: Issue server certificate directly from hostname or IP
cmd_quick() {
    local h=${1:-} args=() nolookup=0
    [ -n "$h" ] && shift || die "Usage: pki quick <hostname|ip> [--dns ..] [--ip ..] [--no-lookup]"

    while [ $# -gt 0 ]; do
        case $1 in
            --no-lookup) nolookup=1 ;;
            *)           args+=("$1") ;;
        esac
        shift
    done

    reset_issue_vars
    I_PRESET=server
    [ ${#args[@]} -gt 0 ] && parse_issue_opts "${args[@]}"

    case $(preset_family "$I_PRESET") in
        server|vpnserver) ;;
        *) die "quick command is reserved for server presets (server, server-client, vpn-server)" ;;
    esac

    if [ "$nolookup" = 1 ]; then
        I_CN=${I_CN:-$(lower "$h")}
    else
        autodetect "$h" || die "Network autodetection failed"
        [ -z "$AD_IP" ] && warn "No IP address resolved for '$h' via DNS - specify manually with --ip if required"
        I_CN=${I_CN:-$AD_CN}
        I_DNS="$AD_DNS${I_DNS:+,$I_DNS}"
        I_IP="$AD_IP${I_IP:+,$I_IP}"
    fi

    issue_cert
}

###############################################################################
# MODULE: lib/operations.sh
###############################################################################
###############################################################################
# lib/operations.sh - Certificate Operations: Listing, Verify, Renew, Revoke & CRL
###############################################################################

REVOKE_REASONS="unspecified keyCompromise CACompromise affiliationChanged superseded cessationOfOperation certificateHold"

# Lists all issued leaf certificates
list_issued() {
    local d
    [ -d "$PKI_DIR/issued" ] || return 0
    for d in "$PKI_DIR"/issued/*/; do
        [ -f "$d/cert.meta" ] && basename "$d"
    done
    return 0
}

# Color-formatted status text for certificate lifetime and revocation
status_text() { # <days> <revoked_flag: R>
    if [ "$2" = R ]; then
        printf '%sREVOKED%s' "$C_RED" "$C_RST"
    elif [ "$1" = "?" ]; then
        printf '?'
    elif [ "$1" -lt 0 ]; then
        printf '%sEXPIRED%s' "$C_RED" "$C_RST"
    elif [ "$1" -le "${WARN_DAYS:-30}" ]; then
        printf '%sEXPIRING%s' "$C_YEL" "$C_RST"
    else
        printf '%sOK%s' "$C_GRN" "$C_RST"
    fi
}

# Tabular overview of all CAs and issued certificates
list_all() {
    local n d days st fmt="%-24s %-13s %-12s %-11s %6s  %-10s %s\n"
    require_pki

    printf '%s\n# Certificate Authorities (CAs) in %s\n%s\n' "$HR" "$PKI_DIR" "$HR"
    printf "$fmt" "NAME" "TYPE" "KEY" "VALID UNTIL" "DAYS" "STATUS" "CN"

    for n in root $(list_intermediates); do
        d=$(ca_dir "$n")
        load_ca_meta "$n"
        days=$(cert_days_left "$d/certs/ca.crt")
        st=""
        [ "$n" != root ] && st=$(index_status "$PKI_DIR/root" "$(cert_serial "$d/certs/ca.crt")")
        printf "$fmt" "$n$( [ "$n" = "$DEFAULT_CA" ] && echo '*')" "$M_TYPE" "$M_KEY" "$(cert_end_date "$d/certs/ca.crt")" "$days" "$(status_text "$days" "$st")" "$M_CN"
    done

    printf '\n%s\n# Issued End-Entity Certificates (Leaves)\n%s\n' "$HR" "$HR"
    printf "$fmt" "NAME" "PRESET" "CA" "VALID UNTIL" "DAYS" "STATUS" "CN"

    local total=0 ok_c=0 exp_c=0 rev_c=0
    for n in $(list_issued); do
        total=$((total+1))
        d="$PKI_DIR/issued/$n"
        local pre ca
        pre=$(awk -F'"' '/^PRESET=/{print $2}' "$d/cert.meta")
        ca=$(awk -F'"' '/^CA=/{print $2}' "$d/cert.meta")
        days=$(cert_days_left "$d/cert.pem")
        st=""
        [ "$ca" != selfsigned ] && ca_exists "$ca" && st=$(index_status "$(ca_dir "$ca")" "$(cert_serial "$d/cert.pem")")

        # If issuing parent CA was revoked
        if [ "$ca" != selfsigned ] && [ "$ca" != root ] && ca_exists "$ca" && \
           [ "$(index_status "$PKI_DIR/root" "$(cert_serial "$(ca_dir "$ca")/certs/ca.crt")")" = R ]; then
            st=R
        fi

        if [ "$st" = R ]; then
            rev_c=$((rev_c+1))
        elif [ "$days" != "?" ] && [ "$days" -le "${WARN_DAYS:-30}" ]; then
            exp_c=$((exp_c+1))
        else
            ok_c=$((ok_c+1))
        fi

        printf "$fmt" "$n" "$pre" "$ca" "$(cert_end_date "$d/cert.pem")" "$days" "$(status_text "$days" "$st")" "$(cert_cn "$d/cert.pem")"
    done

    printf '\n  Total: %s certificates (%s%s valid%s, %s%s expiring soon%s, %s%s revoked%s)  |  * = DEFAULT_CA\n\n' \
        "$total" "$C_GRN" "$ok_c" "$C_RST" "$C_YEL" "$exp_c" "$C_RST" "$C_RED" "$rev_c" "$C_RST"
}

# Filters certificates by Name, CN, IP, SAN, Preset, or Serial
search_certs() {
    local query=$1 n d pre ca cn dns ip serial found=0
    [ -n "$query" ] || die "Usage: pki search <query>"
    require_pki
    query=$(lower "$query")

    banner "Search Results for: '$query'"
    local fmt="%-22s %-12s %-12s %-10s %s\n"
    printf "$fmt" "NAME" "PRESET" "CA" "DAYS LEFT" "COMMON NAME / DETAILS"

    for n in $(list_issued); do
        d="$PKI_DIR/issued/$n"
        pre=$(awk -F'"' '/^PRESET=/{print $2}' "$d/cert.meta")
        ca=$(awk -F'"' '/^CA=/{print $2}' "$d/cert.meta")
        cn=$(awk -F'"' '/^CN=/{print $2}' "$d/cert.meta")
        dns=$(awk -F'"' '/^DNS=/{print $2}' "$d/cert.meta")
        ip=$(awk -F'"' '/^IP=/{print $2}' "$d/cert.meta")
        serial=$(cert_serial "$d/cert.pem" 2>/dev/null || true)

        local haystack
        haystack=$(lower "$n $pre $ca $cn $dns $ip $serial")
        if [[ $haystack == *"$query"* ]]; then
            found=$((found+1))
            local days; days=$(cert_days_left "$d/cert.pem")
            printf "$fmt" "$n" "$pre" "$ca" "$days" "$cn $( [ -n "$dns" ] && echo "[$dns]" )"
        fi
    done

    [ "$found" -eq 0 ] && info "No matching certificates found for '$query'"
    printf '\n'
}

# Checks expiry dates for monitoring/cron (Exit code 2 when any certificate/CRL expires soon)
check_all() {
    local warn_days=${1:-$WARN_DAYS} n d days st bad=0 ca next e
    require_pki

    for n in root $(list_intermediates); do
        d=$(ca_dir "$n")
        days=$(cert_days_left "$d/certs/ca.crt")
        if [ "$days" -le "$warn_days" ]; then
            printf 'CA   %-22s %5s days remaining\n' "$n" "$days"
            bad=1
        fi
        if [ -f "$d/crl/ca.crl" ]; then
            next=$("$OPENSSL" crl -in "$d/crl/ca.crl" -noout -nextupdate -dateopt iso_8601 | cut -d= -f2)
            e=$(to_epoch "${next%Z}")
            days=$(( (e - $(date -u +%s)) / 86400 ))
            if [ "$days" -le 7 ]; then
                printf 'CRL  %-22s %5s days  -> pki crl --ca %s\n' "$n" "$days" "$n"
                bad=1
            fi
        fi
    done

    for n in $(list_issued); do
        d="$PKI_DIR/issued/$n"
        ca=$(awk -F'"' '/^CA=/{print $2}' "$d/cert.meta")
        st=""
        [ "$ca" != selfsigned ] && ca_exists "$ca" && st=$(index_status "$(ca_dir "$ca")" "$(cert_serial "$d/cert.pem")")
        [ "$st" = R ] && continue

        days=$(cert_days_left "$d/cert.pem")
        if [ "$days" -le "$warn_days" ]; then
            printf 'CERT %-22s %5s days  -> pki renew %s\n' "$n" "$days" "$n"
            bad=1
        fi
    done

    if [ "$bad" = 0 ]; then
        ok "All certificates and CRLs are valid (warning threshold: $warn_days days)"
        return 0
    fi
    return 2
}

# Resolves a name or path to a certificate file
resolve_cert() {
    if [ -f "$1" ]; then
        printf '%s' "$1"
    elif [ "$1" = root ]; then
        printf '%s' "$PKI_DIR/root/certs/ca.crt"
    elif [ -f "$PKI_DIR/intermediate/$1/certs/ca.crt" ]; then
        printf '%s' "$PKI_DIR/intermediate/$1/certs/ca.crt"
    elif [ -f "$PKI_DIR/issued/$1/cert.pem" ]; then
        printf '%s' "$PKI_DIR/issued/$1/cert.pem"
    else
        die "Certificate not found: '$1' (neither as certificate name nor file path)"
    fi
}

# Displays certificate details
show_cert() {
    local f
    f=$(resolve_cert "$1")

    if [ "${2:-}" = full ]; then
        "$OPENSSL" x509 -in "$f" -noout -text
        return
    fi

    banner "Certificate Details: $f"
    "$OPENSSL" x509 -in "$f" -noout -nameopt utf8,sep_comma_plus_space -subject -issuer -serial \
        -startdate -enddate -dateopt iso_8601
    printf 'Remaining days : %s days\n' "$(cert_days_left "$f")"
    "$OPENSSL" x509 -in "$f" -noout -text | awk '/Public Key Algorithm|Public-Key:/{sub(/^ +/,""); print}'
    "$OPENSSL" x509 -in "$f" -noout -ext basicConstraints,keyUsage,extendedKeyUsage,subjectAltName,nameConstraints,crlDistributionPoints,authorityInfoAccess 2>/dev/null || true
    printf 'SHA-256 Fingerprint: %s\n' "$(cert_fingerprint "$f")"
}

# Validates chain, revocation status, keyUsage/purpose, and private key match
verify_cert() {
    local name=$1 host=${2:-} d="$PKI_DIR/issued/$1" f ca pre crls args=() rc=0

    if [ ! -f "$d/cert.pem" ]; then
        # Verification of a CA
        f=$(resolve_cert "$name")
        "$OPENSSL" verify -CAfile "$PKI_DIR/root/certs/ca.crt" "$f" && return 0 || return 1
    fi

    f="$d/cert.pem"
    ca=$(awk -F'"' '/^CA=/{print $2}' "$d/cert.meta")
    pre=$(awk -F'"' '/^PRESET=/{print $2}' "$d/cert.meta")
    load_preset "$pre"

    banner "Certificate Verification (Verify): $name"

    if [ "$ca" = selfsigned ]; then
        args=(-CAfile "$f" -partial_chain)
    else
        args=(-CAfile "$PKI_DIR/root/certs/ca.crt")
        [ -s "$d/chain.pem" ] && args+=(-untrusted "$d/chain.pem")
        crls=$(mktemp)
        cat "$PKI_DIR/root/crl/ca.crl" > "$crls"
        [ "$ca" != root ] && cat "$(ca_dir "$ca")/crl/ca.crl" >> "$crls"
        args+=(-crl_check_all -CRLfile "$crls")
    fi

    [ "$P_PURPOSE" != any ] && args+=(-purpose "$P_PURPOSE")
    if [ -n "$host" ]; then
        if is_ipv4 "$host" || is_ipv6 "$host"; then
            args+=(-verify_ip "$host")
        else
            args+=(-verify_hostname "$(lower "$host")")
        fi
    fi

    if "$OPENSSL" verify "${args[@]}" "$f"; then
        ok "Certificate chain, CRL revocation status${host:+, hostname '$host'} and purpose ($P_PURPOSE) are VALID"
    else
        err "Verification failed"
        rc=1
    fi
    [ -n "${crls:-}" ] && rm -f "$crls"

    if [ -f "$d/key.pem" ]; then
        if key_is_encrypted "$d/key.pem" && [ -z "${PKI_KEY_PASS:-}" ] && [ ! -t 0 ]; then
            info "Private key is passphrase-protected - key matching check skipped in non-interactive shell"
        else
            key_passin "$d/key.pem"
            if [ "$("$OPENSSL" pkey -in "$d/key.pem" "${KPASSIN[@]}" -pubout 2>/dev/null)" = "$("$OPENSSL" x509 -in "$f" -noout -pubkey)" ]; then
                ok "Private key matches certificate exactly (Public Key Match)"
            else
                err "Private key does NOT match certificate!"
                rc=1
            fi
        fi
    fi
    return $rc
}

# Re-issues a leaf certificate reusing existing parameters from cert.meta
renew_cert() {
    local name=$1 d="$PKI_DIR/issued/$1" old_serial old_ca keep=$I_KEEP_KEY revoke_old=$R_REVOKE_OLD days=$I_DAYS
    [ -f "$d/cert.meta" ] || die "No certificate '$name' or cert.meta file found"
    old_serial=$(cert_serial "$d/cert.pem")

    reset_issue_vars
    # shellcheck disable=SC2086
    load_kv "$d/cert.meta" I_ $I_KEYS SERIAL ISSUED
    old_ca=$I_CA
    [ -n "$days" ] && I_DAYS=$days
    I_KEEP_KEY=$keep
    I_RENEW=1

    [ -f "$d/key.pem" ] || die "No private key available (external CSR) - sign a new CSR with 'pki sign-csr'"

    if [ "$I_EXPORT_P12" = yes ] && [ -z "${PKI_P12_PASS:-}" ] && [ ! -t 0 ]; then
        warn "PKI_P12_PASS not set - .p12 export will not be regenerated (run later: pki export $name)"
        I_EXPORT_P12=no
    fi

    issue_cert

    if [ "$revoke_old" = 1 ] && [ "$old_ca" != selfsigned ]; then
        local cad; cad=$(ca_dir "$old_ca")
        ca_passin "$old_ca"
        if [ -f "$cad/newcerts/$old_serial.pem" ]; then
            ssl ca -config "$cad/ca.cnf" "${PASSIN[@]}" -revoke "$cad/newcerts/$old_serial.pem" -crl_reason superseded \
                && ok "Previous certificate ($old_serial) revoked as 'superseded'" \
                && gen_crl "$old_ca"
        else
            warn "Previous certificate not found in newcerts/ - revocation skipped"
        fi
    fi
    log_action "RENEW name=$name old_serial=$old_serial keep_key=$keep"
}

# Renews a CA retaining the identical private key (all issued certificates remain valid!)
renew_ca() {
    local ca=$1 d days=$2 a n
    ca_exists "$ca" || die "CA '$ca' does not exist"
    d=$(ca_dir "$ca")
    load_ca_meta "$ca"

    [ -z "$days" ] && { if [ "$ca" = root ]; then days=$ROOT_DAYS; else days=$INTERMEDIATE_DAYS; fi; }
    a="$d/archive/$(stamp)"
    mkdir -p "$a"
    cp "$d/certs/ca.crt" "$a/"

    banner "Renew CA: $ca (retaining original private key)"
    ca_passin "$ca"

    if [ "$ca" = root ]; then
        req_selfsign "$d/private/ca.key" "$M_SUBJECT" "$days" "$d/ext.cnf" v3_root "$d/certs/ca.crt.new" "${PASSIN[@]}" \
            || die "Root CA renewal failed"
        mv "$d/certs/ca.crt.new" "$d/certs/ca.crt"
        chmod 644 "$d/certs/ca.crt"
        for n in $(list_intermediates); do
            cat "$(ca_dir "$n")/certs/ca.crt" "$d/certs/ca.crt" > "$(ca_dir "$n")/certs/chain.pem"
        done
        warn "New Root CA certificate must be redistributed to trust stores (publish/root.crt) - certificate thumbprint has changed!"
    else
        local left; left=$(cert_days_left "$PKI_DIR/root/certs/ca.crt")
        [ "$days" -gt "$left" ] && { warn "Validity shortened to Root CA remaining lifetime: $left days"; days=$left; }
        ssl req -new -utf8 -config "$PKI_DIR/.req.cnf" -key "$d/private/ca.key" "${PASSIN[@]}" -subj "$M_SUBJECT" -out "$d/ca.csr" \
            || die "CSR creation for CA failed"
        ca_passin root
        ssl ca -batch -config "$PKI_DIR/root/ca.cnf" "${PASSIN[@]}" -extfile "$d/ext.cnf" -extensions v3_intermediate \
            -days "$days" -notext -preserveDN -in "$d/ca.csr" -out "$d/certs/ca.crt.new" || die "Signing updated Intermediate CA failed"
        mv "$d/certs/ca.crt.new" "$d/certs/ca.crt"
        chmod 644 "$d/certs/ca.crt"
        cat "$d/certs/ca.crt" "$PKI_DIR/root/certs/ca.crt" > "$d/certs/chain.pem"
    fi

    publish_ca "$ca"

    # Update certificate bundles of all affected issued certificates
    for n in $(list_issued); do
        local lca; lca=$(awk -F'"' '/^CA=/{print $2}' "$PKI_DIR/issued/$n/cert.meta")
        if [ "$lca" = "$ca" ] || { [ "$ca" = root ] && [ "$lca" != selfsigned ]; }; then
            write_bundles "$PKI_DIR/issued/$n" "$lca"
            [ -f "$PKI_DIR/issued/$n/cert.p12" ] && warn "$n: cert.p12 contains previous certificate chain -> run 'pki export $n'"
        fi
    done

    log_action "RENEW-CA ca=$ca days=$days"
    ok "CA '$ca' renewed successfully, valid until $(cert_end_date "$d/certs/ca.crt")"
}

# Generates a fresh Certificate Revocation List (CRL) for a CA
gen_crl() {
    local ca=$1 d
    d=$(ca_dir "$1")
    ca_passin "$ca"
    ssl ca -config "$d/ca.cnf" "${PASSIN[@]}" -gencrl -crldays "${CRL_DAYS:-30}" -out "$d/crl/ca.crl" \
        || die "CRL generation for '$ca' failed"
    chmod 644 "$d/crl/ca.crl"
    publish_ca "$ca"
    log_action "CRL generated ca=$ca"
    ok "CRL for CA '$ca' generated (next update due: $("$OPENSSL" crl -in "$d/crl/ca.crl" -noout -nextupdate -dateopt iso_8601 | cut -d= -f2))"
}

# Revokes a certificate or an Intermediate CA
revoke_cert() {
    local name=$1 reason=${2:-unspecified} cert issuer st
    case " $REVOKE_REASONS " in
        *" $reason "*) ;;
        *) die "Invalid revocation reason '$reason'. Allowed: $REVOKE_REASONS" ;;
    esac

    if [ -f "$PKI_DIR/issued/$name/cert.pem" ]; then
        cert="$PKI_DIR/issued/$name/cert.pem"
        issuer=$(awk -F'"' '/^CA=/{print $2}' "$PKI_DIR/issued/$name/cert.meta")
    elif [ -f "$PKI_DIR/intermediate/$name/certs/ca.crt" ]; then
        cert="$PKI_DIR/intermediate/$name/certs/ca.crt"
        issuer=root
        warn "Attention: You are revoking an INTERMEDIATE CA! All certificates signed by this CA will become invalid!"
    else
        die "No certificate or CA found named '$name'"
    fi

    [ "$issuer" = selfsigned ] && die "Self-signed certificates cannot be revoked (no CA CRL infrastructure)"
    st=$(index_status "$(ca_dir "$issuer")" "$(cert_serial "$cert")")
    [ "$st" = R ] && die "'$name' is already revoked"
    [ -z "$st" ] && die "'$name' was not found in database of CA '$issuer'"

    if [ "$INTERACTIVE" = 1 ] || [ "$ASSUME_YES" != 1 ]; then
        confirm "Really revoke '$name' (Serial $(cert_serial "$cert"))? Reason: $reason" || { info "Cancelled"; return 0; }
    fi

    ca_passin "$issuer"
    ssl ca -config "$(ca_dir "$issuer")/ca.cnf" "${PASSIN[@]}" -revoke "$cert" -crl_reason "$reason" \
        || die "Revocation command failed in OpenSSL"

    log_action "REVOKE name=$name ca=$issuer reason=$reason serial=$(cert_serial "$cert")"
    ok "Certificate '$name' successfully revoked (Reason: $reason)"
    gen_crl "$issuer"
    info "CRL was regenerated and published to publish/."
}

###############################################################################
# MODULE: lib/export.sh
###############################################################################
###############################################################################
# lib/export.sh - Certificate Exports (PKCS#12, DER) & Deployment Guide Generator
###############################################################################

# Exports certificate, private key, and chain to PKCS#12 (.p12)
export_p12() {
    local name=$1 d="$PKI_DIR/issued/$1" passout=() legacy=${2:-$I_P12_LEGACY}
    [ -f "$d/key.pem" ] || { warn "No private key found for '$name' (external CSR?) - PKCS#12 export not possible"; return 0; }

    key_passin "$d/key.pem"
    ensure_p12_pass
    passout=(-passout env:PKI_P12_PASS)

    if [ -s "$d/ca-bundle.pem" ] && ! cmp -s "$d/ca-bundle.pem" "$d/cert.pem"; then
        ssl pkcs12 -export -in "$d/cert.pem" -inkey "$d/key.pem" "${KPASSIN[@]}" -certfile "$d/ca-bundle.pem" \
            -name "$name" "${passout[@]}" -out "$d/cert.p12" || die "PKCS#12 export failed"
    else
        ssl pkcs12 -export -in "$d/cert.pem" -inkey "$d/key.pem" "${KPASSIN[@]}" \
            -name "$name" "${passout[@]}" -out "$d/cert.p12" || die "PKCS#12 export failed"
    fi
    chmod 600 "$d/cert.p12"
    ok "PKCS#12 file created: cert.p12 (AES-256/PBKDF2 with complete chain)"

    if [ "$legacy" = yes ]; then
        ssl pkcs12 -export -in "$d/cert.pem" -inkey "$d/key.pem" "${KPASSIN[@]}" -certfile "$d/ca-bundle.pem" \
            -name "$name" "${passout[@]}" -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 \
            -out "$d/cert-legacy.p12" || die "Legacy PKCS#12 export failed"
        chmod 600 "$d/cert-legacy.p12"
        ok "Legacy PKCS#12 created: cert-legacy.p12 (3DES/SHA1 for legacy appliances/Windows)"
    fi
}

# Exports certificate in binary DER format (.der)
export_der() {
    local d="$PKI_DIR/issued/$1"
    "$OPENSSL" x509 -in "$d/cert.pem" -outform der -out "$d/cert.der"
    chmod 644 "$d/cert.der"
    ok "DER format created: cert.der"
}

# Displays all available files in a certificate directory
print_leaf_files() {
    local d=$1 f
    section "Files in ${d#"$PWD"/}"
    for f in key.pem cert.pem chain.pem fullchain.pem ca-bundle.pem combined.pem cert.p12 cert-legacy.p12 cert.der cert.csr ext.cnf cert.meta; do
        [ -e "$d/$f" ] || continue
        case $f in
            key.pem)         printf '  %-16s private key - KEEP STRICTLY CONFIDENTIAL\n' "$f" >&2 ;;
            cert.pem)        printf '  %-16s certificate only (end-entity)\n' "$f" >&2 ;;
            chain.pem)       [ -s "$d/$f" ] && printf '  %-16s intermediate certificate(s) (without root)\n' "$f" >&2 ;;
            fullchain.pem)   printf '  %-16s certificate + intermediate (for Nginx, Traefik, Caddy, Apache)\n' "$f" >&2 ;;
            ca-bundle.pem)   printf '  %-16s intermediate + root (for trust stores, mTLS client validation)\n' "$f" >&2 ;;
            combined.pem)    printf '  %-16s private key + fullchain in a single file (for HAProxy)\n' "$f" >&2 ;;
            cert.p12)        printf '  %-16s PKCS#12 bundle (Windows, macOS, browser, email client)\n' "$f" >&2 ;;
            cert-legacy.p12) printf '  %-16s PKCS#12 3DES/SHA1 for legacy systems and appliances\n' "$f" >&2 ;;
            cert.der)        printf '  %-16s binary DER format certificate\n' "$f" >&2 ;;
            cert.csr)        printf '  %-16s Certificate Signing Request (CSR)\n' "$f" >&2 ;;
            ext.cnf)         printf '  %-16s X.509 extensions configuration used\n' "$f" >&2 ;;
            cert.meta)       printf '  %-16s metadata and reproducible template for renewals\n' "$f" >&2 ;;
        esac
    done
    load_preset "$(awk -F'"' '/^PRESET=/{print $2}' "$d/cert.meta" 2>/dev/null)" 2>/dev/null && [ -n "$P_USE" ] && printf '\n  Intended usage: %s\n' "$P_USE" >&2
    return 0
}

# Maps preset families to common services and recommended files
usage_rows() {
    local p=$1
    case $(preset_family "$p") in
        server)
            echo "Nginx / Traefik / Caddy|fullchain.pem + key.pem"
            echo "Apache HTTPD (>= 2.4.8)|fullchain.pem + key.pem"
            echo "HAProxy|combined.pem"
            echo "Proxmox VE (Web GUI)|fullchain.pem + key.pem"
            echo "TrueNAS CORE / SCALE|fullchain.pem + key.pem"
            echo "UniFi OS (UDM / CloudKey)|fullchain.pem + key.pem"
            echo "UniFi Network App (Linux)|cert.p12"
            echo "Windows / IIS Web Server|cert.p12"
            echo "Docker Containers|fullchain.pem + key.pem (mounted :ro)"
            ;;
        vpnserver)
            echo "OpenVPN Server|cert.pem + key.pem + chain.pem"
            echo "strongSwan (swanctl)|cert.pem + key.pem + chain.pem"
            echo "Windows RRAS (VPN Server)|cert.p12"
            ;;
        client)
            if [ "$p" = vpn-client ]; then echo "OpenVPN Client (.ovpn)|cert.pem + key.pem (+ ca-bundle.pem)"; fi
            echo "Windows / macOS / Browser|cert.p12"
            if [ "$p" = user ] || [ "$p" = smime ]; then echo "Email Client (S/MIME)|cert.p12"; fi
            if [ "$p" = vpn-client ]; then echo "Windows/macOS IKEv2|cert.p12"; fi
            echo "curl / Scripts / REST APIs|cert.pem + key.pem"
            echo "802.1X EAP-TLS (WiFi/Switch)|cert.p12 (OS) or cert.pem + key.pem (wpa_supplicant)"
            ;;
        codesign)
            echo "PowerShell (Authenticode)|cert.p12"
            echo "osslsigncode / openssl cms|fullchain.pem + key.pem"
            ;;
        ocsp)
            echo "OCSP Responder Daemon|cert.pem + key.pem"
            ;;
        timestamp)
            echo "TSA (RFC 3161 openssl ts)|cert.pem + key.pem + chain.pem"
            ;;
        custom)
            echo "Linux Services|fullchain.pem + key.pem"
            echo "Windows / GUI Clients|cert.p12"
            ;;
    esac
    case $(preset_family "$p") in
        server|vpnserver|custom) echo "Client Trust (Install Root CA)|publish/root.pem (once per client device)" ;;
        client) echo "Server Client Verification (mTLS)|ca-bundle.pem (CA trust chain)" ;;
    esac
}

# Quick summary printed directly after certificate issuance
print_quick_usage() {
    local d=$1 name pre what files hint
    name=$(basename "$d")
    pre=$(meta_get "$d" PRESET)

    section "Successfully issued: ${d#"$PKI_DIR"/} (valid until $(cert_end_date "$d/cert.pem"))"
    printf '\n  %s%-32s %s%s\n' "$C_BLD" "USAGE / SERVICE" "RECOMMENDED FILES" "$C_RST" >&2
    while IFS='|' read -r what files; do
        hint=""
        case $files in *cert.p12*) [ -f "$d/cert.p12" ] || hint="  (export with: pki export $name --p12)";; esac
        printf '  %-32s %s%s%s%s\n' "$what" "$files" "$C_YEL" "$hint" "$C_RST" >&2
    done < <(usage_rows "$pre")
    printf '\n' >&2

    if [ ! -f "$d/key.pem" ]; then
        info "Private key retained by requester (external CSR)."
    elif key_is_encrypted "$d/key.pem"; then
        warn "key.pem is password-protected. For unattended daemons create an unencrypted copy: openssl pkey -in key.pem -out key-plain.pem"
    fi
    printf '  Deployment Guide  :  %s\n' "${d#"$PWD"/}/GUIDE.txt" >&2
    printf '  Verify Certificate:  pki verify %s\n\n' "$name" >&2
}

HOWTO_N=0
howto_sec() {
    HOWTO_N=$((HOWTO_N+1))
    printf '\n%s\n# %s. %s\n%s\n' "$HR" "$HOWTO_N" "$1" "$HR"
}

# Writes detailed, tailored deployment documentation (GUIDE.txt & ANLEITUNG.txt)
write_howto() {
    local d=$1 f="$1/GUIDE.txt" fanl="$1/ANLEITUNG.txt" name pre ca cn dns ip fam host tgt root rootder enc=no
    local srvnames="" main="" aliases="" caddyhost x what files clientca orgslug script_cmd
    name=$(basename "$d")
    pre=$(meta_get "$d" PRESET)
    ca=$(meta_get "$d" CA)
    cn=$(meta_get "$d" CN)
    dns=$(meta_get "$d" DNS)
    ip=$(meta_get "$d" IP)
    fam=$(preset_family "$pre")
    root="$PKI_DIR/publish/root.pem"
    rootder="$PKI_DIR/publish/root.crt"
    tgt="/etc/ssl/$name"
    key_is_encrypted "$d/key.pem" && enc=yes
    orgslug=$(name_from_cn "${PKI_ORG:-pki}")
    script_cmd="${SCRIPT_PATH:-pki}"

    # Prepare names for server configurations
    split_list "$dns"
    for x in "${SPLIT[@]}"; do
        srvnames="${srvnames:+$srvnames }$x"
        caddyhost="${caddyhost:+$caddyhost, }$x"
        case $x in \**) ;; *) if [ -z "$main" ]; then main=$x; continue; fi ;; esac
        aliases="${aliases:+$aliases }$x"
    done
    split_list "$ip"
    for x in "${SPLIT[@]}"; do caddyhost="${caddyhost:+$caddyhost, }$x"; done
    [ -z "$main" ] && main=$cn
    [ -z "$srvnames" ] && srvnames=$cn
    [ -z "$caddyhost" ] && caddyhost=$cn
    host=$main; [ "$pre" = wildcard ] && host="my-server"
    [ -z "$host" ] && host="my-server"
    clientca=$(list_intermediates | grep -i client | head -n1)
    [ -z "$clientca" ] && clientca="<client-ca>"

    HOWTO_N=0
    {
        printf '%s\n# DEPLOYMENT GUIDE & INTEGRATION FOR: %s\n%s\n' "$HR" "$name" "$HR"
        printf '#\n'
        printf '#  Preset       : %s\n' "$pre"
        printf '#  Common Name  : %s\n' "$cn"
        [ -n "$dns" ] && printf '#  DNS SANs     : %s\n' "$(printf '%s' "$dns" | sed 's/,/, /g')"
        [ -n "$ip" ]  && printf '#  IP SANs      : %s\n' "$(printf '%s' "$ip" | sed 's/,/, /g')"
        printf '#  Issuer CA    : %s\n' "$ca"
        printf '#  Valid Until  : %s\n' "$(cert_end_date "$d/cert.pem")"
        printf '#  Directory    : %s\n' "$d"
        printf '#\n#  Generated on %s by pki.sh %s. Updated automatically on "pki renew".\n' "$(now)" "$VERSION"
        printf '#  Note: Paths in examples are standard conventions; adjust for your environment.\n'

        howto_sec "Which file for which purpose?"
        while IFS='|' read -r what files; do printf '  %-32s %s\n' "$what" "$files"; done < <(usage_rows "$pre")
        cat <<EOF

  Files in this directory:
    key.pem          Private key - KEEP CONFIDENTIAL, readable only by daemon
    cert.pem         Leaf certificate only
    chain.pem        Intermediate CA certificate(s) without Root
    fullchain.pem    Leaf + Intermediate            <- Standard for Nginx, Apache, Traefik, Caddy
    ca-bundle.pem    Intermediate + Root             <- For validating peers / client trust
    combined.pem     Private key + fullchain in one  <- HAProxy
    cert.p12         PKCS#12 bundle with password    <- Windows, macOS, browser, email client
EOF

        if [ "$enc" = yes ]; then
            howto_sec "IMPORTANT: key.pem is password-protected"
            cat <<EOF
  Services such as Nginx, Apache, Proxmox, or Docker cannot unlock an encrypted key
  during unattended boot. Generate an unencrypted copy:

    openssl pkey -in $d/key.pem -out $d/key-plain.pem && chmod 600 $d/key-plain.pem

  Then reference 'key-plain.pem' in your service configuration.
EOF
        fi

        case $fam in
        server)
            howto_sec "Step 1: Copy certificates to target server"
            cat <<EOF
  Copy to remote server via SSH / SCP:
    ssh root@$host 'mkdir -p $tgt'
    scp $d/fullchain.pem $d/key.pem $d/combined.pem root@$host:$tgt/
    ssh root@$host 'chmod 644 $tgt/fullchain.pem && chmod 600 $tgt/key.pem $tgt/combined.pem'

  Local usage on this server:
    sudo mkdir -p $tgt
    sudo cp $d/{fullchain,key,combined}.pem $tgt/
    sudo chmod 644 $tgt/fullchain.pem && sudo chmod 600 $tgt/key.pem $tgt/combined.pem
EOF
            howto_sec "Nginx Configuration"
            cat <<EOF
  server {
      listen 443 ssl;
      listen [::]:443 ssl;
      http2 on;
      server_name $srvnames;

      ssl_certificate     $tgt/fullchain.pem;
      ssl_certificate_key $tgt/key.pem;
      ssl_protocols       TLSv1.2 TLSv1.3;

      location / {
          proxy_pass http://127.0.0.1:8080;
      }
  }

  Test syntax and reload:
    nginx -t && systemctl reload nginx
EOF
            howto_sec "Apache HTTPD Configuration"
            cat <<EOF
  <VirtualHost *:443>
      ServerName  $main
$( [ -n "$aliases" ] && printf '      ServerAlias %s\n' "$aliases" )
      SSLEngine on
      SSLCertificateFile    $tgt/fullchain.pem
      SSLCertificateKeyFile $tgt/key.pem
      SSLProtocol -all +TLSv1.2 +TLSv1.3
  </VirtualHost>

  Test syntax and reload:
    apachectl configtest && systemctl reload apache2
EOF
            howto_sec "HAProxy Configuration"
            cat <<EOF
  mkdir -p /etc/haproxy/certs
  cp $tgt/combined.pem /etc/haproxy/certs/$name.pem && chmod 600 /etc/haproxy/certs/$name.pem

  frontend https
      bind :443 ssl crt /etc/haproxy/certs/$name.pem alpn h2,http/1.1
      default_backend app_servers

  Test syntax and reload:
    haproxy -c -f /etc/haproxy/haproxy.cfg && systemctl reload haproxy
EOF
            howto_sec "Traefik (Docker Compose)"
            cat <<EOF
  services:
    traefik:
      image: traefik:v3
      ports: ["443:443"]
      command:
        - --entrypoints.websecure.address=:443
        - --providers.file.filename=/etc/traefik/dynamic.yml
      volumes:
        - $tgt:/certs:ro
        - ./dynamic.yml:/etc/traefik/dynamic.yml:ro

  # dynamic.yml
  tls:
    certificates:
      - certFile: /certs/fullchain.pem
        keyFile:  /certs/key.pem
EOF
            howto_sec "Caddy Web Server"
            cat <<EOF
  $caddyhost {
      tls $tgt/fullchain.pem $tgt/key.pem
      reverse_proxy 127.0.0.1:8080
  }

  chown root:caddy $tgt/key.pem && chmod 640 $tgt/key.pem
  caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy
EOF
            howto_sec "Proxmox VE (Web GUI)"
            cat <<EOF
  Option A - Shell (standard file locations):
    scp $d/fullchain.pem root@$host:/etc/pve/local/pveproxy-ssl.pem
    scp $d/key.pem       root@$host:/etc/pve/local/pveproxy-ssl.key
    ssh root@$host 'systemctl restart pveproxy'

  Option B - Web GUI:
    Datacenter > Node > System > Certificates > "Upload Custom Certificate"
    - Private Key        = content of key.pem
    - Certificate Chain  = content of fullchain.pem
EOF
            howto_sec "TrueNAS CORE / SCALE"
            cat <<EOF
  1. Credentials > Certificates > Certificate Authorities > Add (Import CA):
     Paste content of $root.
  2. Credentials > Certificates > Certificates > Add (Import Certificate):
     - Certificate = content of fullchain.pem
     - Private Key = content of key.pem
  3. System > General > GUI > Set "GUI SSL Certificate" to the newly imported certificate.
EOF
            howto_sec "UniFi OS (UDM / Gateway / CloudKey)"
            cat <<EOF
  SSH to UniFi Console:
    scp $d/fullchain.pem root@$host:/data/unifi-core/config/unifi-core.crt
    scp $d/key.pem       root@$host:/data/unifi-core/config/unifi-core.key
    ssh root@$host 'systemctl restart unifi-core'
EOF
            howto_sec "Windows Server / IIS"
            cat <<EOF
  PowerShell as Administrator:
    \$pw = Read-Host "P12 Password" -AsSecureString
    Import-PfxCertificate -FilePath .\\cert.p12 -CertStoreLocation Cert:\\LocalMachine\\My -Password \$pw
    Import-Certificate    -FilePath .\\root.crt -CertStoreLocation Cert:\\LocalMachine\\Root

  In IIS Manager: Site > Bindings > https > select SSL certificate "$cn".
EOF
            ;;
        vpnserver)
            howto_sec "OpenVPN Server"
            cat <<EOF
  Deploy files:
    cp $d/cert.pem  /etc/openvpn/server/$name.crt
    cp $d/key.pem   /etc/openvpn/server/$name.key && chmod 600 /etc/openvpn/server/$name.key
    cp $d/chain.pem /etc/openvpn/server/chain.pem
    cp $PKI_DIR/intermediate/$clientca/certs/chain.pem /etc/openvpn/server/ca.pem
    cp $PKI_DIR/publish/$clientca.crl.pem /etc/openvpn/server/crl.pem

  In /etc/openvpn/server/server.conf:
    ca          /etc/openvpn/server/ca.pem
    cert        /etc/openvpn/server/$name.crt
    key         /etc/openvpn/server/$name.key
    extra-certs /etc/openvpn/server/chain.pem
    crl-verify  /etc/openvpn/server/crl.pem
    remote-cert-tls client
EOF
            howto_sec "strongSwan (swanctl)"
            cat <<EOF
  cp $d/cert.pem  /etc/swanctl/x509/$name.pem
  cp $d/key.pem   /etc/swanctl/private/$name.key && chmod 600 /etc/swanctl/private/$name.key
  cp $d/chain.pem /etc/swanctl/x509ca/$ca.pem
  cp $root        /etc/swanctl/x509ca/root.pem
  swanctl --load-all
EOF
            ;;
        client)
            howto_sec "Importing Client Certificate"
            cat <<EOF
  Windows:
    Double click 'cert.p12' > Current User > enter password.
    To trust the Root CA: double click 'root.crt' > Trusted Root Certification Authorities.

  macOS:
    security import $d/cert.p12 -k ~/Library/Keychains/login.keychain-db
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $root

  Linux (curl / mTLS):
    curl --cert $d/cert.pem --key $d/key.pem --cacert $root https://$main/

  802.1X EAP-TLS (Network Authentication):
    - Windows: Certificate imported in Personal store, WiFi configured with EAP-TLS.
    - Linux wpa_supplicant.conf:
        eap=TLS
        identity="$cn"
        ca_cert="$root"
        client_cert="$d/cert.pem"
        private_key="$d/key.pem"
EOF
            ;;
        codesign)
            howto_sec "Code Signing Usage"
            cat <<EOF
  PowerShell script signing:
    \$cert = Get-PfxCertificate -FilePath .\\cert.p12
    Set-AuthenticodeSignature -FilePath .\\script.ps1 -Certificate \$cert -HashAlgorithm SHA256

  Linux / binary signing:
    osslsigncode sign -certs $d/fullchain.pem -key $d/key.pem -h sha256 -in app.exe -out app-signed.exe
EOF
            ;;
        ocsp)
            howto_sec "OCSP Responder Service"
            cat <<EOF
  Launch:
    $script_cmd ocsp-server --ca $ca --signer $name --port 2560
EOF
            ;;
        timestamp)
            howto_sec "Time Stamping Authority (TSA)"
            cat <<EOF
  openssl ts -reply -config tsa.cnf -queryfile request.tsq -signer $d/cert.pem -inkey $d/key.pem -out response.tsr
EOF
            ;;
        custom)
            howto_sec "Custom Integration"
            cat <<EOF
  Ready to deploy: fullchain.pem and key.pem
EOF
            ;;
        esac

        if [ "$fam" = server ] || [ "$fam" = vpnserver ] || [ "$fam" = custom ]; then
            howto_sec "Trusting the Root CA on Client Devices (Once per device)"
            cat <<EOF
  To avoid browser and TLS client warnings on client devices:

  Debian / Ubuntu / Proxmox:
    sudo cp $root /usr/local/share/ca-certificates/$orgslug-root.crt && sudo update-ca-certificates

  RHEL / Rocky Linux / Fedora:
    sudo cp $root /etc/pki/ca-trust/source/anchors/$orgslug-root.pem && sudo update-ca-trust

  macOS:
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $root

  Windows (PowerShell as Administrator):
    Import-Certificate -FilePath .\\root.crt -CertStoreLocation Cert:\\LocalMachine\\Root

  Firefox (Use OS Trust Store):
    In Firefox 'about:config', set 'security.enterprise_roots.enabled' to 'true'.
EOF
        fi

        howto_sec "Testing & Verifying the Certificate"
        cat <<EOF
  Verify chain, CRL, and purpose:
    $script_cmd verify $name$( [ "$fam" = server ] && [ "$pre" != wildcard ] && printf ' --host %s' "$main")

  Test remote TLS handshake after deployment:
    openssl s_client -connect $host:443 -servername $main -CAfile $root </dev/null
    -> Expected result: "Verify return code: 0 (ok)"
EOF

        printf '\n%s\n# Renew Certificate: %s renew %s --revoke-old\n%s\n' "$HR" "$script_cmd" "$name" "$HR"
    } > "$f"
    chmod 644 "$f"
    cp "$f" "$fanl" 2>/dev/null || true
}

# CLI command to regenerate deployment guide
cmd_guide() {
    local n
    [ -n "${1:-}" ] || die "Usage: pki guide <name> | --all"
    if [ "$1" = --all ]; then
        for n in $(list_issued); do
            write_howto "$PKI_DIR/issued/$n"
            ok "GUIDE.txt updated for: $n"
        done
    else
        [ -f "$PKI_DIR/issued/$1/cert.meta" ] || die "Certificate '$1' not found"
        write_howto "$PKI_DIR/issued/$1"
        ok "Documentation written: ${PKI_DIR#"$PWD"/}/issued/$1/GUIDE.txt"
        print_quick_usage "$PKI_DIR/issued/$1"
    fi
}

cmd_anleitung() {
    cmd_guide "$@"
}

###############################################################################
# MODULE: lib/ocsp.sh
###############################################################################
###############################################################################
# lib/ocsp.sh - OCSP Responder Daemon and OCSP Verification
###############################################################################

# Starts the built-in OpenSSL OCSP responder daemon
ocsp_server() {
    local ca=$1 signer=$2 port=${3:-2560} cad sd
    [ -n "$ca" ] && [ -n "$signer" ] || die "Usage: pki ocsp-server --ca <ca> --signer <ocsp-cert> [--port 2560]"
    ca_exists "$ca" || die "CA '$ca' does not exist"
    cad=$(ca_dir "$ca")
    sd="$PKI_DIR/issued/$signer"

    [ -f "$sd/cert.pem" ] || die "OCSP signer '$signer' not found (create first using preset 'ocsp')"
    [ "$(awk -F'"' '/^CA=/{print $2}' "$sd/cert.meta")" = "$ca" ] || die "Signer certificate must be issued by CA '$ca'"

    banner "OCSP Responder for CA '$ca' on port $port (Press Ctrl+C to stop)"
    info "Note: Restart the responder after revoking any certificate to reload index.txt."
    key_passin "$sd/key.pem"

    exec "$OPENSSL" ocsp -index "$cad/index.txt" -port "$port" -rsigner "$sd/cert.pem" -rkey "$sd/key.pem" \
        "${KPASSIN[@]}" -CA "$cad/certs/ca.crt" -text -ignore_err
}

# Queries revocation status of a certificate via OCSP
ocsp_check() {
    local name=$1 url=${2:-} d="$PKI_DIR/issued/$1" ca
    [ -f "$d/cert.pem" ] || die "Certificate '$name' not found"
    ca=$(awk -F'"' '/^CA=/{print $2}' "$d/cert.meta")
    [ "$ca" = selfsigned ] && die "Self-signed certificates do not support OCSP"

    if [ -z "$url" ]; then
        load_ca_meta "$ca"
        url=$M_OCSP_URL
    fi
    [ -n "$url" ] || die "No OCSP URL configured (provide --url http://host:2560 or configure in CA metadata)"

    info "Sending OCSP request to: $url ..."
    "$OPENSSL" ocsp -issuer "$(ca_dir "$ca")/certs/ca.crt" -cert "$d/cert.pem" -url "$url" \
        -CAfile "$d/ca-bundle.pem" -no_nonce
}

###############################################################################
# MODULE: lib/batch.sh
###############################################################################
###############################################################################
# lib/batch.sh - Certificate Templates and Batch Processing
###############################################################################

# Formats a key-value line aligned with comment
tpl_line() {
    printf '%-40s # %s\n' "$1=\"$2\"" "$3"
}

# Outputs a configuration template for a preset to stdout
print_template() {
    local preset=$1 name=${2:-} cn dns="" ip="" email="" ca=${DEFAULT_CA:-server-ca}
    load_preset "$preset" || die "Unknown preset '$preset'. Available presets: $PRESETS"

    case $preset in
        server|server-client) cn="web01.lan"; dns="web01.lan, web01"; ip="10.0.10.5" ;;
        wildcard)             cn="*.lan"; dns="*.lan, lan" ;;
        vpn-server)           cn="vpn.example.org"; dns="vpn.example.org"; ip="203.0.113.10" ;;
        vpn-client)           cn="client01-laptop" ;;
        client)               cn="client01" ;;
        user|smime)           cn="Jane Doe"; email="jane@example.org" ;;
        codesign)             cn="$PKI_ORG Code Signing" ;;
        ocsp)                 cn="$PKI_ORG OCSP Responder" ;;
        timestamp)            cn="$PKI_ORG Timestamp Authority" ;;
        custom)               cn="custom01" ;;
    esac

    [ -z "$name" ] && name=$(name_from_cn "$cn")
    local p12=no cku="" ceku=""
    case $preset in client|user|smime|vpn-client|codesign) p12=yes ;; esac
    [ "$preset" = custom ] && { cku="digitalSignature, keyEncipherment"; ceku="serverAuth, clientAuth"; }

    cat <<EOF
###############################################################################
# Template for pki.sh  -  Preset: $preset
# Purpose: $P_DESC
#
# Usage: pki batch <this-file.conf> [additional...]
# Format: KEY="value" (separate list entries with comma or space)
###############################################################################

######## General Settings
EOF
    tpl_line PRESET "$preset"      "$PRESETS"
    tpl_line NAME   "$name"        "Directory name under issued/ (blank = derived from CN)"
    tpl_line CN     "$cn"          "Common Name (automatically added to SANs for servers)"
    tpl_line OU     ""             "Organizational Unit (blank = default from pki.conf)"
    printf '\n######## Subject Alternative Names (SANs - comma-separated list)\n'
    tpl_line DNS    "$dns"         "DNS hostnames, wildcards supported: *.lan"
    tpl_line IP     "$ip"          "IPv4 and IPv6 addresses"
    tpl_line EMAIL  "$email"       "Email addresses (for smime, user presets)"
    tpl_line URI    ""             "URIs (e.g. spiffe://lab/node1)"
    printf '\n######## Cryptography & Issuing CA\n'
    tpl_line KEY    "${DEFAULT_LEAF_KEY:-rsa3072}" "rsa2048 | rsa3072 | rsa4096 | ed25519"
    tpl_line DAYS   "$P_DAYS"      "Validity in days"
    tpl_line CA     "$ca"          "Intermediate CA name | root | selfsigned"
    tpl_line KEY_PASS no           "yes = encrypt private key with AES-256"
    printf '\n######## Automated Exports\n'
    tpl_line EXPORT_P12 "$p12"     "yes = generate cert.p12 for Windows/macOS/Browser/Email"
    tpl_line P12_LEGACY no         "yes = also generate cert-legacy.p12 (3DES) for legacy systems"
    tpl_line EXPORT_DER no         "yes = generate cert.der (binary DER format)"
    printf '\n######## Advanced Options (only applicable for PRESET="custom")\n'
    tpl_line CUSTOM_KU  "$cku"     "keyUsage (e.g. digitalSignature, keyEncipherment)"
    tpl_line CUSTOM_EKU "$ceku"    "extendedKeyUsage (e.g. serverAuth, clientAuth)"
}

# Processes multiple template files or directories in batch
batch_issue() {
    local f g files=() rcount=0 fcount=0
    for f in "$@"; do
        if [ -d "$f" ]; then
            for g in "$f"/*.conf "$f"/*.meta; do
                [ -f "$g" ] && files+=("$g")
            done
        else
            files+=("$f")
        fi
    done

    [ ${#files[@]} -gt 0 ] || die "No template files specified or found"

    banner "Batch Processing: ${#files[@]} template(s) loaded"

    for f in "${files[@]}"; do
        info "Processing template: $f"
        if ( reset_issue_vars
             # shellcheck disable=SC2086
             load_kv "$f" I_ $I_KEYS SERIAL ISSUED
             I_FORCE=$B_FORCE
             issue_cert ); then
            rcount=$((rcount+1))
        else
            err "Failed processing template: $f"
            fcount=$((fcount+1))
        fi
    done

    banner "Batch completed: $rcount succeeded, $fcount failed"
    [ "$fcount" -eq 0 ]
}

###############################################################################
# MODULE: lib/backup.sh
###############################################################################
###############################################################################
# lib/backup.sh - PKI Backup & Restore Utilities
###############################################################################

# Creates an encrypted/compressed backup archive of the entire PKI directory
pki_backup() {
    require_pki
    local out=${1:-}
    have tar || die "'tar' is not available on this system"

    if [ -z "$out" ]; then
        local bdir="$PKI_DIR/backups"
        mkdir -p "$bdir"
        out="$bdir/pki-backup-$(stamp).tar.gz"
    fi

    banner "Creating PKI Backup"
    info "Backing up $PKI_DIR to $out ..."

    local pki_parent; pki_parent=$(dirname "$PKI_DIR")
    local pki_base; pki_base=$(basename "$PKI_DIR")

    (
        cd "$pki_parent"
        tar -czf "$out" \
            --exclude="$pki_base/backups" \
            --exclude="$pki_base/.req.cnf" \
            "$pki_base"
    ) || die "Backup archive creation failed"

    chmod 600 "$out"
    if tar -tzf "$out" >/dev/null 2>&1; then
        ok "Backup created successfully: $out"
        info "Archive size: $(du -h "$out" 2>/dev/null | awk '{print $1}' || echo 'ok')"
        warn "IMPORTANT: This backup contains private CA keys. Store in a secure, isolated location!"
    else
        die "Archive verification failed: $out"
    fi
}

# Restores the PKI from a backup archive
pki_restore() {
    local src=${1:-}
    [ -n "$src" ] || die "Usage: pki restore <backup-file.tar.gz>"
    [ -f "$src" ] || die "Backup file not found: $src"
    have tar || die "'tar' is not available on this system"

    banner "PKI Restore"
    warn "Target directory: $PKI_DIR"

    if [ -f "$PKI_DIR/root/certs/ca.crt" ]; then
        warn "An active PKI already exists in $PKI_DIR!"
        confirm "Are you sure you want to overwrite the existing PKI with this backup?" || { info "Restore cancelled"; return 0; }
    fi

    local pki_parent; pki_parent=$(dirname "$PKI_DIR")
    mkdir -p "$pki_parent"

    info "Extracting $src to $pki_parent ..."
    (
        cd "$pki_parent"
        tar -xzf "$src"
    ) || die "Extraction failed"

    chmod 700 "$PKI_DIR" 2>/dev/null || true
    [ -d "$PKI_DIR/root/private" ] && chmod 700 "$PKI_DIR/root/private"
    for d in "$PKI_DIR"/intermediate/*/private; do
        [ -d "$d" ] && chmod 700 "$d"
    done

    ok "PKI successfully restored!"
    load_config
    list_all
}

###############################################################################
# MODULE: lib/doctor.sh
###############################################################################
###############################################################################
# lib/doctor.sh - Environment and Integrity Verification (Pre-Flight Health Check)
###############################################################################

pki_doctor() {
    banner "PKI System & Environment Health Check (Doctor)"
    local issues=0 warnings=0

    # 1. OpenSSL Verification
    printf '\n%s1. OpenSSL & Cryptography Environment%s\n' "$C_BLD" "$C_RST"
    if [ -n "$OPENSSL" ] && [ -x "$OPENSSL" ]; then
        local v; v=$("$OPENSSL" version 2>/dev/null)
        if echo "$v" | grep -q '^OpenSSL 3'; then
            ok "OpenSSL 3.x available: $v ($OPENSSL)"
        else
            err "OpenSSL is not version 3.x: $v"
            issues=$((issues+1))
        fi
    else
        err "OpenSSL executable not found!"
        issues=$((issues+1))
    fi

    # 2. Bash Version and System Utilities
    printf '\n%s2. Shell & Core System Utilities%s\n' "$C_BLD" "$C_RST"
    if [ -n "${BASH_VERSION:-}" ]; then
        ok "Bash available: version $BASH_VERSION"
    else
        warn "Non-Bash shell detected (current shell: $SHELL)"
        warnings=$((warnings+1))
    fi

    local tool
    for tool in awk sed date tar tr; do
        if have "$tool"; then
            ok "Tool '$tool' available"
        else
            err "Required core tool '$tool' is missing!"
            issues=$((issues+1))
        fi
    done

    for tool in getent host dig timeout; do
        if have "$tool"; then
            ok "Network tool '$tool' available"
        else
            info "Optional network tool '$tool' not found (DNS autodetection limited)"
        fi
    done

    # 3. PKI Directory Structure and Security Permissions
    printf '\n%s3. PKI Directory Layout & Security Permissions%s\n' "$C_BLD" "$C_RST"
    if [ -d "$PKI_DIR" ]; then
        ok "PKI directory exists: $PKI_DIR"
        if [ -w "$PKI_DIR" ]; then
            ok "PKI directory is writable"
        else
            err "PKI directory is NOT writable!"
            issues=$((issues+1))
        fi
    else
        info "PKI directory does not exist yet (will be created on 'pki init')"
    fi

    # 4. Check CAs and Database Integrity
    if [ -f "$PKI_DIR/root/certs/ca.crt" ]; then
        printf '\n%s4. Certificate Authorities & Databases%s\n' "$C_BLD" "$C_RST"
        local root_days; root_days=$(cert_days_left "$PKI_DIR/root/certs/ca.crt")
        if [ "$root_days" -lt 0 ]; then
            err "Root CA has expired ($root_days days)!"
            issues=$((issues+1))
        else
            ok "Root CA is valid ($root_days days remaining)"
        fi

        # Verify private key permissions
        if [ -d "$PKI_DIR/root/private" ]; then
            local priv_perm; priv_perm=$(ls -ld "$PKI_DIR/root/private" 2>/dev/null | awk '{print $1}')
            case $priv_perm in
                drwx------*) ok "Root private directory securely permissions ($priv_perm)" ;;
                *) warn "Root private directory permissions should be 700 (currently: $priv_perm)"; warnings=$((warnings+1)) ;;
            esac
        fi

        local ca
        for ca in $(list_intermediates); do
            local cad; cad=$(ca_dir "$ca")
            local cdays; cdays=$(cert_days_left "$cad/certs/ca.crt")
            if [ "$cdays" -lt 0 ]; then
                err "Intermediate CA '$ca' has expired ($cdays days remaining)!"
                issues=$((issues+1))
            else
                ok "Intermediate CA '$ca' is valid ($cdays days remaining)"
            fi

            if [ -f "$cad/index.txt" ]; then
                local cert_count; cert_count=$(wc -l < "$cad/index.txt" | tr -d ' ')
                ok "Database for '$ca': $cert_count entries"
            fi
        done
    fi

    # Summary
    divider
    if [ "$issues" -eq 0 ] && [ "$warnings" -eq 0 ]; then
        ok "Diagnostics complete: Everything configured optimally! No issues found."
        return 0
    elif [ "$issues" -eq 0 ]; then
        warn "Diagnostics complete: $warnings warning(s) found, system is functional."
        return 0
    else
        err "Diagnostics complete: $issues critical issue(s) detected! Please resolve."
        return 1
    fi
}

###############################################################################
# MODULE: lib/ui.sh
###############################################################################
###############################################################################
# lib/ui.sh - Interactive Terminal Menu, Input Helpers, and Guided Wizards
###############################################################################

# All interactive prompts write to stderr so stdout remains clean for pipes.
ask() { # ask <var> <prompt> [default]
    local __ask_v=$1 __ask_p=$2 __ask_d=${3:-} __ask_a
    if [ -n "$__ask_d" ]; then
        printf '%s [%s]: ' "$__ask_p" "$__ask_d" >&2
    else
        printf '%s: ' "$__ask_p" >&2
    fi
    IFS= read -r __ask_a || { printf '\n' >&2; exit 0; }
    __ask_a=$(trim "$__ask_a")
    [ -z "$__ask_a" ] && __ask_a=$__ask_d
    printf -v "$__ask_v" '%s' "$__ask_a"
}

# Prompts for mandatory input
ask_req() {
    local __req_v=$1
    while :; do
        ask "$@"
        [ -n "${!__req_v}" ] && return 0
        warn "This field cannot be empty"
    done
}

# Yes/No prompt (returns 'yes' or 'no')
ask_yn() { # ask_yn <var> <prompt> <y|n>
    local __yn_v=$1 __yn_a __yn_d=${3:-n}
    case $__yn_d in j|ja|y|yes) __yn_d=y ;; *) __yn_d=n ;; esac
    while :; do
        ask __yn_a "$2 (y/n)" "$__yn_d"
        case $(lower "$__yn_a") in
            y|yes|j|ja) printf -v "$__yn_v" yes; return ;;
            n|no|nein)  printf -v "$__yn_v" no; return ;;
        esac
    done
}

# Confirmation prompt (defaults to No)
confirm() {
    local r
    ask_yn r "$1" n
    [ "$r" = yes ]
}

# Selection from numbered menu options
ask_choice() { # ask_choice <var> <prompt> <default> "value|description" ...
    local __ch_v=$1 __ch_p=$2 __ch_d=$3; shift 3
    local __ch_i=1 __ch_o __ch_def="" __ch_a __ch_n
    for __ch_o in "$@"; do
        printf '   %2d) %-18s %s\n' "$__ch_i" "${__ch_o%%|*}" "$( [ "$__ch_o" != "${__ch_o#*|}" ] && printf '%s' "${__ch_o#*|}")" >&2
        [ "${__ch_o%%|*}" = "$__ch_d" ] && __ch_def=$__ch_i
        __ch_i=$((__ch_i+1))
    done
    while :; do
        ask __ch_a "$__ch_p" "$__ch_def"
        if is_int "$__ch_a" && [ "$__ch_a" -ge 1 ] && [ "$__ch_a" -le $# ]; then
            __ch_n=1
            for __ch_o in "$@"; do
                [ "$__ch_n" = "$__ch_a" ] && { printf -v "$__ch_v" '%s' "${__ch_o%%|*}"; return; }
                __ch_n=$((__ch_n+1))
            done
        fi
        # Allow typing option value directly (e.g. "server")
        for __ch_o in "$@"; do
            [ "${__ch_o%%|*}" = "$__ch_a" ] && { printf -v "$__ch_v" '%s' "$__ch_a"; return; }
        done
        warn "Please enter a number 1-$# or the name"
    done
}

# Collects multiple values (comma-separated or line-by-line, blank line finishes)
ask_list() { # ask_list <var> <label> [initial]
    local __ls_v=$1 __ls_l=$2 __ls_acc=${3:-} __ls_a __ls_x
    printf '%s  (separate multiple values with comma or enter line-by-line; empty input = finish)\n' "$__ls_l" >&2
    [ -n "$__ls_acc" ] && printf '  already entered: %s\n' "$__ls_acc" >&2
    while :; do
        printf '  + ' >&2
        IFS= read -r __ls_a || break
        __ls_a=$(trim "$__ls_a")
        [ -z "$__ls_a" ] && break
        split_list "$__ls_a"
        for __ls_x in "${SPLIT[@]}"; do
            __ls_acc=$(add_uniq "$__ls_acc" "$__ls_x")
        done
    done
    printf -v "$__ls_v" '%s' "$__ls_acc"
}

pause() {
    printf '\nPress [Enter] to continue... ' >&2
    IFS= read -r _ || exit 0
}

choose_keytype() { # <var> <default>
    ask_choice "$1" "Select key type" "$2" \
        "rsa2048|compatible & fast (minimum standard)" \
        "rsa3072|recommended for leaf certificates" \
        "rsa4096|recommended for CAs (high security)" \
        "ed25519|modern & compact (NOT for web browsers!)"
}

choose_ca() { # <var>
    local __cc_opts=() __cc_n
    for __cc_n in $(list_intermediates); do
        load_ca_meta "$__cc_n"
        __cc_opts+=("$__cc_n|$M_CN ($M_KEY)")
    done
    __cc_opts+=("root|Root CA directly (only if necessary)" "selfsigned|Self-signed (standalone, no CA hierarchy)")
    ask_choice "$1" "Select issuing CA" "${DEFAULT_CA:-root}" "${__cc_opts[@]}"
}

pick_issued() { # <var> <prompt>
    local __pk_opts=() __pk_n
    for __pk_n in $(list_issued); do
        __pk_opts+=("$__pk_n|$(awk -F'"' '/^PRESET=/{print $2}' "$PKI_DIR/issued/$__pk_n/cert.meta") valid until $(cert_end_date "$PKI_DIR/issued/$__pk_n/cert.pem")")
    done
    [ ${#__pk_opts[@]} -gt 0 ] || die "No certificates have been issued yet"
    ask_choice "$1" "$2" "" "${__pk_opts[@]}"
}

pick_any() { # Leaf, Intermediate, or root
    local __pa_opts=() __pa_n
    __pa_opts+=("root|Root CA")
    for __pa_n in $(list_intermediates); do
        __pa_opts+=("$__pa_n|Intermediate CA")
    done
    for __pa_n in $(list_issued); do
        __pa_opts+=("$__pa_n|$(awk -F'"' '/^PRESET=/{print $2}' "$PKI_DIR/issued/$__pa_n/cert.meta")")
    done
    ask_choice "$1" "$2" "" "${__pa_opts[@]}"
}

###############################################################################
# Interactive Wizards
###############################################################################
i_init() {
    banner "PKI Initialization Wizard"
    [ -f "$PKI_DIR/root/certs/ca.crt" ] && die "A PKI already exists in $PKI_DIR"
    info "PKI directory: $PKI_DIR (change with: pki --dir /path)"

    set_conf_defaults
    section "1. Subject Base Information (applied to all certificates)"
    ask PKI_COUNTRY  "Country Code (2 letters, ISO)" "DE"
    ask PKI_STATE    "State / Province (optional)" ""
    ask PKI_LOCALITY "City / Locality (optional)" ""
    ask_req PKI_ORG  "Organization / Homelab Name" "Homelab"
    ask PKI_OU       "Organizational Unit / OU (optional)" ""
    check_safe Organization "$PKI_ORG"
    check_safe OU "$PKI_OU"
    check_safe Locality "$PKI_LOCALITY"
    check_safe State "$PKI_STATE"

    section "2. Root CA Configuration"
    ask_req R_CN "Common Name of Root CA" "$PKI_ORG Root CA"
    choose_keytype R_KEY rsa4096
    DEFAULT_CA_KEY=$R_KEY
    ask R_DAYS "Validity in days" "$ROOT_DAYS"
    ROOT_DAYS=$R_DAYS
    ask_yn R_PASS "Protect Root key with passphrase? (strongly recommended)" y

    section "3. Global PKI Defaults"
    ask DEFAULT_LEAF_KEY "Default key type for leaf certificates" "rsa3072"
    valid_keytype "$DEFAULT_LEAF_KEY" || die "Invalid key type"
    ask CRL_DAYS "CRL validity in days" "30"
    info "Optional: HTTP URL for publishing CRL and CA certificates (publish/)"
    ask AIA_BASE_URL "AIA/CRL Base URL, e.g. http://pki.lan (empty = none)" ""

    create_root

    section "4. Create Intermediate CAs"
    info "Recommendation: Create at least a 'server-ca' for web and server services."
    local more=yes
    while [ "$more" = yes ]; do
        ask_yn more "Create an Intermediate CA now?" y
        [ "$more" = yes ] || break
        ( i_ca_new_inner ) || warn "Intermediate CA creation skipped"
        load_config
    done
    ok "PKI successfully initialized! You can now issue certificates directly."
}

i_ca_new_inner() {
    N_NAME="" N_CN="" N_KEY="" N_DAYS="" N_PASS=yes N_PATHLEN=0 N_PERMIT_DNS="" N_PERMIT_IP="" N_EKU_LIMIT="" N_OCSP_URL=""
    ask_req N_NAME "Short identifier for Intermediate CA (e.g. server-ca, client-ca, vpn-ca)" ""
    N_NAME=$(lower "$N_NAME")
    ask_req N_CN "Common Name (CN)" "$PKI_ORG $(printf '%s' "$N_NAME" | sed 's/-/ /g')"
    choose_keytype N_KEY "${DEFAULT_CA_KEY:-rsa4096}"
    ask N_DAYS "Validity in days" "$INTERMEDIATE_DAYS"
    ask_yn N_PASS "Protect CA key with passphrase?" y

    local adv
    ask_yn adv "Configure advanced restrictions (Name Constraints, EKU limit, OCSP)?" n
    if [ "$adv" = yes ]; then
        info "Name Constraints: CA may ONLY issue certificates matching these suffixes (e.g. .lan .home.arpa)"
        ask_list N_PERMIT_DNS "Permitted DNS suffixes (empty = unrestricted)"
        ask_list N_PERMIT_IP  "Permitted IPv4 subnets in CIDR (e.g. 10.0.0.0/8, empty = unrestricted)"
        info "EKU Restriction: Certificates issued by this CA will be restricted to these purposes (e.g. serverAuth, clientAuth)"
        ask N_EKU_LIMIT "EKU Restriction (empty = none)" ""
        ask N_OCSP_URL "OCSP URL for this CA, e.g. http://ocsp.lan:2560 (empty = none)" ""
        ask N_PATHLEN "Maximum depth of subordinate CAs (pathlen)" "0"
    fi
    create_intermediate
}

i_ca_new() {
    require_pki
    banner "Create Intermediate CA"
    i_ca_new_inner
}

i_issue() {
    local p opts=()
    require_pki
    banner "Certificate Issuance Wizard"
    reset_issue_vars

    for p in $PRESETS; do
        load_preset "$p"
        opts+=("$p|$P_DESC")
    done

    ask_choice I_PRESET "Select preset / intended usage" server "${opts[@]}"
    load_preset "$I_PRESET"
    info "$P_DESC"
    choose_ca I_CA

    section "1. Certificate Identity"
    case $I_PRESET in
        wildcard)
            ask_req I_DOMAIN "Base domain (covers *.domain + base domain)" "lan"
            I_DOMAIN=$(lower "${I_DOMAIN#\*.}")
            I_CN="*.$I_DOMAIN"
            I_DNS="*.$I_DOMAIN,$I_DOMAIN"
            info "CN: $I_CN  SANs: $I_DNS"
            ;;
        smime|user)
            ask_req I_CN "Full Name of Person (CN)" ""
            ask_list I_EMAIL "Email address(es)"
            ;;
        codesign)
            ask_req I_CN "Signing Identity (CN)" "$PKI_ORG Code Signing"
            ;;
        ocsp)
            ask_req I_CN "Responder Identity (CN)" "$PKI_ORG OCSP Responder ($I_CA)"
            ;;
        timestamp)
            ask_req I_CN "Timestamp Authority Name (CN)" "$PKI_ORG Timestamp Authority"
            ;;
        client|vpn-client)
            ask_req I_CN "Client Identity (user or device, e.g. user-laptop)" ""
            ;;
        *)
            ask_req I_CN "Hostname / FQDN (automatically added as SAN)" ""
            [ "$P_CN_AUTO" = dns ] && autodetect_offer
            ;;
    esac

    case " $P_SAN_ASK " in
        *" dns "*)
            info "Additional DNS hostnames (aliases, short names). CN is included automatically."
            ask_list I_DNS "DNS hostnames" "$I_DNS"
            ;;
    esac
    case " $P_SAN_ASK " in
        *" ip "*)
            ask_list I_IP "IP addresses (IPv4/IPv6)" "$I_IP"
            ;;
    esac
    case " $P_SAN_ASK " in
        *" email "*)
            [ -z "$I_EMAIL" ] && ask_list I_EMAIL "Email addresses (optional)"
            ;;
    esac
    case " $P_SAN_ASK " in
        *" uri "*)
            ask_list I_URI "URIs (optional, e.g. spiffe://lab/node1)"
            ;;
    esac

    if [ "$I_PRESET" = custom ]; then
        section "Define Custom Key Usage"
        ask I_CUSTOM_KU "keyUsage" "digitalSignature, keyEncipherment"
        ask I_CUSTOM_EKU "extendedKeyUsage" "serverAuth, clientAuth"
    fi

    section "2. Key & Validity"
    choose_keytype I_KEY "$DEFAULT_LEAF_KEY"
    ask I_DAYS "Validity in days" "$P_DAYS"

    case $(preset_family "$I_PRESET") in
        server|vpnserver|ocsp|timestamp)
            info "For services like Nginx, Apache, or Proxmox an unencrypted key is recommended for unattended reboots."
            ;;
        *)
            info "For browser/Windows/macOS users the passphrase is embedded directly into the .p12 bundle."
            ;;
    esac
    ask_yn I_KEY_PASS "Protect private key with passphrase?" n

    section "3. Exports & Output"
    local p12def=n
    case $I_PRESET in client|user|smime|vpn-client|codesign) p12def=y ;; esac
    ask_yn I_EXPORT_P12 "Generate PKCS#12 (.p12) for Windows/macOS/Browser/Email?" "$p12def"
    [ "$I_EXPORT_P12" = yes ] && ask_yn I_P12_LEGACY "Also generate legacy PKCS#12 (3DES) for older systems?" n
    ask_yn I_EXPORT_DER "Generate binary DER format (.der)?" n

    ask I_NAME "Directory name under issued/" "$(name_from_cn "$I_CN")"

    banner "Configuration Summary"
    kv "Preset"      "$I_PRESET"
    kv "Issuer CA"   "$I_CA"
    kv "Common Name" "$I_CN"
    kv "DNS SANs"    "${I_DNS:--}"
    kv "IP SANs"     "${I_IP:--}"
    kv "Email"       "${I_EMAIL:--}"
    kv "Key Type"    "$I_KEY $( [ "$I_KEY_PASS" = yes ] && echo '(encrypted)' || echo '(unencrypted)' )"
    kv "Validity"    "$I_DAYS days"
    kv "Exports"     "P12=$I_EXPORT_P12, DER=$I_EXPORT_DER"
    kv "Directory"   "issued/$I_NAME"
    printf '\n' >&2

    if [ -e "$PKI_DIR/issued/$I_NAME/cert.pem" ]; then
        warn "A certificate in 'issued/$I_NAME' already exists!"
        confirm "Overwrite (previous certificate material will be archived)?" || return 0
        I_FORCE=1
    fi

    confirm "Issue certificate now?" || { info "Issuance cancelled"; return 0; }
    issue_cert
}

i_quick() {
    require_pki
    local h use
    banner "Quick Mode: TLS Server Certificate"
    printf '  Enter only the hostname (short or FQDN) or an IP address.\n' >&2
    printf '  All SANs and IPs are discovered automatically via DNS!\n' >&2
    printf '  Defaults: Preset server, %s, 397 days, CA: %s\n\n' "$DEFAULT_LEAF_KEY" "${DEFAULT_CA:-selected below}" >&2

    ask_req h "Hostname or IP address" ""
    reset_issue_vars
    I_PRESET=server

    info "Discovering network configuration ..."
    autodetect "$h" || return 1

    kv "CN"       "$AD_CN"
    kv "DNS SANs" "$( [ -n "$AD_DNS" ] && printf '%s' "$AD_DNS" | sed 's/,/, /g' || echo '-')"
    kv "IP SANs"  "$( [ -n "$AD_IP" ] && printf '%s' "$AD_IP" | sed 's/,/, /g' || echo '(none via DNS)')"
    printf '\n' >&2

    ask_yn use "Accept detected network parameters?" y
    I_CN=$AD_CN
    if [ "$use" = yes ]; then
        I_DNS=$AD_DNS
        I_IP=$AD_IP
    fi

    ask_list I_DNS "Additional DNS hostnames (optional)" "$I_DNS"
    ask_list I_IP  "Additional IP addresses (optional)" "$I_IP"

    if [ -n "$DEFAULT_CA" ]; then
        I_CA=$DEFAULT_CA
    else
        choose_ca I_CA
    fi

    I_NAME=$(name_from_cn "$I_CN")
    if [ -e "$PKI_DIR/issued/$I_NAME/cert.pem" ]; then
        warn "issued/$I_NAME already exists"
        confirm "Overwrite (previous material will be archived)?" || return 0
        I_FORCE=1
    fi
    issue_cert
}

i_sign_csr() {
    require_pki
    banner "Sign External CSR"
    reset_issue_vars; I_NO_CSR_SAN=0
    local csr p opts=() add

    ask_req csr "Path to CSR file" ""
    [ -f "$csr" ] || die "CSR file not found: $csr"
    csr_info "$csr"

    info "CSR inspected: CN='$CSR_CN' Key=$CSR_KEY SAN='${CSR_SAN:-none}'"
    for p in $PRESETS; do
        [ "$p" = wildcard ] && continue
        load_preset "$p"
        opts+=("$p|$P_DESC")
    done

    ask_choice I_PRESET "Preset" server "${opts[@]}"
    choose_ca I_CA
    ask I_CN "Common Name" "$CSR_CN"
    ask_yn add "Import SANs from CSR?" y
    [ "$add" = no ] && I_NO_CSR_SAN=1

    ask_list I_DNS "Additional DNS hostnames"
    ask_list I_IP  "Additional IP addresses"
    load_preset "$I_PRESET"
    ask I_DAYS "Validity in days" "$P_DAYS"
    ask I_NAME "Directory name under issued/" "$(name_from_cn "${I_CN:-$CSR_CN}")"

    confirm "Sign CSR now?" || return 0
    sign_csr "$csr"
}

i_show() {
    require_pki
    local n f
    pick_any n "Which certificate would you like to view?"
    ask_yn f "Verbose OpenSSL text output (-text)?" n
    show_cert "$n" "$( [ "$f" = yes ] && echo full)"
}

i_verify() {
    require_pki
    local n h
    pick_issued n "Which certificate should be verified?"
    ask h "Hostname/IP to verify against (leave blank to skip)" ""
    verify_cert "$n" "$h" || true
}

i_renew() {
    require_pki
    local n k r
    pick_issued n "Which certificate would you like to renew?"
    ask_yn k "Keep existing private key? (n = generate new key, recommended)" n
    ask_yn r "Revoke previous certificate in CA as 'superseded'?" y
    I_KEEP_KEY=0; [ "$k" = yes ] && I_KEEP_KEY=1
    R_REVOKE_OLD=0; [ "$r" = yes ] && R_REVOKE_OLD=1
    I_DAYS=""
    renew_cert "$n"
}

i_renew_ca() {
    require_pki
    local opts=("root|Root CA") n d
    for n in $(list_intermediates); do opts+=("$n|Intermediate CA"); done
    ask_choice n "Which CA would you like to renew?" "" "${opts[@]}"
    ask d "New validity in days" "$( [ "$n" = root ] && echo "$ROOT_DAYS" || echo "$INTERMEDIATE_DAYS")"
    confirm "Sign CA '$n' with renewed expiration date?" || return 0
    renew_ca "$n" "$d"
}

i_revoke() {
    require_pki
    local n r opts=() x
    pick_any n "Which certificate or Intermediate CA should be revoked?"
    [ "$n" = root ] && die "The Root CA cannot be revoked - only renewed or replaced."
    for x in $REVOKE_REASONS; do opts+=("$x|"); done
    ask_choice r "Revocation reason" superseded "${opts[@]}"
    revoke_cert "$n" "$r"
}

i_crl() {
    require_pki
    local opts=("all|Regenerate for all CAs" "root|Root CA only") n x
    for x in $(list_intermediates); do opts+=("$x|Intermediate CA"); done
    ask_choice n "Generate CRL for" all "${opts[@]}"
    if [ "$n" = all ]; then
        for x in root $(list_intermediates); do gen_crl "$x"; done
    else
        gen_crl "$n"
    fi
}

i_export() {
    require_pki
    local n p l der
    pick_issued n "Which certificate would you like to export?"
    ask_yn p "Generate PKCS#12 (.p12)?" y
    l=no
    [ "$p" = yes ] && ask_yn l "Also generate legacy PKCS#12 (3DES) for older systems?" n
    ask_yn der "Generate binary DER certificate (.der)?" n
    [ "$p" = yes ] && export_p12 "$n" "$l"
    [ "$der" = yes ] && export_der "$n"
    print_leaf_files "$PKI_DIR/issued/$n"
}

i_template() {
    local p opts=() name out
    for p in $PRESETS; do
        load_preset "$p"
        opts+=("$p|$P_DESC")
    done
    ask_choice p "Preset for template" server "${opts[@]}"
    ask name "Name (directory under issued/)" ""
    mkdir -p "$PKI_DIR/templates" 2>/dev/null || true
    ask out "Target file" "$PKI_DIR/templates/${name:-$p}.conf"
    print_template "$p" "$name" > "$out"
    ok "Template written successfully: $out"
    info "Edit this file and run 'pki batch $out' later."
}

i_batch() {
    require_pki
    local f
    ask_req f "Template file or directory" "$PKI_DIR/templates"
    B_FORCE=0
    batch_issue "$f"
}

i_ocsp() {
    require_pki
    local ca s port opts=() n
    for n in $(list_issued); do
        [ "$(awk -F'"' '/^PRESET=/{print $2}' "$PKI_DIR/issued/$n/cert.meta")" = ocsp ] && opts+=("$n|")
    done
    [ ${#opts[@]} -gt 0 ] || die "No OCSP signer found! Please issue a certificate using preset 'ocsp' first."
    ask_choice s "OCSP Signer Certificate" "" "${opts[@]}"
    ca=$(awk -F'"' '/^CA=/{print $2}' "$PKI_DIR/issued/$s/cert.meta")
    ask port "TCP port for responder daemon" 2560
    ocsp_server "$ca" "$s" "$port"
}

i_backup() {
    local act
    ask_choice act "Action" backup \
        "backup|Create a full PKI backup archive" \
        "restore|Restore PKI from a backup archive"
    if [ "$act" = backup ]; then
        pki_backup
    else
        local f
        ask_req f "Path to backup archive (.tar.gz)" ""
        pki_restore "$f"
    fi
}

i_search() {
    local q
    ask_req q "Search term (domain, IP, name, serial)" ""
    search_certs "$q"
}

###############################################################################
# Dashboard & Main Menu
###############################################################################
menu_header() {
    local ints n=0 exp=0 x
    printf '\n%s\n' "$HR" >&2
    printf '# %sOpenSSL Homelab PKI Generator %s%s  (%s)\n' "$C_BLD" "$VERSION" "$C_RST" "$OPENSSL" >&2
    printf '# PKI Directory: %s\n' "$PKI_DIR" >&2

    if [ -f "$PKI_DIR/root/certs/ca.crt" ]; then
        ints=$(list_intermediates | tr '\n' ' ')
        for x in $(list_issued); do
            n=$((n+1))
            local d; d=$(cert_days_left "$PKI_DIR/issued/$x/cert.pem")
            [ "$d" != "?" ] && [ "$d" -le "${WARN_DAYS:-30}" ] && exp=$((exp+1))
        done
        local root_days; root_days=$(cert_days_left "$PKI_DIR/root/certs/ca.crt")
        printf '# Root CA      : %s (%s days)  |  Intermediates: %s\n' \
            "$(cert_cn "$PKI_DIR/root/certs/ca.crt")" "$root_days" "${ints:-none}" >&2
        printf '# Certificates : %s issued  |  %s expiring soon  |  Default CA: %s\n' \
            "$n" "$( [ "$exp" -gt 0 ] && printf '%s%s%s' "$C_YEL" "$exp" "$C_RST" || printf '0' )" "${DEFAULT_CA:-none}" >&2
    else
        printf '# Status       : %sNo PKI initialized yet%s -> Select option 1 to set up!\n' "$C_YEL" "$C_RST" >&2
    fi
    printf '%s\n' "$HR" >&2
}

menu() {
    INTERACTIVE=1
    local c
    while :; do
        load_config
        menu_header
        cat >&2 <<'EOF'
  [s] QUICK MODE: Issue TLS Server Certificate in 1 Click (DNS Auto-Detect)
  [d] DASHBOARD / STATUS: Overview of all CAs & Certificates

  1. PKI & CA Management
     1) Initialize New PKI (Root CA)
     2) Create Intermediate CA
     3) System Diagnostics (Doctor)
     4) Create / Restore PKI Backup

  2. Certificate Issuance
     5) Issue Certificate (Wizard)
     6) Sign External CSR
     7) Issue Certificates in Batch

  3. Inspection & Operations
     8) List all Certificates & CAs
     9) Search Certificates
    10) Show Certificate Details
    11) Verify Certificate & Key Match
    12) Run Expiry Check

  4. Lifecycle & Maintenance
    13) Renew Certificate
    14) Renew CA Certificate
    15) Revoke Certificate / Intermediate CA
    16) Regenerate CRL Revocation List
    17) Export PKCS#12 (.p12) / DER
    18) Launch OCSP Responder Daemon

  [p] Show Presets    [h] Help (CLI)    [0/q] Exit
EOF
        printf '%s\n' "$HR" >&2
        printf 'Your choice: ' >&2
        IFS= read -r c || { printf '\n' >&2; exit 0; }
        case $(trim "$c") in
            s|S)      ( i_quick )       || true ;;
            d|D)      ( list_all )      || true ;;
            1)        ( i_init )        || true ;;
            2)        ( i_ca_new )      || true ;;
            3)        ( pki_doctor )    || true ;;
            4)        ( i_backup )      || true ;;
            5)        ( i_issue )       || true ;;
            6)        ( i_sign_csr )    || true ;;
            7)        ( i_batch )       || true ;;
            8)        ( list_all )      || true ;;
            9)        ( i_search )      || true ;;
            10)       ( i_show )        || true ;;
            11)       ( i_verify )      || true ;;
            12)       ( check_all )     || true ;;
            13)       ( i_renew )       || true ;;
            14)       ( i_renew_ca )    || true ;;
            15)       ( i_revoke )      || true ;;
            16)       ( i_crl )         || true ;;
            17)       ( i_export )      || true ;;
            18)       ( i_ocsp )        || true ;;
            p|P)      ( print_presets ) || true ;;
            h|H|help) ( usage )         || true ;;
            0|q|Q|exit) exit 0 ;;
            '')       continue ;;
            *)        warn "Invalid choice: $c"; continue ;;
        esac
        pause
    done
}

###############################################################################
# MODULE: lib/cli.sh
###############################################################################
###############################################################################
# lib/cli.sh - Command Line Interface (CLI) Parser and Argument Dispatcher
###############################################################################

need_arg() {
    [ -n "${2:-}" ] || die "Option $1 requires an argument"
}

# Common options for issue / selfsigned / sign-csr
parse_issue_opts() {
    while [ $# -gt 0 ]; do
        case $1 in
            --cn)         need_arg "$@"; I_CN=$2; shift ;;
            --dns)        need_arg "$@"; I_DNS="${I_DNS:+$I_DNS,}$2"; shift ;;
            --ip)         need_arg "$@"; I_IP="${I_IP:+$I_IP,}$2"; shift ;;
            --email)      need_arg "$@"; I_EMAIL="${I_EMAIL:+$I_EMAIL,}$2"; shift ;;
            --uri)        need_arg "$@"; I_URI="${I_URI:+$I_URI,}$2"; shift ;;
            --domain)     need_arg "$@"; I_DOMAIN=$2; shift ;;
            --ca)         need_arg "$@"; I_CA=$2; shift ;;
            --key)        need_arg "$@"; I_KEY=$2; shift ;;
            --days)       need_arg "$@"; I_DAYS=$2; shift ;;
            --name)       need_arg "$@"; I_NAME=$2; shift ;;
            --ou)         need_arg "$@"; I_OU=$2; shift ;;
            --preset)     need_arg "$@"; I_PRESET=$2; shift ;;
            --ku)         need_arg "$@"; I_CUSTOM_KU=$2; shift ;;
            --eku)        need_arg "$@"; I_CUSTOM_EKU=$2; shift ;;
            --key-pass)   I_KEY_PASS=yes ;;
            --p12)        I_EXPORT_P12=yes ;;
            --p12-legacy) I_EXPORT_P12=yes; I_P12_LEGACY=yes ;;
            --der)        I_EXPORT_DER=yes ;;
            --force)      I_FORCE=1 ;;
            --no-csr-san) I_NO_CSR_SAN=1 ;;
            *) die "Unknown option: $1  (view help with: pki help)" ;;
        esac
        shift
    done
}

cmd_init() {
    set_conf_defaults
    R_CN="" R_KEY="" R_DAYS="" R_PASS=yes
    local ints=() n

    while [ $# -gt 0 ]; do
        case $1 in
            --org)          need_arg "$@"; PKI_ORG=$2; shift ;;
            --country)      need_arg "$@"; PKI_COUNTRY=$2; shift ;;
            --state)        need_arg "$@"; PKI_STATE=$2; shift ;;
            --locality)     need_arg "$@"; PKI_LOCALITY=$2; shift ;;
            --ou)           need_arg "$@"; PKI_OU=$2; shift ;;
            --cn)           need_arg "$@"; R_CN=$2; shift ;;
            --key)          need_arg "$@"; R_KEY=$2; shift ;;
            --days)         need_arg "$@"; R_DAYS=$2; shift ;;
            --leaf-key)     need_arg "$@"; DEFAULT_LEAF_KEY=$2; shift ;;
            --crl-days)     need_arg "$@"; CRL_DAYS=$2; shift ;;
            --aia-url)      need_arg "$@"; AIA_BASE_URL=$2; shift ;;
            --no-pass)      R_PASS=no ;;
            --intermediate) need_arg "$@"; ints+=("$2"); shift ;;
            *) die "Unknown option for init: $1" ;;
        esac
        shift
    done

    for n in "$PKI_ORG" "$PKI_OU" "$PKI_STATE" "$PKI_LOCALITY" "$AIA_BASE_URL"; do
        check_safe Value "$n"
    done
    valid_keytype "$DEFAULT_LEAF_KEY" || die "Invalid --leaf-key"
    [ -z "$R_CN" ] && R_CN="$PKI_ORG Root CA"
    [ -z "$R_KEY" ] && R_KEY=rsa4096
    DEFAULT_CA_KEY=$R_KEY
    [ -z "$R_DAYS" ] && R_DAYS=$ROOT_DAYS
    ROOT_DAYS=$R_DAYS

    create_root

    for n in "${ints[@]}"; do
        N_NAME=$n N_CN="" N_KEY="" N_DAYS="" N_PASS=$R_PASS N_PATHLEN=0
        N_PERMIT_DNS="" N_PERMIT_IP="" N_EKU_LIMIT="" N_OCSP_URL=""
        create_intermediate
    done
}

cmd_ca_new() {
    require_pki
    N_NAME=${1:-}
    [ -n "$N_NAME" ] && shift || die "Usage: pki ca-new <name> [options]"
    N_NAME=$(lower "$N_NAME")
    N_CN="" N_KEY="" N_DAYS="" N_PASS=yes N_PATHLEN=0 N_PERMIT_DNS="" N_PERMIT_IP="" N_EKU_LIMIT="" N_OCSP_URL=""
    local setdef=0

    while [ $# -gt 0 ]; do
        case $1 in
            --cn)         need_arg "$@"; N_CN=$2; shift ;;
            --key)        need_arg "$@"; N_KEY=$2; shift ;;
            --days)       need_arg "$@"; N_DAYS=$2; shift ;;
            --no-pass)    N_PASS=no ;;
            --pathlen)    need_arg "$@"; N_PATHLEN=$2; shift ;;
            --permit-dns) need_arg "$@"; N_PERMIT_DNS="${N_PERMIT_DNS:+$N_PERMIT_DNS,}$2"; shift ;;
            --permit-ip)  need_arg "$@"; N_PERMIT_IP="${N_PERMIT_IP:+$N_PERMIT_IP,}$2"; shift ;;
            --eku-limit)  need_arg "$@"; N_EKU_LIMIT=$2; shift ;;
            --ocsp-url)   need_arg "$@"; N_OCSP_URL=$2; shift ;;
            --default)    setdef=1 ;;
            *) die "Unknown option for ca-new: $1" ;;
        esac
        shift
    done

    check_safe Value "$N_OCSP_URL"
    check_safe Value "$N_EKU_LIMIT"
    create_intermediate

    if [ "$setdef" = 1 ]; then
        DEFAULT_CA=$N_NAME
        write_config
        ok "DEFAULT_CA set to: $N_NAME"
    fi
}

usage() {
    cat <<EOF
$HR
# OpenSSL Homelab PKI Generator $VERSION
$HR

USAGE:
  pki                                   Interactive TUI menu and wizards
  pki [--dir PATH] [-y] <command> [opt] CLI mode (automation, CI/CD, and scripts)

GLOBAL OPTIONS:
  --dir PATH           PKI root directory (default: ./pki or \$PKI_DIR)
  -y, --yes            Assume yes to all prompts (for non-interactive automation)
  --no-color           Disable ANSI colored console output (or set NO_COLOR=1)

COMMANDS BY CATEGORY:

1. Infrastructure & CAs
  init                 Initialize new PKI (Root CA + optional Intermediates)
                       Options: --org NAME, --country CC, --state, --locality, --ou
                                 --cn NAME, --key rsa4096|..., --days 7300, --no-pass
                                 --leaf-key rsa3072, --crl-days 30, --aia-url URL
                                 --intermediate NAME (can be repeated)
  ca-new NAME          Create a new Intermediate CA
                       Options: --cn, --key, --days, --no-pass, --pathlen N
                                 --permit-dns LIST, --permit-ip LIST
                                 --eku-limit LIST, --ocsp-url URL, --default
  doctor               System environment diagnosis & pre-flight health checks

2. Certificate Issuance
  quick HOST           1-Click TLS Server Certificate with automatic DNS/IP discovery!
                       Options: --dns LIST, --ip LIST, --ca CA, --days N, --no-lookup
  issue PRESET         Issue a certificate using a profile preset (see: pki presets)
                       Options: --cn NAME (required)
                                 --dns LIST, --ip LIST, --email LIST, --uri LIST
                                 --domain DOMAIN (for wildcard preset)
                                 --ca CA (default: DEFAULT_CA), --key TYPE, --days N
                                 --name DIR, --ou OU, --key-pass
                                 --p12, --p12-legacy, --der, --force
  selfsigned           Shortcut: pki issue <preset> --ca selfsigned
  sign-csr FILE        Sign an external CSR (same options as 'issue', plus --no-csr-san)

3. Inspection & Diagnostics
  list, ls             Tabular overview of all CAs & issued certificates with validity
  search QUERY         Filter certificates (by name, CN, IP, SAN, status, or serial)
  status, dashboard    Live summary dashboard of PKI health
  show NAME|FILE       Show certificate details (--full for complete OpenSSL text)
  verify NAME          Comprehensive verification: Chain, CRL, Purpose, Key Match (--host H)
  check [--days N]     Expiry monitoring (Exit 0=ok, 2=certificates/CRLs expiring soon)
  guide, anleitung     Regenerate GUIDE.txt integration documentation (Nginx, Proxmox, etc.)

4. Lifecycle & Maintenance
  renew NAME           Renew leaf certificate (--keep-key, --revoke-old, --days N)
  renew-ca NAME        Renew Root or Intermediate CA certificate (retains private key)
  revoke NAME          Revoke a certificate or Intermediate CA (--reason REASON)
  crl [--ca NAME]      Regenerate CRL revocation list (without --ca: all CAs)
  export NAME          Export certificate bundles (--p12, --p12-legacy, --der)
  backup [FILE]        Create secure compressed tar.gz backup of entire PKI directory
  restore FILE         Restore PKI from a backup archive

5. Templates, Batch & Services
  presets              Display all certificate presets and intended usages
  template PRESET      Generate configuration template to stdout or file (-o FILE)
  batch FILE|DIR       Batch issue certificates automatically from template files
  ocsp-server          Launch OpenSSL OCSP responder daemon (--ca CA --signer NAME [--port 2560])
  ocsp-check NAME      Query OCSP revocation status for a certificate (--url URL)

EXAMPLES:
  pki init --org Homelab --intermediate server-ca --intermediate client-ca
  pki quick pve-node1.lan                   # Autodetects FQDN, shortname, and IP addresses
  pki issue server --cn web01.lan --dns www.lan,web01 --ip 10.0.10.5
  pki issue wildcard --domain homelab.lan
  pki issue client --cn admin-laptop --p12
  pki verify web01.lan --host web01.lan
  pki backup /mnt/secure/pki-backup.tar.gz

ENVIRONMENT VARIABLES FOR HEADLESS AUTOMATION:
  PKI_DIR              PKI directory path (default: ./pki)
  PKI_CA_PASS          Master passphrase for all CA keys
  PKI_CA_PASS_<NAME>   Passphrase for a specific CA (e.g. PKI_CA_PASS_SERVER_CA)
  PKI_KEY_PASS         Passphrase for leaf certificate keys
  PKI_P12_PASS         Passphrase for PKCS#12 exports
EOF
}

dispatch_cli() {
    local cmd=${1:-}
    [ $# -gt 0 ] && shift

    case $cmd in
        '')
            menu
            ;;
        help|-h|--help)
            usage
            ;;
        version|-v|--version)
            printf 'pki.sh %s (%s)\n' "$VERSION" "$("$OPENSSL" version)"
            ;;
        presets)
            print_presets
            ;;
        init)
            cmd_init "$@"
            ;;
        ca-new)
            cmd_ca_new "$@"
            ;;
        issue)
            require_pki; reset_issue_vars
            I_PRESET=${1:-}
            [ -n "$I_PRESET" ] && shift || die "Usage: pki issue <preset> --cn ... (view presets with: pki presets)"
            parse_issue_opts "$@"
            issue_cert
            ;;
        quick)
            require_pki
            cmd_quick "$@"
            ;;
        guide|anleitung|howto)
            require_pki
            cmd_guide "$@"
            ;;
        selfsigned)
            [ -f "$PKI_DIR/.req.cnf" ] || { mkdir -p "$PKI_DIR/issued" "$PKI_DIR/log"; write_req_cnf; }
            reset_issue_vars
            I_PRESET=server
            case ${1:-} in ''|-*) ;; *) I_PRESET=$1; shift ;; esac
            parse_issue_opts "$@"
            I_CA=selfsigned
            issue_cert
            ;;
        sign-csr)
            require_pki; reset_issue_vars; I_NO_CSR_SAN=0
            local csr=${1:-}
            [ -n "$csr" ] && shift || die "Usage: pki sign-csr <file.csr> --preset server [--ca ...]"
            I_PRESET=server
            parse_issue_opts "$@"
            sign_csr "$csr"
            ;;
        list|ls)
            list_all
            ;;
        status|dashboard)
            list_all
            ;;
        search)
            search_certs "$@"
            ;;
        doctor)
            pki_doctor
            ;;
        check)
            local wd=""
            while [ $# -gt 0 ]; do
                case $1 in
                    --days) need_arg "$@"; wd=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            check_all "$wd" || exit $?
            ;;
        show)
            [ -n "${1:-}" ] || die "Usage: pki show <name|file> [--full]"
            show_cert "$1" "$( [ "${2:-}" = --full ] && echo full)"
            ;;
        verify)
            require_pki
            local vn=${1:-} vh=""
            [ -n "$vn" ] && shift || die "Usage: pki verify <name> [--host hostname]"
            while [ $# -gt 0 ]; do
                case $1 in
                    --host) need_arg "$@"; vh=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            verify_cert "$vn" "$vh" || exit $?
            ;;
        renew)
            require_pki
            local rn=${1:-}
            [ -n "$rn" ] && shift || die "Usage: pki renew <name> [--keep-key] [--revoke-old] [--days N]"
            I_KEEP_KEY=0; R_REVOKE_OLD=0; I_DAYS=""
            while [ $# -gt 0 ]; do
                case $1 in
                    --keep-key)   I_KEEP_KEY=1 ;;
                    --revoke-old) R_REVOKE_OLD=1 ;;
                    --days)       need_arg "$@"; I_DAYS=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            renew_cert "$rn"
            ;;
        renew-ca)
            require_pki
            local cn=${1:-} cd=""
            [ -n "$cn" ] && shift || die "Usage: pki renew-ca <root|intermediate> [--days N]"
            while [ $# -gt 0 ]; do
                case $1 in
                    --days) need_arg "$@"; cd=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            renew_ca "$cn" "$cd"
            ;;
        revoke)
            require_pki
            local vname=${1:-} reason=unspecified
            [ -n "$vname" ] && shift || die "Usage: pki revoke <name> [--reason reason]"
            while [ $# -gt 0 ]; do
                case $1 in
                    --reason) need_arg "$@"; reason=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            revoke_cert "$vname" "$reason"
            ;;
        crl)
            require_pki
            local cc=""
            while [ $# -gt 0 ]; do
                case $1 in
                    --ca) need_arg "$@"; cc=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            if [ -n "$cc" ]; then
                ca_exists "$cc" || die "CA '$cc' unknown"
                gen_crl "$cc"
            else
                for cc in root $(list_intermediates); do gen_crl "$cc"; done
            fi
            ;;
        export)
            require_pki
            local en=${1:-} ep=0 el=no ed=0
            [ -n "$en" ] && shift || die "Usage: pki export <name> [--p12] [--p12-legacy] [--der]"
            [ -f "$PKI_DIR/issued/$en/cert.pem" ] || die "Certificate '$en' not found"
            while [ $# -gt 0 ]; do
                case $1 in
                    --p12)        ep=1 ;;
                    --p12-legacy) ep=1; el=yes ;;
                    --der)        ed=1 ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            [ "$ep" = 0 ] && [ "$ed" = 0 ] && { ep=1; ed=1; }
            [ "$ep" = 1 ] && export_p12 "$en" "$el"
            [ "$ed" = 1 ] && export_der "$en"
            print_leaf_files "$PKI_DIR/issued/$en"
            ;;
        backup)
            pki_backup "$@"
            ;;
        restore)
            pki_restore "$@"
            ;;
        ocsp-server)
            require_pki
            local oc="" os="" op=2560
            while [ $# -gt 0 ]; do
                case $1 in
                    --ca)     need_arg "$@"; oc=$2; shift ;;
                    --signer) need_arg "$@"; os=$2; shift ;;
                    --port)   need_arg "$@"; op=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            ocsp_server "$oc" "$os" "$op"
            ;;
        ocsp-check)
            require_pki
            local qn=${1:-} qu=""
            [ -n "$qn" ] && shift || die "Usage: pki ocsp-check <name> [--url URL]"
            while [ $# -gt 0 ]; do
                case $1 in
                    --url) need_arg "$@"; qu=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            ocsp_check "$qn" "$qu" || exit $?
            ;;
        template)
            local tp=${1:-} tn="" to=""
            [ -n "$tp" ] && shift || die "Usage: pki template <preset> [--name n] [-o file]"
            while [ $# -gt 0 ]; do
                case $1 in
                    --name)    need_arg "$@"; tn=$2; shift ;;
                    -o|--out)  need_arg "$@"; to=$2; shift ;;
                    *) die "Unknown option: $1" ;;
                esac
                shift
            done
            if [ -n "$to" ]; then
                print_template "$tp" "$tn" > "$to"
                ok "Template written: $to"
            else
                print_template "$tp" "$tn"
            fi
            ;;
        batch)
            require_pki
            local bf=(); B_FORCE=0
            while [ $# -gt 0 ]; do
                case $1 in
                    --force) B_FORCE=1 ;;
                    *)       bf+=("$1") ;;
                esac
                shift
            done
            batch_issue "${bf[@]}" || exit $?
            ;;
        *)
            err "Unknown command: '$cmd'"
            usage >&2
            exit 1
            ;;
    esac
}

trap 'err "Unexpected error at line $LINENO: $BASH_COMMAND"' ERR

main() {
    while [ $# -gt 0 ]; do
        case $1 in
            --dir)
                need_arg "$@"
                PKI_DIR=$2
                shift 2
                ;;
            -y|--yes)
                ASSUME_YES=1
                shift
                ;;
            --no-color)
                NO_COLOR=1
                setup_colors
                shift
                ;;
            -h|--help)
                set -- help
                break
                ;;
            *)
                break
                ;;
        esac
    done

    case $PKI_DIR in
        /*) ;;
        *)  PKI_DIR="$PWD/$PKI_DIR" ;;
    esac
    PKI_DIR=${PKI_DIR%/}

    find_openssl
    load_config
    dispatch_cli "$@"
}

main "$@"
