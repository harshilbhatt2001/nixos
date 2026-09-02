# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A NixOS flake for a single machine (`anton`), built on the **dendritic pattern**: `flake.nix` is a stub whose only job is to hand `./modules` to `import-tree`, which recursively auto-imports **every `.nix` file** under it as a flake-parts module. There is no explicit import list anywhere — adding a file to `modules/` wires it in, deleting it unwires it.

Non-`.nix` files (e.g. `modules/features/noctalia/noctalia.json`) are ignored by import-tree and exist only to be referenced from Nix code.

## Commands

```bash
nix flake check    # evaluate everything
nix flake show     # list outputs
nix build .#niri   # build one wrapped package

# evaluate the whole system closure without building or activating it
nix eval .#nixosConfigurations.anton.config.system.build.toplevel.drvPath

sudo nixos-rebuild switch --flake .#anton   # apply to the running system
sudo nixos-rebuild build  --flake .#anton   # build, don't activate
```

Prefer `flake check` or the `eval ... drvPath` line above when verifying a change — both force full evaluation and catch every error a rebuild would, without touching the running system.

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
- `self'.packages.<name>` — a package from `perSystem` on the *current* system (`modules/features/niri/default.nix` uses this for `noctalia`).
- `moduleWithSystem ({ self' }: { ... })` — the bridge from a NixOS module to `self'.packages.*` / `inputs'.*`; it's a flake-parts helper available as a top-level module arg alongside `self`/`inputs`. (`self.packages.${pkgs.stdenv.hostPlatform.system}.<name>` works too, but `moduleWithSystem` is the house style.)

Because names are the wiring, a typo or a not-yet-written module is an evaluation error, not a missing-file error.

`modules/parts.nix` sets `systems = [ "x86_64-linux" ]`. This is load-bearing: with no `systems`, `perSystem` silently yields *no* outputs, so `packages` disappears and every `self'.packages.*` reference dangles — while `nixosConfigurations` still appears to evaluate fine. It's Linux-only because the wrapped desktop packages (niri) don't evaluate on darwin, which would fail `nix flake check`.

## Architecture

`~/ws-linux/nixos-reference` (the "Voidarc" dendritic config) is the reference for how this repo is developed. Same stack — flake-parts + import-tree + nix-wrapper-modules (input name `wrappers`) — and the same layered module taxonomy, which this repo now follows.

```
flake.nix ─── import-tree ./modules ──▶ every .nix file is a flake-parts module

modules/
├── parts.nix          systems = [ ... ]        (repo-wide, enables perSystem)
│
├── hosts/<HOST>/      flake.nixosConfigurations.<HOST>
│                      = nixosSystem { modules = with self.nixosModules; [ ... ] }
│                      + <host>Configuration: hostname + host-only quirks
│
├── attrs/<bundle>/    nixosModules.<bundle>    composition only — imports other
│                      (development, gaming…)   nixosModules + plain pkgs, no new
│                                               features defined here
│
├── system/<area>/     nixosModules.<area>      base system, NO wrapped binaries
│                      core/ desktop/ drivers/  (boot, users, locale, network,
│                      network/ audio/ theme/   audio, gpu, gtk/cursor theme)
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
   ├── antonConfiguration                  hostname, Limine/Secure Boot, disks
   ├── antonHardware                       wrapped nixos-generate-config scan
   ├── system:   desktop ──imports──▶ core ──▶ user, nix-settings, locale
   │             desktop also imports network, audio, zen-browser, and the
   │             two desktop-environment groups (see below)
   ├── attrs:    development ──imports──▶ git, neovim
   └── features: niri = moduleWithSystem ({ self' }: ...)
                    │        installs self'.packages.niri
                    ▼
                 perSystem.packages.niri = inputs.wrappers.wrappers
                    .niri.wrap { inherit pkgs; settings = ...; }
                    │        config baked into the binary; keybinds reference
                    ▼        other apps via lib.getExe self'.packages.<other>
                 nix run .#niri works standalone on any machine
```

Conventions (from the reference):

- **Layering is strict**: `system/` never installs wrapped binaries, `attrs/` never defines anything new (imports + plain `environment.systemPackages` only), `features/` is the only place a wrapper lives. A host file is just a module list.
- One folder in `features/` per app; folder name = package name = module name. Every feature with a package is independently runnable: `nix run .#<app>`.
- Host-specific facts (hostname, boot chain, partition UUIDs) live only in `hosts/<HOST>/`; everything else must stay host-agnostic so a second host can reuse it.

Deliberate differences from the reference: hardware config is tracked in-repo (`hosts/anton/hardware.nix`) instead of the impure `/etc/nixos/hardware-configuration.nix` import — no `--impure` here, and that's better. Single host (`anton`) and `systems = [ "x86_64-linux" ]` for now.

### Desktop-environment groups

`system/desktop/` composes two selectable desktop environments; drop one from `desktop`'s imports to remove it wholesale:

- **`hyprland`** (`features/hyprland/`, the default) — the reference's custom DE, ported verbatim. The `hyprland` flake input is the reference author's wrapper flake, which provides the wrapped binary and `lib.defaultRuntimePkgs`. The actual `hyprland.lua` config is **out-of-store**: an activation script symlinks `/run/hypr/config` to the local checkout at `~/.config/hypr` (a clone of the reference author's config repo, with anton-specific tweaks under `if Hostname == "anton"` branches), so config edits apply on `hyprctl reload` with no rebuild — deviating from the reference, which links the store copy (`packages.repo-files`); the module overrides `runtimePackages` with this repo's wrapped `quickshell`/`otter-launcher`/`wlogout`/`wpaperd`/`kitty` plus `grimblast`, `playerctl` and `zen` (one `features/` folder each, also from the reference). It imports `systemTheme` (`system/systemTheme/`: bibata cursor + catppuccin GTK via dconf) and sets `services.displayManager.defaultSession = "hyprland"`, which is what makes it the default session. The quickshell config is likewise out-of-store: the wrapper's `--path` points at the local checkout `~/.config/quickshell` (the `quickshell` flake input pins the fork of that config repo but is currently unreferenced by the wrap call).
- **Shared keymap** (`features/keymap/`): the binds both compositors have in common (windows, focus/move, workspaces, terminal/browser/launcher, screenshots, media keys, the mouse thumb wheel) live once, in Nix, as `flake.lib.keymap.binds` — a table of niri-spelled keys (`"Mod+Shift+H"`, `"Mod+WheelScrollRight"`) to compositor-neutral actions (`focus-left`, `spawn`, `focus-workspace-next`…; the vocabulary is listed at the top of that file). `toNiri` renders it into the niri wrapper's `settings.binds` (`features/niri` passes a `resolve` map so `spawn` names become store paths, and overrides `launcher`); `toHyprlandLua` renders it to a Lua chunk that `features/hyprland` links at `/run/hypr/keymap.lua`, which `binds.lua` in the hypr checkout `dofile()`s and maps to dispatchers via its `sharedActions` table. A new shared bind therefore goes in `features/keymap` and needs a rebuild; a new *action* also needs a translator entry on both sides (niri: `niriActions` or the caller's `actions`; hyprland: `sharedActions` in `binds.lua`, which notifies at reload for any action it doesn't know). Compositor-specific binds stay in `features/niri` (merged with `//` after `toNiri`) or in `binds.lua`'s `globalAppBinds`.
- **`niriDesktop`** (`system/desktop/niri.nix`) — the pre-hyprland setup: just the `niri` feature. SDDM (`features/sddm`, catppuccin-themed) is the display manager for both groups.

The legacy installer GNOME + GDM were removed deliberately. What GNOME had been enabling implicitly is now explicit: bluetooth/upower/udisks2/gvfs/avahi live in the shared `desktop` module (the verified enable-diff of dropping GNOME), gnome-keyring comes from `programs.niri`'s nixpkgs module (portals' `Secret` backend), portals come from the hyprland/niri nixpkgs modules, and SDDM's PAM service opts into keyring auto-unlock (`features/sddm`) because only GDM did that automatically.

### Wrapped packages

Desktop programs are wrapped with the `wrappers` input (BirdeeHub/nix-wrapper-modules) rather than configured via home-manager or dotfiles: `settings` passed to `inputs.wrappers.wrappers.<prog>.wrap` becomes the program's config, baked into the package. Keybinds reference other wrapped packages via `lib.getExe self'.packages.<name>`, so config is fully closed over the store — no `$PATH` lookups. `wrap` requires `inherit pkgs;` explicitly.

`inputs.wrappers.wrappers` lists what can be wrapped; each wrapper's options live in `wrapperModules/<letter>/<name>/module.nix` in that flake's source. Those `module.nix` files carry the option examples and are the reference when a `settings` block won't serialize — there is no published option index.

Wrappers validate the config they generate at **build** time, so a malformed `settings` block passes `nix flake check` and only fails during `nixos-rebuild`. Check a wrapped package on its own (`nix build .#niri`) after editing its settings.

For niri specifically, `settings` is serialized to KDL, and an action taking no arguments is written `_: { }`:

```nix
"Mod+Q".close-window = _: { };   # -> `close-window`
"Mod+Q".close-window = null;     # -> `close-window null`, rejected by niri
```

The same `_: { }` idiom applies anywhere a bare KDL node is needed (`focus-ring.off`, argument-less workspace definitions, and so on).

Noctalia is a special case worth knowing: it edits its own config files from its GUI, so a store-backed config is read-only. With only `settings` set, the wrapper points `NOCTALIA_SETTINGS_FILE` at the store. Setting `colors`/`plugins`/`user-templates` too switches it to a store `NOCTALIA_CONFIG_DIR` (still read-only); `outOfStoreConfig = "/some/path"` makes it copy to a writable location on startup instead. The wrapper also ships `dump-noctalia-shell`, which prints the live config as Nix.

## Migration in progress

The installer-generated config has been split into `modules/system/*` along reference lines, but its *settings* were carried over verbatim and are still unreviewed. GNOME + GDM have since been removed (see Desktop-environment groups above); `programs.firefox.enable` still rides along in `antonConfiguration.nix`.

Don't change base-system behaviour as a side effect of unrelated work — it's being handled deliberately. The restructure itself was verified behaviour-preserving: the `toplevel` drvPath is identical before and after.

`modules/features/noctalia/noctalia.json` is a full `dump-noctalia-shell` config dump (bar layout, wallpaper dir, display geometry), referenced by nothing yet — it's staged input for `modules/features/noctalia/default.nix`, which currently passes `settings = { }` and whose comment says to paste the parts worth keeping from exactly such a dump.
