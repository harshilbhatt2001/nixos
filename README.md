# nixos

NixOS configuration for `anton`, built on the **dendritic pattern**: `flake.nix`
hands `./modules` to [import-tree](https://github.com/vic/import-tree), which
auto-imports every `.nix` file as a
[flake-parts](https://flake.parts) module. There is no import list — adding a
file wires it in. Desktop apps are configured with
[nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules): the
config is baked into each program's binary, so there are no dotfiles and every
app runs standalone on any machine with nix.

Modeled on [the Voidarc reference config](~/ws/nixos-reference).

## Daily driving

```bash
sudo nixos-rebuild switch --flake .   # apply to the running system
sudo nixos-rebuild build  --flake .   # build without activating

nix flake check                       # evaluate everything (CI-style check)
nix build .#kitty                     # build one app + validate its config
nix run .#kitty                       # run one app without installing it
```

Two things worth knowing:

- **Nix only sees git-tracked files.** A new file under `modules/` does
  nothing until `git add`. If a change "mysteriously" has no effect, check
  `git status`.
- **Wrapped-app configs validate at build time, not eval time.** `nix flake
  check` passes on a broken `settings` block; `nix build .#<app>` is what
  catches it. Always build the app you just edited.

## Layout — what lives where

```
modules/
├── parts.nix          flake-parts plumbing (systems)
├── hosts/anton/       this machine: module list, boot chain, disks, hardware
├── system/            base system, no apps: core (user/nix/locale),
│                      desktop, network, audio
├── attrs/             bundles that compose other modules: development
└── features/          one folder per app = NixOS module + wrapped binary:
                       niri, kitty, neovim, noctalia, zen-browser, fish, git
```

The layering is strict:

| Layer | May contain | Never contains |
|---|---|---|
| `hosts/` | module list, hostname, partitions, boot | anything reusable |
| `system/` | base services and settings | wrapped app binaries |
| `attrs/` | imports of other modules + plain packages | new feature definitions |
| `features/` | one app: its module and its wrapped package | host-specific facts |

## Running and testing apps standalone

Every feature with a package is independently runnable — the config travels
with the binary:

```bash
nix run .#niri        # the window manager, keybinds and all
nix run .#kitty       # terminal with its baked-in kitty.conf
nix run .#neovim      # full editor: plugins, LSPs, colorscheme
nix run .#noctalia    # the shell/launcher
```

This is also the edit loop: change a feature's `settings`, then
`nix build .#<app>` (validates the generated config) and `nix run .#<app>`
(try it live). Nothing touches the running system until you `nixos-rebuild
switch`.

## Adding a new app

1. Create `modules/features/<app>/default.nix`. Folder name = package name =
   module name. Shape:

   ```nix
   { inputs, moduleWithSystem, ... }: {
     flake.nixosModules.<app> = moduleWithSystem (
       { self' }: {
         environment.systemPackages = [ self'.packages.<app> ];
       }
     );

     perSystem = { pkgs, ... }: {
       packages.<app> = inputs.wrappers.wrappers.<app>.wrap {
         inherit pkgs;              # required, always
         settings = { ... };        # becomes the app's config file
       };
     };
   }
   ```

   `inputs.wrappers.wrappers` lists what can be wrapped; each wrapper's
   options live in `wrapperModules/<letter>/<app>/module.nix` in the
   [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)
   source. Reference other wrapped apps with `lib.getExe
   self'.packages.<other>` so the dependency is baked in.

2. `git add` the folder, then `nix build .#<app>` and `nix run .#<app>`.

3. Wire it in by name: add `<app>` to the imports in
   `modules/system/desktop/default.nix` (desktop apps) or to the host list in
   `modules/hosts/anton/default.nix`, then rebuild.

Plain packages that need no config don't get a feature — add them to
`environment.systemPackages` in an `attrs/` bundle (e.g. `development`).

## Dev environments & starting projects

`claude-code` and `devenv` are installed system-wide via the `development`
bundle. Per-project environments stay out of the system config entirely —
pick whichever fits the project:

```bash
# devenv: batteries-included per-project environments
devenv init            # scaffold devenv.nix + devenv.yaml in the current dir
devenv shell           # enter the environment
devenv up              # start declared services (postgres, redis, ...)

# plain flakes: a devShell you define yourself
nix flake init -t templates#utils   # scaffold a flake.nix (see `nix flake show templates`)
nix develop                          # enter the devShell

# ad hoc: try a tool without installing anything
nix shell nixpkgs#hugo nixpkgs#nodejs
nix run nixpkgs#cowsay -- moo
```

For automatic activation on `cd`, add `direnv` + `nix-direnv` (works with both
`devenv` and flake devShells via `use flake` / `use devenv` in an `.envrc`) —
not installed yet, add it to the `development` bundle when wanted.

## Updating

```bash
nix flake update            # bump every input
nix flake update nvim       # bump one input (e.g. pull new neovim config)
sudo nixos-rebuild switch --flake .
```

Neovim is its own flake at
[harshilbhatt2001/nvim](https://github.com/harshilbhatt2001/nvim/tree/nix)
(branch `nix`), with all plugins pinned by nix. Editing it: commit + push to
the `nix` branch, then `nix flake update nvim` here. Plugin updates happen in
*that* repo via its own `nix flake update`.

Roll back a bad generation from the boot menu, or:

```bash
sudo nixos-rebuild switch --rollback
```

## Adding a second host

1. `modules/hosts/<name>/default.nix` — `flake.nixosConfigurations.<name>`
   listing modules by name (`with self.nixosModules; [ desktop ... ]`).
2. `<name>Configuration.nix` — hostname, bootloader, disks.
3. `hardware.nix` — run `nixos-generate-config`, then wrap the generated body
   as a flake-parts module (copy the shape of `hosts/anton/hardware.nix`; a
   bare NixOS module fails with a misleading infinite-recursion error).

Everything under `system/`, `attrs/`, and `features/` is host-agnostic and
reusable as-is.
