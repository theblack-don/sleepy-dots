# sleepy-dots

Declarative dotfiles & system setup for Arch-based systems using [iNiR](https://github.com/snowarch/inir) and [dcli](https://aur.archlinux.org/packages/dcli-arch-git).

## Quick Install

Run this one-liner to clone and execute the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/theblack-don/sleepy-dots/main/install.sh | bash
```

Or, if you prefer `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/theblack-don/sleepy-dots/main/install.sh | bash
```

## Manual Install

```bash
git clone https://github.com/theblack-don/sleepy-dots.git
cd sleepy-dots
./install.sh
```

## What it does

1. Installs **iNiR** (dotfiles manager)
2. Installs **dcli** from the AUR (declarative package/hook manager)
3. Copies the `inir-dots` module and post-install hook into `~/.config/arch-config`
4. Enables the module for your hostname
5. Runs `dcli sync` to apply everything

## After install

To re-run the iNiR installer later:

```bash
dcli hooks run
```
