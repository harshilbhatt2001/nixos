# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A NixOS flake for a single machine (`anton`), built on the **dendritic pattern**: `flake.nix` is a stub whose only job is to hand `./modules` to `import-tree`, which recursively auto-imports **every `.nix` file** under it as a flake-parts module. There is no explicit import list anywhere — adding a file to `modules/` wires it in, deleting it unwires it.

Non-`.nix` files (e.g. `modules/features/otter-launcher/config.toml`, the wallpapers) are ignored by import-tree and exist only to be referenced from Nix code.

## Commands

```bash
nix flake check    # evaluate everything
nix flake show     # list outputs
nix build .#kitty  # build one wrapped package

# evaluate the whole system closure without building or activating it
nix eval .#nixosConfigurations.anton.config.system.build.toplevel.drvPath

sudo nixos-rebuild switch --flake .#anton   # apply to the running system
sudo nixos-rebuild build  --flake .#anton   # build, don't activate
```

Prefer `flake check` or the `eval ... drvPath` line above when verifying a change — both force full evaluation and catch every error a rebuild would, without touching the running system.

`devenv.nix` at the repo root is the development shell for working *on* this repo (auto-activated by the fish hook, or `devenv shell`): nixd, `nom`/`nvd`/`nix-tree`, difftastic wired into `git diff`, and git hooks (alejandra, deadnix, statix with `statix.toml`, merge-conflict check) that also run after every Claude Code edit via devenv's `claude.code` integration. Scripts: `rebuild-diff` builds `.#nixosConfigurations.$(hostname)` and shows the package-level diff against the running system (it runs `desk-status` first); `desk-status` reports uncommitted/unpushed work in this repo, `~/.config/hypr` and `~/.config/quickshell`. `.mcp.json` and `.claude/settings.json` are generated store symlinks, not tracked. `env.NVIM_COLORSCHEME` there picks the wrapped neovim's colourscheme (read by `init.lua` in the `nvim` input).

`networking.hostName` matches the flake attribute, so bare `nixos-rebuild switch --flake .` also resolves to `anton`. Keep the two in sync if either is renamed.

`nix flake show` / `flake check` rewrite `flake.lock` if inputs in `flake.nix` are unlocked — read the lock diff Nix prints before moving on.

This repo is a git repository, and that matters for evaluation: Nix only sees **tracked** files (plus staged/modified ones). An untracked file under `modules/` is invisible to import-tree until `git add` — a new module that "mysteriously" has no effect is usually just untracked.

## Module conventions

Every file under `modules/` must be a **flake-parts module**, not a bare NixOS module. The two are not interchangeable, and confusing them is the main failure mode here: a plain NixOS module dropped into `modules/` fails with `error: infinite recursion encountered` on `modulesPath`, which does not point at the real cause.

This matters most after re-running `nixos-generate-config`, which emits plain NixOS modules. Wrap the generated body rather than dropping it in as-is (`modules/hosts/anton/hardware.nix` is the wrapped copy).

The established shape is: define a named NixOS module under the `flake.nixosModules.*` output, then reference it by name from elsewhere.

```nix
{ self, inputs, ... }: {
  flake.nixosModules.<name> = { pkgs, lib, ... }: {
    # ...ordinary NixOS options go in here, one level down
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.<pkgName> = ...;   # per-system outputs go under perSystem
  };
}
```

Cross-references between files always go through flake outputs, never relative paths:

- `self.nixosModules.<name>` — another module in this repo (`modules/hosts/anton/default.nix` composes the whole system this way).
- `self'.packages.<name>` — a package from `perSystem` on the *current* system (`modules/features/hyprland/default.nix` uses this for its runtime programs).
- `self.lib.<name>` — repo-local data and helpers (`keymap`, `user`, `installFeature`). `flake.lib` is **declared** in `modules/parts.nix` as a mergeable `lazyAttrsOf raw`: undeclared flake outputs must be defined exactly once, so without that declaration a second file setting `flake.lib.<x>` fails with "defined multiple times while it's expected to be unique". Anything that names the login user reads `self.lib.user` (`name`, `description`, `home`), defined in `system/core/user.nix` — flake-level rather than a NixOS option so perSystem packages can use it too.
- `moduleWithSystem ({ self' }: { ... })` — the bridge from a NixOS module to `self'.packages.*` / `inputs'.*`; it's a flake-parts helper available as a top-level module arg alongside `self`/`inputs`. (`self.packages.${pkgs.stdenv.hostPlatform.system}.<name>` works too, but `moduleWithSystem` is the house style.)

Because names are the wiring, a typo or a not-yet-written module is an evaluation error, not a missing-file error.

`modules/parts.nix` sets `systems = [ "x86_64-linux" ]`. This is load-bearing: with no `systems`, `perSystem` silently yields *no* outputs, so `packages` disappears and every `self'.packages.*` reference dangles — while `nixosConfigurations` still appears to evaluate fine. It's Linux-only because the wrapped desktop packages (hyprland) aren't built for darwin, which would fail `nix flake check`.

## Architecture

`~/ws-linux/nixos-reference` (the "Voidarc" dendritic config) is the reference for how this repo is developed. Same stack — flake-parts + import-tree + nix-wrapper-modules (input name `wrappers`) — and the same layered module taxonomy, which this repo now follows.

```
flake.nix ─── import-tree ./modules ──▶ every .nix file is a flake-parts module

modules/
├── parts.nix          systems = [ ... ]; declares flake.lib (mergeable)
│
├── hosts/<HOST>/      flake.nixosConfigurations.<HOST>
│                      = nixosSystem { modules = with self.nixosModules; [ ... ] }
│                      + <host>Configuration: hostname, stateVersion, boot,
│                        disks, GPU order — host-only facts
│
├── attrs/<bundle>/    nixosModules.<bundle>    composition only — imports other
│                      (development…)           nixosModules + plain pkgs, no new
│                                               features defined here
│
├── system/<area>/     nixosModules.<area>      base system; may import feature
│                      core/ desktop/ drivers/  modules but never defines a
│                      network/ audio/          wrapper (boot, users, locale,
│                      systemTheme/ nix-ld/     network, audio, gpu, theme, fonts)
│
└── features/<app>/    nixosModules.<app>       one folder per app: the NixOS
                       + perSystem packages     module AND the wrapped binary
                       .<app>                   it installs
```

How the host composes, and where packages come from:

```
nixosConfigurations.anton                  (hosts/anton/default.nix)
   │  lists modules by name only: with self.nixosModules; [ ... ]
   │
   ├── antonConfiguration                  hostname, stateVersion, Limine/Secure
   │                                       Boot, disks, AQ_DRM_DEVICES
   ├── antonHardware                       wrapped nixos-generate-config scan
   ├── system:   desktop ──imports──▶ core ──▶ user, nix-settings, locale, …
   │             desktop also imports network, audio, systemTheme, sddm and
   │             the app features (zen-browser, kitty, way-edges, ytmdesktop,
   │             hyprland)
   ├── also:     fish, nix-ld, amdDrivers, intelDrivers, ddcci
   ├── attrs:    development ──imports──▶ devenv, git, lazygit, neovim
   └── features: hyprland = moduleWithSystem ({ self' }: ...)
                    │        programs.hyprland.package = self'.packages.hyprland
                    ▼
                 perSystem.packages.hyprland = the hypr flake's wrapper,
                    .override { runtimePackages = { kitty = self'.packages.kitty; … }; }
                    │        every program the lua config launches by name,
                    ▼        linked into /run/hypr-runtime-env/bin
                 nix run .#kitty etc. work standalone on any machine
```

Conventions (from the reference):

- **Layering**: wrappers are *defined* only in `features/`; `system/` never defines a wrapped package, but `system/desktop` may compose feature modules (as the reference's does). `attrs/` never defines anything new (imports + plain `environment.systemPackages` only). A host file is just a module list. A module shouldn't rely on another module importing something for it — e.g. the theme and fonts are imported by `desktop`, not by `hyprland`, so they don't vanish with the DE.
- One folder in `features/` per app; folder name = package name = module name. Every feature with a package is independently runnable: `nix run .#<app>`. A feature whose module only installs its package uses `self.lib.installFeature "<app>"` (see `modules/lib/`).
- Host-specific facts (hostname, stateVersion, boot chain, partition UUIDs, GPU PCI addresses) live only in `hosts/<HOST>/`; everything else must stay host-agnostic so a second host (a laptop is planned) can reuse it.

Deliberate differences from the reference: hardware config is tracked in-repo (`hosts/anton/hardware.nix`) instead of the impure `/etc/nixos/hardware-configuration.nix` import — no `--impure` here, and that's better. Single host (`anton`) and `systems = [ "x86_64-linux" ]` for now.

### Flake inputs

Everything follows the system `nixpkgs` — `wrappers`, `zen-browser`, `otter-launcher`, the `hyprland` fork and its sub-inputs, including hyprwm's Hyprland itself (so the compositor links the system mesa). There is no Hyprland binary cache configured, so a Hyprland bump builds it from source. `nvim` deliberately keeps its own locked nixpkgs (it only shares `wrappers`). Adding an input: give it `inputs.nixpkgs.follows = "nixpkgs"` unless there's a reason not to, and check `flake.lock` for new `nixpkgs_N` nodes.

### Desktop

Hyprland is the only session (niri and noctalia were removed). SDDM (`features/sddm`, catppuccin-themed, X11 greeter — which is why `services.xserver.enable` stays) is the display manager.

- **`hyprland`** (`features/hyprland/`) — the reference's custom DE. The `hyprland` flake input is the user's fork of the reference author's config repo + wrapper flake, which provides the wrapped binary. `runtimePackages` is spelled out explicitly (this repo's wrapped `quickshell`/`otter-launcher`/`wlogout`/`wpaperd`/`kitty`/`way-edges`/`zen`/`grimblast`/`ytmdesktop`, plus `playerctl`, `nemo`, `hyprpolkitagent`) rather than trimmed from the fork's `defaultRuntimePkgs`, so nothing leaks in from upstream. The portal comes from the same hyprwm flake (`portalPackage`), and `programs.hyprlock.enable` gives hyprlock its PAM service (wlogout's lock button).
- **Out-of-store configs.** `hyprland.lua` and the quickshell config are live-edited checkouts, so edits apply on `hyprctl reload` / quickshell restart with no rebuild. Activation scripts link `/run/hypr/config` → `~/.config/hypr` and `/run/quickshell/config` → `~/.config/quickshell` (the quickshell wrapper's `configDir` is that link; `features/quickshell`'s module owns it and `hyprland` imports it). When a checkout is missing, the link falls back to the pushed state pinned by the `hyprland` / `quickshell` inputs, so a fresh install still gets a configured session. Hence: push the config repo, then `nix flake update hyprland quickshell`, or the fallback drifts from what actually runs (`desk-status` shows it).
- **Shared keymap** (`features/keymap/`): binds that need store paths live once, in Nix, as `flake.lib.keymap.binds` — a table of keys (`"Mod+Shift+H"`, `"Mod+WheelScrollRight"`) to compositor-neutral actions (`focus-left`, `spawn`, `music`…; vocabulary at the top of that file). `toHyprlandLua` renders it to a Lua chunk that `features/hyprland` links at `/run/hypr/keymap.lua`, which `binds.lua` in the hypr checkout `dofile()`s and maps to dispatchers via its `sharedActions` table (it notifies at reload for any action it doesn't know). A new shared bind goes in `features/keymap` and needs a rebuild; a new *action* also needs a `sharedActions` entry. Hyprland-only binds stay in `binds.lua`. `flake.lib.keymap.cheatsheet` renders the table as markdown. The per-bind attributes and key spelling are compositor-neutral on purpose, so another compositor would just add a translator next to `toHyprlandLua`.
- **GPU order** (`hosts/anton`): `AQ_DRM_DEVICES` lists the Intel iGPU first on purpose — it does basic compositing so the 9070 XT's VRAM stays free — via udev symlinks (`/dev/dri/intel-igpu`, `/dev/dri/amd-dgpu`), because cardN numbering isn't stable and the by-path names contain colons.

The legacy installer GNOME + GDM were removed deliberately. What GNOME had been enabling implicitly is now explicit in `desktop`: bluetooth, upower, udisks2 (with a deliberate polkit rule letting wheel mount internal disks without a prompt), gvfs, gnome-keyring, and SDDM's PAM keyring auto-unlock (`features/sddm`), which only GDM did automatically. Printing and avahi are off (no printer); openssh is keys-only; `nix.gc` runs weekly (`--delete-older-than 14d`) with `nix.optimise`.

### Wrapped packages

Desktop programs are wrapped with the `wrappers` input (BirdeeHub/nix-wrapper-modules) rather than configured via home-manager or dotfiles: `settings` passed to `inputs.wrappers.wrappers.<prog>.wrap` becomes the program's config, baked into the package. Config references other wrapped packages via `lib.getExe self'.packages.<name>`, so it is closed over the store — no `$PATH` lookups, except where a dependency cycle forces one (`hyprctl` in otter-launcher/wlogout, since those sit in hyprland's runtimePackages). `wrap` requires `inherit pkgs;` explicitly. Neovim is its own flake (`nvim` input) and is installed directly, with `EDITOR=nvim`.

`inputs.wrappers.wrappers` lists what can be wrapped; each wrapper's options live in `wrapperModules/<letter>/<name>/module.nix` in that flake's source. Those `module.nix` files carry the option examples and are the reference when a `settings` block won't serialize — there is no published option index.

Wrappers validate the config they generate at **build** time, so a malformed `settings` block passes `nix flake check` and only fails during `nixos-rebuild`. Check a wrapped package on its own (`nix build .#kitty`) after editing its settings.
