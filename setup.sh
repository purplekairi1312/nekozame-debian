#!/bin/bash
# nekozame-debian setup: nekozame os's desktop and apps on Debian 13 (trixie) and newer.
# run it again any time: what's done stays done, and it updates what it put in place.
#   on for everyone: niri with DankMaterialShell and nekozame's shortcuts, the nekozame
#   theme (dms, gtk, qt, ghostty, btop, cava, yazi), the catshark wallpaper, the pointer,
#   icons, Nerd Fonts, fastfetch with the bubble logo, the prompt, Zen with the privacy
#   extensions and the nekozame look
#   asked: the wallpaper's logo, fonts, Super as Cmd (xremap), nala fetch, music
#   production, emulators
# your own configs are kept. what this changes is backed up first, to
# ~/.config-backup-nekozame-DATE. the theme and art come from nekozame-os and
# nekozame-theme when you run it: only the Debian glue lives here.
#   ./setup.sh               the questions
#   ./setup.sh --defaults    no questions: the defaults
#   ./setup.sh --no-sudo     nothing as root: the root steps go into a script to run later
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/nekozame"
BIN="$HOME/.local/bin"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nekozame"
OS=https://raw.githubusercontent.com/purplekairi1312/nekozame-os/main
THEME_TAR=https://github.com/purplekairi1312/nekozame-theme/archive/refs/heads/main.tar.gz
BACKUP="$HOME/.config-backup-nekozame-$(date +%F)"
SUDO_SCRIPT="$SHARE/root-steps.sh"
# pinned downloads (what Debian doesn't have), each checked
XREMAP=v0.15.18
XREMAP_SHA=4c12afabd88e9fbe213b30a874710cafd929586bd56bc7d5ea4993c60bdcb3ed
ADW_GTK3=v6.5
ADW_GTK3_SHA=a81780fadfc432be0fc3d89c4ebb41aa28e4f032d42c36f9789c57dd10cfa41c
TELA=2026-07-07
TELA_SHA=0a8aee6e95f19ff96cc497d804c75e2af4271a5e6472c55891fb8ac5b099b59b

DEFAULTS="" NOSUDO=""
for a in "$@"; do
    case "$a" in
        --defaults) DEFAULTS=1 ;;
        --no-sudo) NOSUDO=1 ;;
        *) echo "setup.sh [--defaults] [--no-sudo]" >&2; exit 1 ;;
    esac
done
[ "$(id -u)" -ne 0 ] || { echo "run it as yourself, not root: it asks for your password when it needs it" >&2; exit 1; }
[ -r /etc/debian_version ] || { echo "this is for Debian" >&2; exit 1; }
mkdir -p "$SHARE" "$BIN" "$STATE" "$CONF"
export PATH="$BIN:$PATH"

pink() { if command -v gum >/dev/null; then gum style --foreground "#ffc0e5" --bold "$*"; else printf '\033[1;38;2;255;192;229m%s\033[0m\n' "$*"; fi; }
step() { echo; pink "▸ $*"; }
ok() { echo "  ✓ $*"; }
note() { echo "  · $*"; }
ask() {  # ask QUESTION [false]
    local d="${2:-true}"
    [ -z "$DEFAULTS" ] || { [ "$d" = true ]; return; }
    if command -v gum >/dev/null; then gum confirm --default="$d" "$1"; return; fi
    local yn; read -r -p "  $1 [$( [ "$d" = true ] && echo Y/n || echo y/N )] " yn
    case "${yn:-$( [ "$d" = true ] && echo y || echo n )}" in [Yy]*) return 0 ;; *) return 1 ;; esac
}
choose() {  # choose HEADER DEFAULT OPTION...
    local h=$1 d=$2; shift 2
    [ -z "$DEFAULTS" ] || { echo "$d"; return; }
    if command -v gum >/dev/null; then gum choose --header "$h" --selected="$d" "$@"; return; fi
    local r; read -r -p "  $h ($*) [$d] " r </dev/tty; echo "${r:-$d}"
}
fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }  # fetch URL FILE
sha() { echo "$2  $1" | sha256sum -c --quiet - || { echo "  $1: wrong checksum" >&2; return 1; }; }
# a copy of PATH in the backup folder before anything changes it (once a day: the
# first, untouched one is kept)
backup() {
    local p rel
    for p in "$@"; do
        [ -e "$p" ] || [ -L "$p" ] || continue
        rel="${p#"$HOME"/}"
        [ -e "$BACKUP/$rel" ] || [ -L "$BACKUP/$rel" ] && continue
        mkdir -p "$BACKUP/$(dirname "$rel")"
        cp -a "$p" "$BACKUP/$rel"
    done
}
# root's part: run now with sudo, or (--no-sudo) written down to run later
ROOT_STEPS=0
root() {
    ROOT_STEPS=$((ROOT_STEPS + 1))
    if [ -n "$NOSUDO" ]; then
        [ -s "$SUDO_SCRIPT" ] || printf '#!/bin/bash\n# nekozame-debian: the steps that need root. run: bash %s\nset -euxo pipefail\n' "${SUDO_SCRIPT/#$HOME/\~}" > "$SUDO_SCRIPT"
        { printf 'sudo'; printf ' %q' "$@"; echo; } >> "$SUDO_SCRIPT"
    else
        sudo "$@"
    fi
}
missing() { local p; for p in "$@"; do [ "$(dpkg-query -W -f='${Status}' "$p" 2>/dev/null)" = "install ok installed" ] || echo "$p"; done; }
candidate() { [[ "$(apt-cache policy "$1" 2>/dev/null)" == *"Candidate: "[0-9]* ]]; }
rm -f "$SUDO_SCRIPT"

# in a terminal over ssh or in tmux, the desktop session's variables aren't there: found
# from niri's socket
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [ -z "${NIRI_SOCKET:-}" ]; then
    NIRI_SOCKET=$(ls -t "$XDG_RUNTIME_DIR"/niri.wayland-*.sock 2>/dev/null | head -1) || true
    [ -z "$NIRI_SOCKET" ] || export NIRI_SOCKET
fi
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -n "${NIRI_SOCKET:-}" ]; then
    WAYLAND_DISPLAY=$(basename "$NIRI_SOCKET" | cut -d. -f2) && export WAYLAND_DISPLAY
fi
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
dms_up() { command -v dms >/dev/null && dms ipc call wallpaper get >/dev/null 2>&1; }

echo; pink "nekozame-debian 🦈"
echo "  the defaults are already picked: press enter to keep them."

# ---------------------------------------------------------------- packages (root)
step "Packages: nala, niri, DankMaterialShell and the rest"
codename=$(. /etc/os-release && echo "${VERSION_CODENAME:-}")
if ! command -v nala >/dev/null; then
    # nala: apt with parallel downloads and a readable list of what changes
    root apt-get update
    root apt-get install -y nala
fi
if [ -s /etc/apt/sources.list.d/fetch.sources ]; then
    ok "nala fetch: fast mirrors already picked"
elif ask "Pick the fastest Debian mirrors (nala fetch)?" false; then
    root nala fetch --auto --fetches 3 -y
fi

# DankMaterialShell, niri and quickshell, the way dms's own guide says for Debian:
# its developers' repos on the openSUSE build service, signed (duxlabs.dev/docs/dms/installation).
# a machine that already has them from there (also under their older AvengeMedia
# name) keeps its repos
repos_new=""
mkdir -p "$SHARE/apt"
if ! candidate dms; then
    dist=Debian_13; [ "$codename" = trixie ] || dist=Debian_Testing
    for r in dux-repo dms; do
        fetch "https://download.opensuse.org/repositories/home:/duxlabs-dev:/$r/$dist/Release.key" "$SHARE/apt/$r.key"
        echo "deb [signed-by=/etc/apt/keyrings/home-duxlabs-dev-$r.gpg] https://download.opensuse.org/repositories/home:/duxlabs-dev:/$r/$dist/ /" \
            > "$SHARE/apt/home-duxlabs-dev-$r.list"
        root install -d -m 0755 /etc/apt/keyrings
        root gpg --batch --yes --dearmor -o "/etc/apt/keyrings/home-duxlabs-dev-$r.gpg" "$SHARE/apt/$r.key"
        root install -m 0644 "$SHARE/apt/home-duxlabs-dev-$r.list" /etc/apt/sources.list.d/
    done
    repos_new=1
fi
# quickshell: Debian's own (trixie-backports on 13), as dms's guide says. one already
# installed stays
if [ -n "$(missing quickshell)" ] && [ "$codename" = trixie ]; then
    if ! grep -rqs 'trixie-backports' /etc/apt/sources.list /etc/apt/sources.list.d/; then
        echo "deb http://deb.debian.org/debian trixie-backports main" > "$SHARE/apt/trixie-backports.list"
        root install -m 0644 "$SHARE/apt/trixie-backports.list" /etc/apt/sources.list.d/
    fi
    root nala update
    root nala install -y -t trixie-backports quickshell
    repos_new=""
fi
[ -z "$repos_new" ] || root nala update

WANT=(niri dms xwayland-satellite xdg-desktop-portal-gnome xdg-desktop-portal-gtk
    ghostty fastfetch cava btop gum ffmpeg jq curl git python3 unzip xz-utils fontconfig
    qt-style-kvantum qt6ct qt5ct thunar grim wl-clipboard flatpak fonts-noto-color-emoji)
mapfile -t need < <(missing "${WANT[@]}")
if [ ${#need[@]} -gt 0 ]; then
    root nala install -y "${need[@]}"
else
    ok "all there"
fi

# dms starts with niri (and only with niri), as its guide says
if [ -f /usr/lib/systemd/user/dms.service ] && ! systemctl --user is-enabled -q dms.service 2>/dev/null \
    && [ ! -e "$CONF/systemd/user/niri.service.wants/dms.service" ]; then
    systemctl --user add-wants niri.service dms.service && ok "dms starts with niri"
fi

# ---------------------------------------------------------------- the files
step "The nekozame theme and art (from nekozame-theme and nekozame-os)"
backup "$CONF/niri" "$CONF/dms" "$CONF/ghostty" "$CONF/cava" "$CONF/btop" "$CONF/fastfetch" \
    "$CONF/gtk-3.0" "$CONF/gtk-4.0" "$CONF/qt5ct" "$CONF/qt6ct" "$CONF/Kvantum" \
    "$CONF/environment.d" "$CONF/yazi" "$CONF/nekozame" "$HOME/.bashrc" \
    "$HOME/.local/share/icons/default"
if command -v gsettings >/dev/null; then
    mkdir -p "$BACKUP"
    [ -e "$BACKUP/gsettings-interface.txt" ] || gsettings list-recursively org.gnome.desktop.interface > "$BACKUP/gsettings-interface.txt" 2>/dev/null || true
fi
if dms_up && [ ! -e "$BACKUP/dms-wallpaper.txt" ]; then
    mkdir -p "$BACKUP" && dms ipc call wallpaper get > "$BACKUP/dms-wallpaper.txt" 2>/dev/null || true
fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fetch "$THEME_TAR" "$tmp/theme.tar.gz" && tar -xzf "$tmp/theme.tar.gz" -C "$tmp"
T="$tmp/nekozame-theme-main/themes"
O="$SHARE/os"
mkdir -p "$O"
# where nekozame os keeps them (build.sh), under ~/.local/share/nekozame/os
install -Dm0644 "$T/ghostty/nekozame" "$CONF/ghostty/themes/nekozame"
install -Dm0644 "$T/btop/nekozame.theme" "$CONF/btop/themes/nekozame.theme"
install -Dm0644 "$T/cava/config" "$O/cava/config"
install -Dm0644 "$T/dms/nekozame.json" "$O/dms/nekozame.json"
install -Dm0644 "$T/darkreader/nekozame.json" "$O/darkreader/nekozame.json"
install -Dm0644 "$T/improvedtube/nekozame.json" "$O/improvedtube/nekozame.json"
install -Dm0644 "$T/zen/userChrome.css" "$O/zen/userChrome.css"
install -Dm0644 "$T/zen/userContent.css" "$O/zen/userContent.css"
install -Dm0644 "$T/gtk/gtk-3.0/gtk.css" "$O/gtk/gtk-3.0.css"
install -Dm0644 "$T/gtk/gtk-4.0/gtk.css" "$O/gtk/gtk-4.0.css"
install -Dm0644 "$T/qt/nekozame.conf" "$O/qt/nekozame.conf"
install -Dm0644 "$T/yazi/theme.toml" "$O/yazi/theme.toml"
mkdir -p "$CONF/Kvantum/nekozame" && install -m0644 "$T"/kvantum/nekozame/* "$CONF/Kvantum/nekozame/"
rm -rf "$HOME/.local/share/icons/nekozame-cursors"
mkdir -p "$HOME/.local/share/icons" && cp -a "$T/cursors/nekozame" "$HOME/.local/share/icons/nekozame-cursors"
for f in niri/binds.kdl colors.sh LICENSE-ART fastfetch/config.jsonc fastfetch/logo.png \
         fastfetch/logo-color.txt fastfetch/logo-tty.txt fonts/code.png fonts/interface.png \
         xremap/config.yml zen/policies/policies.json; do
    mkdir -p "$(dirname "$O/$f")" && fetch "$OS/system_files/usr/share/nekozame-os/$f" "$O/$f"
done
# fastfetch: the line about the os image is nekozame os's own (rpm-ostree)
sed -i '/nekozame-fetch-image/d' "$O/fastfetch/config.jsonc"
# nekozame os's commands, with its paths changed to these
for c in nekozame-wallpaper nekozame-dms-defaults nekozame-look nekozame-fonts nekozame-display \
         nekozame-fetch nekozame-apps-theme kitty-logo; do
    fetch "$OS/system_files/usr/bin/$c" "$tmp/$c"
    sed -e "s|/usr/share/nekozame-os|$O|g" \
        -e "s|/usr/share/backgrounds/nekozame|$SHARE/backgrounds|g" \
        -e "s|/usr/bin/nekozame-fetch|$BIN/nekozame-fetch|g" \
        -e "s|/usr/share/themes/adw-gtk3-dark|$HOME/.local/share/themes/adw-gtk3-dark|g" \
        -e "s|/usr/share/%s/colors/nekozame.conf|$O/qt/nekozame.conf|g" \
        -e "s|ujust nekozame-|nekozame-|g" "$tmp/$c" > "$BIN/$c"
    chmod 0755 "$BIN/$c"
done
ok "in ${SHARE/#$HOME/~} and ${BIN/#$HOME/~}"

# ---------------------------------------------------------------- niri
step "niri: DankMaterialShell's config with nekozame's shortcuts"
N="$CONF/niri/config.kdl"
if [ ! -f "$N" ] && command -v dms >/dev/null; then
    dms setup headless --compositor niri --no-systemd || true
    # dms starts as a service with niri: not from niri's config too (two bars)
    [ -f "$N" ] && sed -i 's|^spawn-at-startup "dms" "run"|// dms starts as a service: spawn-at-startup "dms" "run"|' "$N"
fi
# dms's own welcome tour: this sets dms up instead
mkdir -p "$CONF/dms" && touch "$CONF/dms/.firstlaunch"
if [ -f "$N" ]; then
    cp "$N" "$tmp/config.kdl.before"
    sed -i -E "s|^include( optional=true)? \"dms/binds.kdl\".*|include \"$O/niri/binds.kdl\"  // nekozame shortcuts (was dms/binds.kdl)|" "$N"
    if grep -qF "$O/niri/binds.kdl" "$N"; then
        if command -v niri >/dev/null && ! niri validate -c "$N" >/dev/null 2>&1; then
            cp "$tmp/config.kdl.before" "$N"
            note "niri didn't take nekozame's shortcuts with your config: yours stay (niri validate says why)"
        else
            ok "Super for apps and windows, Alt+1-9 workspaces. Super+Shift+/ shows them all"
        fi
    else
        note "your niri config has no dms/binds.kdl include: add  include \"$O/niri/binds.kdl\"  for nekozame's shortcuts"
    fi
else
    note "no niri config yet: log in to niri once, then run this again"
fi
# qt apps under niri get kvantum through qt6ct (from the next login)
mkdir -p "$CONF/environment.d"
echo 'QT_QPA_PLATFORMTHEME=qt6ct' > "$CONF/environment.d/60-nekozame-qt.conf"

# ---------------------------------------------------------------- the pointer
step "The pointer: the trans flag, glossy like the bubble"
size=32
cur="$CONF/niri/dms/cursor.kdl"
if [ -f "$cur" ] && grep -q 'xcursor-theme "nekozame-cursors"' "$cur"; then
    size=$(sed -n 's/^ *xcursor-size \([0-9]*\)/\1/p' "$cur"); size=${size:-32}
fi
mkdir -p "$(dirname "$cur")"
printf '// nekozame-display\ncursor {\n    xcursor-theme "nekozame-cursors"\n    xcursor-size %s\n}\n' "$size" > "$cur"
# dms writes cursor.kdl from its own settings: nekozame's go there too
s="$CONF/dms/settings.json"
if [ -f "$s" ] && jq -e . "$s" >/dev/null 2>&1; then
    jq --argjson n "$size" '.cursorSettings = ((.cursorSettings // {}) + {theme: "nekozame-cursors", size: $n})' "$s" > "$s.new" && mv "$s.new" "$s"
fi
mkdir -p "$HOME/.local/share/icons/default"
[ -e "$HOME/.local/share/icons/default/index.theme" ] && ! grep -q nekozame-cursors "$HOME/.local/share/icons/default/index.theme" \
    || printf '[Icon Theme]\nInherits=nekozame-cursors\n' > "$HOME/.local/share/icons/default/index.theme"
gsettings set org.gnome.desktop.interface cursor-theme nekozame-cursors 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size "$size" 2>/dev/null || true
printf '# the mouse pointer, for apps that draw their own (nekozame-display)\nXCURSOR_THEME=nekozame-cursors\nXCURSOR_SIZE=%s\n' "$size" \
    > "$CONF/environment.d/60-nekozame-cursor.conf"
ok "nekozame-cursors at $size (nekozame-display changes the size)"

# ---------------------------------------------------------------- icons and gtk theme
step "Icons (Tela circle, pink) and adw-gtk3 for gtk 3 apps"
if [ ! -d "$HOME/.local/share/icons/Tela-circle-pink-dark" ]; then
    fetch "https://github.com/vinceliuice/Tela-circle-icon-theme/archive/refs/tags/$TELA.tar.gz" "$tmp/tela.tar.gz"
    sha "$tmp/tela.tar.gz" "$TELA_SHA"
    tar -xzf "$tmp/tela.tar.gz" -C "$tmp"
    (cd "$tmp/Tela-circle-icon-theme-$TELA" && ./install.sh -c -d "$HOME/.local/share/icons" pink >/dev/null)
fi
case "$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null)" in  # unless you picked your own
    "'Adwaita'"|"'breeze'"|"'breeze-dark'"|"'Tela-pink-dark'"|"") gsettings set org.gnome.desktop.interface icon-theme Tela-circle-pink-dark 2>/dev/null || true ;;
esac
if [ "$(cat "$HOME/.local/share/themes/.adw-gtk3-version" 2>/dev/null)" != "$ADW_GTK3" ]; then
    fetch "https://github.com/lassekongo83/adw-gtk3/releases/download/$ADW_GTK3/adw-gtk3$ADW_GTK3.tar.xz" "$tmp/adw.tar.xz"
    sha "$tmp/adw.tar.xz" "$ADW_GTK3_SHA"
    mkdir -p "$HOME/.local/share/themes"
    rm -rf "$HOME/.local/share/themes/adw-gtk3" "$HOME/.local/share/themes/adw-gtk3-dark"
    tar -xJf "$tmp/adw.tar.xz" -C "$HOME/.local/share/themes"
    echo "$ADW_GTK3" > "$HOME/.local/share/themes/.adw-gtk3-version"
fi
ok "Tela circle pink, adw-gtk3 $ADW_GTK3"

# ---------------------------------------------------------------- gtk, qt, yazi, thunar
step "nekozame in gtk and qt apps, yazi and thunar"
# what dms generated from a wallpaper (matugen) or a stock file isn't yours: nekozame's
# goes in its place (it's in the backup). files you wrote stay
generated() {  # generated FILE: made by dms/matugen, or the stock one
    grep -qsE 'DMS OVERRIDE|dank-colors\.css|DankMatugen|Generated with Matugen' "$1"
}
for f in "$CONF/gtk-3.0/gtk.css" "$CONF/gtk-4.0/gtk.css" "$CONF/qt6ct/qt6ct.conf" "$CONF/qt5ct/qt5ct.conf"; do
    generated "$f" && rm -f "$f"
done
nekozame-look 2> >(grep -v 'No such file or directory' >&2)

# ---------------------------------------------------------------- terminal apps
step "Ghostty, btop, cava and fastfetch"
g="$CONF/ghostty/config"
if [ ! -f "$g" ]; then
    printf 'theme = nekozame\n' > "$g"
elif grep -q '^theme *= *dankcolors' "$g"; then
    # dms's own ghostty config: nekozame's colours, and see-through like the theme says
    sed -i -e 's/^theme *= *dankcolors/theme = nekozame/' \
           -e 's/^background-opacity = 1.0$/# background-opacity = 1.0  (nekozame: the theme'"'"'s, see-through)/' "$g"
elif ! grep -q '^theme *=' "$g"; then
    printf '\ntheme = nekozame\n' >> "$g"
fi
grep -q '^theme *= *nekozame' "$g" && ok "ghostty" || note "ghostty has your theme: nekozame is in its themes"
b="$CONF/btop/btop.conf"
if [ ! -f "$b" ]; then
    printf 'color_theme = "nekozame"\n' > "$b"
elif grep -q '^color_theme = "Default"' "$b"; then
    sed -i 's/^color_theme = "Default"/color_theme = "nekozame"/' "$b"
fi
grep -q '^color_theme = "nekozame"' "$b" && ok "btop" || note "btop has your theme: nekozame is in its themes"
c="$CONF/cava/config"
# cava's own sample config, nothing changed in it, isn't yours
if [ -f "$c" ] && head -1 "$c" | grep -q '^## Configuration file for CAVA' \
    && ! grep -vE '^\s*([#;].*)?$|^\s*\[[a-z]+\]\s*$' "$c" | grep -q .; then
    rm -f "$c"
fi
if [ ! -e "$c" ]; then
    install -Dm0644 "$O/cava/config" "$c"; ok "cava"
else note "${c/#$HOME/~} is yours, kept"; fi
if [ ! -e "$CONF/fastfetch/config.jsonc" ]; then
    install -Dm0644 "$O/fastfetch/config.jsonc" "$CONF/fastfetch/config.jsonc"
fi
ok "fastfetch, with the bubble logo where the terminal shows pictures"

# ---------------------------------------------------------------- the shell
step "bash: the prompt, fastfetch and cava"
install -Dm0644 "$HERE/shell/nekozame.bash" "$CONF/nekozame/nekozame.bash"
line='[ -f ~/.config/nekozame/nekozame.bash ] && . ~/.config/nekozame/nekozame.bash  # nekozame-debian'
if ! grep -qF 'nekozame/nekozame.bash' "$HOME/.bashrc" 2>/dev/null; then
    if grep -qE '^\s*(fastfetch|neofetch)\s*$' "$HOME/.bashrc" 2>/dev/null; then
        # before the fastfetch you run at the start, so that one has the logo
        n=$(grep -nE '^\s*(fastfetch|neofetch)\s*$' "$HOME/.bashrc" | head -1 | cut -d: -f1)
        sed -i "${n}i $line" "$HOME/.bashrc"
    else
        printf '\n%s\n' "$line" >> "$HOME/.bashrc"
    fi
fi
ok "~/.bashrc sources ~/.config/nekozame/nekozame.bash (NEKOZAME_PROMPT=off keeps your prompt)"

# ---------------------------------------------------------------- fonts
step "Fonts: the interface's and code's (Nerd Fonts)"
if [ -s "$CONF/nekozame/fonts" ] && [ -n "$DEFAULTS" ]; then
    ok "set (change them: nekozame-fonts)"
elif [ -n "$DEFAULTS" ] || ! command -v gum >/dev/null; then
    nekozame-fonts system jetbrains || true
else
    nekozame-fonts || true
fi

# ---------------------------------------------------------------- dms and the wallpaper
step "DankMaterialShell: the nekozame theme and the catshark wallpaper"
variant=$(choose "Wallpaper: the nekozame logo on it, small, big or none (just the catshark)" small small big none)
mkdir -p "$SHARE/backgrounds"
for a in 32x9 21x9 16x9 16x10 3x2 4x3 5x4; do
    [ -s "$SHARE/backgrounds/$variant-$a.mkv" ] || fetch "$OS/system_files/usr/share/backgrounds/nekozame/$variant-$a.mkv" "$SHARE/backgrounds/$variant-$a.mkv"
done
cp "$O/LICENSE-ART" "$SHARE/backgrounds/LICENSE-ART"
mkdir -p "$CONF/nekozame" && echo "$variant" > "$CONF/nekozame/wallpaper"
if dms_up; then
    again=true; [ ! -e "$STATE/dms-defaults" ] || again=false  # done before: a theme you picked since stays
    if ask "The nekozame theme in DankMaterialShell (in place of the one it has now)?" "$again"; then
        NEKOZAME_WALLPAPER=$variant nekozame-dms-defaults --force && ok "theme, and the $variant wallpaper"
    else
        NEKOZAME_WALLPAPER=$variant nekozame-wallpaper && ok "the $variant wallpaper"
    fi
    mkdir -p "$STATE" && touch "$STATE/dms-defaults"
else
    # on the next niri login (dms has to be running for it)
    note "dms isn't running: the theme and wallpaper go in on your next niri login"
    if [ -f "$N" ] && ! grep -q nekozame-dms-defaults "$N"; then
        printf '\n// nekozame-debian: theme + wallpaper in dms, once (nekozame-dms-defaults)\nspawn-at-startup "%s"\n' "$BIN/nekozame-dms-defaults" >> "$N"
    fi
fi

# ---------------------------------------------------------------- zen
step "Zen, ready for privacy"
if ! flatpak info app.zen_browser.zen >/dev/null 2>&1; then
    root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    root flatpak install -y --system flathub app.zen_browser.zen
fi
# nekozame's policies (dark reader, ublock origin, privacy badger, libredirect, clearurls,
# consent-o-matic, duckduckgo, https-only, no telemetry, no webrtc leaks), through
# zen's systemconfig extension point, like nekozame os
P=/usr/local/share/nekozame-debian/zen
E=/var/lib/flatpak/extension/app.zen_browser.zen.systemconfig/x86_64/stable
if ! cmp -s "$O/zen/policies/policies.json" "$P/policies/policies.json" || [ "$(readlink "$E" 2>/dev/null)" != "$P" ]; then
    root install -Dm0644 "$O/zen/policies/policies.json" "$P/policies/policies.json"
    root mkdir -p "$(dirname "$E")"
    root ln -sfn "$P" "$E"
fi
nekozame-apps-theme zen

# ---------------------------------------------------------------- optional
step "Shortcuts: Super works like Cmd on a Mac (Super+C/V/X/Z in every app)"
if ask "Turn on Super as Cmd? (xremap, which reads the keyboard)"; then
    if [ "$("$BIN/xremap" --version 2>/dev/null | awk '{print $2}')" != "${XREMAP#v}" ]; then
        fetch "https://github.com/xremap/xremap/releases/download/$XREMAP/xremap-linux-x86_64-niri.zip" "$tmp/xremap.zip"
        sha "$tmp/xremap.zip" "$XREMAP_SHA"
        python3 -m zipfile -e "$tmp/xremap.zip" "$tmp/xremap"
        install -m 0755 "$tmp/xremap/xremap" "$BIN/xremap"
    fi
    mkdir -p "$CONF/systemd/user"
    fetch "$OS/system_files/usr/lib/systemd/user/nekozame-keys.service" "$tmp/keys.service"
    sed -e "s|/usr/bin/xremap|$BIN/xremap|g" -e "s|/usr/share/nekozame-os|$O|g" \
        -e 's|(nekozame-setup adds you)|(setup.sh adds you)|' "$tmp/keys.service" > "$CONF/systemd/user/nekozame-keys.service"
    systemctl --user daemon-reload
    systemctl --user add-wants niri.service nekozame-keys.service >/dev/null 2>&1 || true
    # xremap reads the keyboard and types through uinput: the input group may do both
    if ! id -nG | grep -qw input; then
        root usermod -aG input "$USER"
    fi
    if [ ! -f /etc/udev/rules.d/70-nekozame-uinput.rules ]; then
        fetch "$OS/system_files/usr/lib/udev/rules.d/70-nekozame-uinput.rules" "$SHARE/70-nekozame-uinput.rules"
        echo uinput > "$SHARE/nekozame-uinput.conf"
        root install -m 0644 "$SHARE/70-nekozame-uinput.rules" /etc/udev/rules.d/
        root install -m 0644 "$SHARE/nekozame-uinput.conf" /etc/modules-load.d/
        root modprobe uinput
        root udevadm control --reload
        root udevadm trigger --name-match=uinput
    fi
    ok "from your next login (the input group needs one)"
fi

step "Music production"
if ask "Set up music production? (DAWs, free plugins, low-latency audio)" false; then
    picks=$(gum choose --no-limit --header "Pick (space), then enter:" \
        "ardour (free software DAW)" "lmms (free software DAW)" "carla (free software plugin host)" \
        "surge-xt (free software synth)" "zynaddsubfx (free software synth)" "x42-plugins (free software)" \
        "lsp-plugins (free software)" "calf-plugins (free software)" "dragonfly-reverb (free software)" \
        "hydrogen (free software drum machine)" 2>/dev/null || true)
    mapfile -t mp < <(printf '%s\n' "$picks" | awk 'NF {print $1}')
    [ ${#mp[@]} -eq 0 ] || root nala install -y "${mp[@]}"
    # 48k by default, buffers down to 32 samples when an app asks (nekozame os's)
    mkdir -p "$CONF/pipewire/pipewire.conf.d"
    fetch "$OS/system_files/usr/share/pipewire/pipewire.conf.d/50-nekozame-lowlatency.conf" \
        "$CONF/pipewire/pipewire.conf.d/50-nekozame-lowlatency.conf"
    printf '@audio  -  rtprio   95\n@audio  -  nice     -19\n@audio  -  memlock  unlimited\n' > "$SHARE/95-nekozame-audio.conf"
    [ -f /etc/security/limits.d/95-nekozame-audio.conf ] || root install -m 0644 "$SHARE/95-nekozame-audio.conf" /etc/security/limits.d/
    id -nG | grep -qw audio || root usermod -aG audio "$USER"
    ok "low latency from the next login. Bitwig and Reaper: from bitwig.com and reaper.fm"
fi

step "Emulation"
if ask "Install emulators from Flathub?" false; then
    picks=$(gum choose --no-limit --header "Pick (space), then enter:" \
        "org.libretro.RetroArch" "org.DolphinEmu.dolphin-emu" "net.pcsx2.PCSX2" "org.duckstation.DuckStation" \
        "org.ppsspp.PPSSPP" "net.kuribo64.melonDS" "org.azahar_emu.Azahar" "net.rpcs3.RPCS3" "info.cemu.Cemu" \
        "app.xemu.xemu" "org.flycast.Flycast" 2>/dev/null || true)
    mapfile -t em < <(printf '%s\n' "$picks" | awk 'NF')
    [ ${#em[@]} -eq 0 ] || root flatpak install -y --system flathub "${em[@]}"
    echo "  nekozame's frontend and the rest: https://github.com/purplekairi1312/nekozame-emu-frontend"
fi

echo; pink "all set <3"
echo "  your configs as they were: ${BACKUP/#$HOME/~}"
if [ -n "$NOSUDO" ] && [ $ROOT_STEPS -gt 0 ]; then
    echo "  the steps that need root, to run once (it asks for your password):"
    echo "    bash ${SUDO_SCRIPT/#$HOME/~}"
fi
echo "  Super+Shift+/ shows the shortcuts. log out and back in once for everything."
