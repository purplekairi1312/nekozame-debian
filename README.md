# nekozame-debian

nekozame os's desktop and apps, for Debian GNU/Linux 13 (trixie) and newer.

- [niri](https://github.com/YaLTeR/niri) with [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), from DMS's own Debian repos, the way its guide says
- nekozame os's shortcuts: Super for apps and windows, Alt+1-9 for workspaces. Super+Shift+/ shows every shortcut. Super+C/V/X work like Cmd on a Mac if you want (xremap)
- The animated catshark wallpaper, sharp on any screen shape, with the nekozame logo small, big or not at all <3
- The [nekozame theme](https://git.sr.ht/~purplekairi1312/nekozame-theme) in DMS, GTK and Qt apps, Ghostty (see-through), btop, cava, yazi and Thunar, with the trans flag pointer and pink Tela circle icons
- Nerd Fonts everywhere, so icons show in the terminal and the bar. OpenDyslexic for the interface if you want it
- fastfetch with the bubble logo, and a prompt in the same colours
- Zen, ready for privacy: Dark Reader, uBlock Origin, Privacy Badger, LibRedirect, ClearURLs, Consent-O-Matic, DuckDuckGo, HTTPS-only, no telemetry, no WebRTC leaks. Zen in nekozame too
- [nala](https://gitlab.com/volian/nala) for packages: parallel downloads and a clear list of what changes
- Music production and emulators on request

The theme and art come from [nekozame-os](https://github.com/purplekairi1312/nekozame-os) and nekozame-theme when you install, so each project keeps its own files. Only the Debian part lives here.

## Install

```sh
git clone https://git.sr.ht/~purplekairi1312/nekozame-debian ~/.local/share/nekozame-debian
~/.local/share/nekozame-debian/setup.sh
```

That downloads it with git and runs the setup. It asks about the optional bits and for your password when it installs packages. It keeps your own configs, and backs up what it changes to `~/.config-backup-nekozame-DATE` first. Run it again to update. Then log out and back in once.

`setup.sh --defaults` takes the defaults without asking. `setup.sh --no-sudo` changes nothing as root and writes those steps to `~/.local/share/nekozame/root-steps.sh` to run later.

## License

GPL-3.0-or-later. The wallpaper and logo are nekozame art, CC BY-NC-SA 4.0, downloaded when you install.
