# Amphetamine for Omarchy ☕

A powerful keep-awake utility and Omarchy bar widget inspired by macOS **Amphetamine** and **Caffeine**.

Amphetamine keeps your Omarchy Linux system awake and prevents your laptop from sleeping when the lid is closed—allowing AI coding agents (like **Claude Code** and **Antigravity / `agy`**), long builds, test suites, and downloads to run uninterrupted.

---

## Features

- 💻 **Closed-Display Mode (Lid-Close Sleep Prevention):** Inhibits systemd-logind from suspending when the laptop lid closes, while still letting the display power down to save battery.
- ☕ **Native Omarchy Bar Widget:** Sits neatly in your status bar with an active/dimmed coffee cup icon (`󰛊`).
- ⏱️ **Preset Timers:** Run indefinitely or set sessions for **15m**, **30m**, **1h**, **2h**, or **4h**.
- 🔄 **Quick Cycling:** Left-click to toggle on/off, right-click to cycle presets with instant desktop notifications.
- 🚀 **Agent & Command Runner:** Run `amphetamine run agy` or `amphetamine run claude` to automatically hold sleep inhibition for the exact duration of a command.
- 🔔 **Desktop Notifications:** Visual alerts via `notify-send` when sessions start, switch, or expire.
- 🔒 **Screensaver & Lock Override:** Keeps Omarchy screensaver and lock timers disarmed during active sessions.

---

## Installation

### Via Omarchy Shell Plugin Manager (Recommended)

```bash
omarchy plugin add https://github.com/ChaseC-130/amphetamine.git --enable --yes
```

To move the widget across your bar:
```bash
omarchy bar move chase.amphetamine --section right
```

### Manual Installation / Symlink

Clone or link to your Omarchy plugins directory:
```bash
ln -s ~/Code/amphetamine ~/.config/omarchy/plugins/chase.amphetamine
omarchy-shell shell rescanPlugins
omarchy plugin enable chase.amphetamine
```

Optionally link the CLI binary into your PATH:
```bash
ln -sf ~/.config/omarchy/plugins/chase.amphetamine/bin/amphetamine ~/.local/bin/amphetamine
```

---

## Usage

### Status Bar Controls
- **Left-Click:** Toggle stay-awake indefinitely on or off.
- **Right-Click:** Cycle timer presets: `Off → Indefinite → 15m → 30m → 1h → 2h → 4h → Off`.
- **Hover:** Displays current status, mode, and remaining countdown.

### CLI Controls

```bash
# Keep system awake indefinitely
amphetamine on

# Set a timed session
amphetamine on 30m
amphetamine on 1h
amphetamine on 2h

# Restore normal sleep behavior
amphetamine off

# Toggle between Indefinite and Off
amphetamine toggle

# Cycle presets
amphetamine cycle

# Check status
amphetamine status
amphetamine status --json

# Inhibit sleep only while running a specific command or agent
amphetamine run agy
amphetamine run claude
```

---

## How It Works

1. **Systemd Inhibitor:** Uses `systemd-inhibit --what=sleep:idle:handle-lid-switch` to block system suspension, idle timeouts, and lid-close sleep events at the logind level without requiring root privileges.
2. **Omarchy Integration:** Synchronizes with Omarchy's internal idle inhibitor (`~/.local/state/omarchy/indicators/stay-awake`) so screensavers and auto-locks don't trigger.
3. **Session Watchdog:** Background timer watchdogs automatically release the lock and clean up state when a timed session expires.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
