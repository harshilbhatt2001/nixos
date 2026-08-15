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

Keep the tree flat — one file per host and per feature, no scaffolding files:

- `modules/hosts/anton/` — the machine.
  - `default.nix` — `nixosConfigurations.anton`, plus `systems`.
  - `configuration.nix` — `nixosModules.antonConfiguration`: composes the feature modules and holds the host's own settings.
  - `hardware.nix` — `nixosModules.antonHardware`, the wrapped `nixos-generate-config` hardware scan.
- `modules/features/` — one file per composable feature. `niri.nix` is the reference example: it exports the NixOS module *and*, via `perSystem`, the wrapped package that module installs.

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
