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
3. Copies the pre-built `dcli-config/` template to `~/.config/dcli`
4. Renames the host template to match your hostname
5. Runs `dcli validate` and `dcli sync` to apply everything

## Repo Structure

```
dcli-config/           ← Complete dcli configuration template
  config.yaml          ← Points to your host file
  hosts/
    template.yaml      ← Generic host config (renamed to <hostname>.yaml during install)
  modules/
    base.yaml          ← Base packages for all hosts
    inir-dots/         ← iNiR desktop shell packages & post-install hook
      module.yaml
      packages.yaml
  scripts/
    inir-post-install.sh
install.sh             ← Installer script
README.md
```

## After install

To re-run the iNiR installer later:

```bash
dcli hooks run
```

## Customizing

Edit the host config at `~/.config/dcli/hosts/<hostname>.yaml` or add new modules under `~/.config/dcli/modules/`.
