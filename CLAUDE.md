# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A NixOS flake for a single machine (`anton`), built on the **dendritic pattern**: `flake.nix` is a stub whose only job is to hand `./modules` to `import-tree`, which recursively auto-imports **every `.nix` file** under it as a flake-parts module. There is no explicit import list anywhere — adding a file to `modules/` wires it in, deleting it unwires it.

Non-`.nix` files (e.g. `modules/features/noctalia.json`) are ignored by import-tree and exist only to be referenced from Nix code.

## Commands

```bash
nix flake check    # evaluate everything
nix flake show     # list outputs
nix build .#myNiri # build one package

# evaluate the whole system closure without building or activating it
nix eval .#nixosConfigurations.anton.config.system.build.toplevel.drvPath

sudo nixos-rebuild switch --flake .#anton   # apply to the running system
sudo nixos-rebuild build  --flake .#anton   # build, don't activate
```

Prefer `flake check` or the `eval ... drvPath` line above when verifying a change — both force full evaluation and catch every error a rebuild would, without touching the running system.

`networking.hostName` matches the flake attribute, so bare `nixos-rebuild switch --flake .` also resolves to `anton`. Keep the two in sync if either is renamed.

`nix flake show` / `flake check` rewrite `flake.lock` if inputs in `flake.nix` are unlocked. This repo is **not** under version control, so that is not undoable — read the lock diff Nix prints before moving on.

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

- `self.nixosModules.<name>` — another module in this repo (`modules/hosts/anton/configuration.nix` composes `antonHardware` and `niri` this way).
- `self'.packages.<name>` — a package from `perSystem` on the *current* system (`modules/features/niri.nix` uses this for `myNoctalia`).
- `self.packages.${pkgs.stdenv.hostPlatform.system}.<name>` — the same package from inside a NixOS module, where `self'` is not in scope.

Because names are the wiring, a typo or a not-yet-written module is an evaluation error, not a missing-file error.

`modules/hosts/anton/default.nix` sets `systems = [ "x86_64-linux" ]`. This is load-bearing: with no `systems`, `perSystem` silently yields *no* outputs, so `packages` disappears and every `self'.packages.*` reference dangles — while `nixosConfigurations` still appears to evaluate fine.

### Layout

Current state — one file per host and per feature, no scaffolding files:

- `modules/hosts/anton/` — the machine.
  - `default.nix` — `nixosConfigurations.anton`, plus `systems`.
  - `configuration.nix` — `nixosModules.antonConfiguration`: composes the feature modules and holds the host's own settings.
  - `hardware.nix` — `nixosModules.antonHardware`, the wrapped `nixos-generate-config` hardware scan.
- `modules/features/` — one file per composable feature. `niri.nix` is the reference example: it exports the NixOS module *and*, via `perSystem`, the wrapped package that module installs.

The direction of travel is the layered layout described under **Target architecture** below; don't restructure ahead of the migration, but put *new* modules where that layout says they belong.

## Target architecture

`~/ws/nixos-reference` (the "Voidarc" dendritic config) is the reference for how this repo will be developed. Same stack — flake-parts + import-tree + wrapper-modules — but with a layered module taxonomy. `modules/parts.nix` (repo-level `systems`) and `modules/system/drivers/amd.nix` are the first pieces of it already copied in.

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

How a host composes, and where packages come from:

```
nixosConfigurations.<HOST>                 (hosts/<HOST>/default.nix)
   │  lists modules by name only: with self.nixosModules; [ ... ]
   │
   ├── <host>Configuration                 hostname, host-specific settings
   ├── system:   desktop ──imports──▶ core ──▶ user, boot, nix, hardware, locale
   │             drivers (amd/intel), network, audio, systemTheme
   ├── attrs:    development ──imports──▶ git, nvim  (+ extra systemPackages)
   └── features: <app> = moduleWithSystem ({ self' }: ...)
                    │        installs self'.packages.<app>
                    ▼
                 perSystem.packages.<app> = inputs.wrappers.wrappers.<app>.wrap {
                    inherit pkgs; settings = ...; }
                    │        config baked into the binary; keybinds reference
                    ▼        other apps via lib.getExe self'.packages.<other>
                 nix run .#<app> works standalone on any machine
```

Key conventions from the reference:

- **Layering is strict**: `system/` never installs wrapped binaries, `attrs/` never defines anything new (imports + plain `environment.systemPackages` only), `features/` is the only place a wrapper lives. A host file is just a module list.
- **`moduleWithSystem`** (a flake-parts helper, available as a top-level module arg alongside `self`/`inputs`) is the idiomatic bridge from a NixOS module to `self'.packages.*` — the reference uses it everywhere this repo currently uses `self.packages.${pkgs.stdenv.hostPlatform.system}`.
- Every feature is independently runnable: `nix run .#<app>` — one folder in `features/` per app, folder name = package name = module name.
- Composition modules put their `imports` list in a `let modules = with self.nixosModules; [ ... ]; in { imports = modules; ... }` block.

Deliberate differences to keep: this repo tracks hardware in-repo (`hosts/anton/hardware.nix`) instead of the reference's impure `/etc/nixos/hardware-configuration.nix` import — no `--impure` here, and that's better. Single host (`anton`) for now.

### Wrapped packages

Desktop programs are wrapped with `inputs.wrapper-modules` rather than configured via home-manager or dotfiles: `settings` passed to `wrapper-modules.wrappers.<prog>.wrap` becomes the program's config, baked into the package. Keybinds reference other wrapped packages via `lib.getExe self'.packages.<name>`, so config is fully closed over the store — no `$PATH` lookups. `wrap` requires `inherit pkgs;` explicitly.

`inputs.wrapper-modules.wrappers` lists what can be wrapped; each wrapper's options live in `wrapperModules/<letter>/<name>/module.nix` in that flake's source. Those `module.nix` files carry the option examples and are the reference when a `settings` block won't serialize — there is no published option index.

Wrappers validate the config they generate at **build** time, so a malformed `settings` block passes `nix flake check` and only fails during `nixos-rebuild`. Check a wrapped package on its own (`nix build .#myNiri`) after editing its settings.

For niri specifically, `settings` is serialized to KDL, and an action taking no arguments is written `_: { }`:

```nix
"Mod+Q".close-window = _: { };   # -> `close-window`
"Mod+Q".close-window = null;     # -> `close-window null`, rejected by niri
```

The same `_: { }` idiom applies anywhere a bare KDL node is needed (`focus-ring.off`, argument-less workspace definitions, and so on).

Noctalia is a special case worth knowing: it edits its own config files from its GUI, so a store-backed config is read-only. With only `settings` set, the wrapper points `NOCTALIA_SETTINGS_FILE` at the store. Setting `colors`/`plugins`/`user-templates` too switches it to a store `NOCTALIA_CONFIG_DIR` (still read-only); `outOfStoreConfig = "/some/path"` makes it copy to a writable location on startup instead. The wrapper also ships `dump-noctalia-shell`, which prints the live config as Nix.

## Migration in progress

The bottom half of `modules/hosts/anton/configuration.nix` is the installer-generated config, carried over as-is. It has not been reviewed yet — the direction is to peel settings out of it into `modules/features/*` as they get revisited. Notably, GNOME + GDM are still enabled alongside the niri setup from `modules/features/niri.nix`.

Don't change base-system behaviour as a side effect of unrelated work — it's being handled deliberately.

`modules/features/noctalia.json` is an empty placeholder, referenced by nothing. `modules/features/noctalia.nix` currently passes `settings = { }`.
