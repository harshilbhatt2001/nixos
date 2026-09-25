# nixos

NixOS config for the machine `anton`.

How it works, in short: every `.nix` file under `modules/` is picked up
automatically ([import-tree](https://github.com/vic/import-tree) +
[flake-parts](https://flake.parts)). There is no import list. Add a file and
it is part of the system; delete it and it is gone. Desktop apps are wrapped
with [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules):
each app's config is baked into its binary. The two exceptions are live-edited
git checkouts: `~/.config/hypr` (Hyprland's lua config) and
`~/.config/quickshell` (the bar), so edits there apply without a rebuild.

## Fresh install

1. Clone this repo to `~/.config/nixos`.
2. Clone the two live-edited config repos:

   ```bash
   git clone https://github.com/harshilbhatt2001/hypr ~/.config/hypr
   git clone https://github.com/harshilbhatt2001/quickshell ~/.config/quickshell
   ```

   Without them the system still works: it falls back to the copies pinned in
   `flake.lock`, which are only as fresh as the last `nix flake update
   hyprland quickshell`.
3. Password SSH is off. If you want to log in remotely, put a public key in
   `~/.ssh/authorized_keys`.
4. `sudo nixos-rebuild switch --flake .`

## Everyday commands

```bash
sudo nixos-rebuild switch --flake .   # apply changes to the running system
sudo nixos-rebuild build  --flake .   # build only, don't apply

nix flake check                       # check that everything still evaluates
nix build .#kitty                     # build one app and validate its config
nix run .#kitty                       # try one app without installing it
```

Two rules to remember:

- **Nix only sees files that git knows about.** A new file does nothing until
  you `git add` it. If a change "mysteriously" has no effect, check
  `git status` first.
- **A broken app config passes `nix flake check`.** The config is only
  validated when the app is built. After editing an app's `settings`, run
  `nix build .#<app>` to catch mistakes.

## Where things live

```
modules/
├── hosts/anton/       this machine: which modules it uses, boot, disks, hardware
├── system/            base system: user, nix settings, locale, desktop,
│                      network, audio, drivers, theme
├── attrs/             bundles of plain packages + other modules (development)
└── features/          one folder per app: its config + wrapped binary
                       (hyprland, kitty, neovim, fish, git, quickshell, ...)
```

Rules of thumb: an app with config goes in `features/`. A plain package with
no config goes in an `attrs/` bundle. Anything true only for this machine
goes in `hosts/anton/`. Everything else stays reusable for a future machine.

## Keybinds

`SUPER+SHIFT+backslash` shows every Hyprland bind. The binds defined in Nix
(`modules/features/keymap`) as a table:

```bash
nix eval --raw .#lib.keymap.cheatsheet
```

## How to add a plain package

For a tool that needs no config (a compiler, a CLI), add it to a bundle in
`attrs/`. For example, in `modules/attrs/development/default.nix`:

```nix
environment.systemPackages = with pkgs; [
  claude-code
  opencode
  ripgrep      # <- new package
];
```

Then `sudo nixos-rebuild switch --flake .`.

To try a tool first without installing anything:

```bash
nix shell nixpkgs#hugo nixpkgs#nodejs   # temporary shell with these tools
nix run nixpkgs#cowsay -- moo           # run once
```

## How to add an app with config

1. Create `modules/features/<app>/default.nix`. The folder name, package
   name, and module name are all the same word. Copy this shape:

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

   `inputs.wrappers.wrappers` lists which apps can be wrapped. The options
   for each app are in `wrapperModules/<letter>/<app>/module.nix` in the
   [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)
   source. To make one app call another (a keybind that opens a terminal),
   use `lib.getExe self'.packages.<other>` instead of the plain name.

2. `git add` the folder, then test it alone:

   ```bash
   nix build .#<app>   # validates the config
   nix run .#<app>     # try it live
   ```

3. Wire it into the system by name. Desktop apps go in the imports in
   `modules/system/desktop/default.nix`; anything else goes in the host list
   in `modules/hosts/anton/default.nix`. Then rebuild. If Hyprland launches
   the app by name (a bind in `binds.lua`), add it to `runtimePackages` in
   `modules/features/hyprland/default.nix` as well.

Nothing touches the running system until you `nixos-rebuild switch`.

## How to add a user

The login user is `flake.lib.user` in `modules/system/core/user.nix`; other
modules (ddcci, autologin, the config links) read it from there, so renaming
it is a one-line change. An extra account is an ordinary block in the same
file's NixOS module:

```nix
users.users."alice" = {
  isNormalUser = true;
  description = "Alice";
  extraGroups = [ "networkmanager" "wheel" ];   # wheel = can use sudo
};
```

Rebuild, then set a password with `sudo passwd alice`. NixOS does not manage
passwords here — only the account itself.

## How to set up a dev environment

Per-project environments stay out of the system config. `devenv` is
installed system-wide and auto-activates when you `cd` into a project (via a
fish hook):

```bash
devenv init      # scaffold devenv.nix in the current project
devenv allow     # allow auto-activation for this project (once)
devenv shell     # or enter the environment by hand
devenv up        # start declared services (postgres, redis, ...)
```

If you prefer a plain flake instead:

```bash
nix flake init -t templates#utils   # scaffold a flake.nix
nix develop                          # enter its devShell
```

## How to update

Update inputs in groups, each as its own `chore(lock): <inputs>` commit, so a
regression can be pinned to one bump:

```bash
nix flake update nixpkgs zen-browser    # roughly weekly
nix flake update hyprland quickshell    # after pushing ~/.config/hypr or ~/.config/quickshell
nix flake update nvim                   # after pushing the nvim repo
```

Then, from the repo's dev shell, check before switching:

```bash
rebuild-diff                            # warns about unpushed config work, builds, shows the package diff
sudo nixos-rebuild switch --flake .
```

`desk-status` on its own shows uncommitted or unpushed work in this repo and
the two config checkouts. Old generations are garbage-collected weekly
(older than 14 days).

Neovim is its own flake at
[harshilbhatt2001/nvim](https://github.com/harshilbhatt2001/nvim/tree/nix)
(branch `nix`). To change it: commit and push there, then
`nix flake update nvim` here. Its plugins are updated in that repo, not this
one.

If an update breaks something, pick an older generation from the boot menu,
or:

```bash
sudo nixos-rebuild switch --rollback
```

## How to add a second machine

1. Create `modules/hosts/<name>/default.nix` with
   `flake.nixosConfigurations.<name>`, listing the modules it wants by name
   (`with self.nixosModules; [ desktop development ... ]`) — copy
   `hosts/anton/default.nix`.
2. Add `<name>Configuration.nix` with the hostname, `system.stateVersion`
   (the release you install), bootloader, disks, and GPU quirks such as
   `AQ_DRM_DEVICES` (see `hosts/anton`).
3. Run `nixos-generate-config` on the new machine and copy the output into a
   `hardware.nix`, wrapped the same way as `hosts/anton/hardware.nix`. (Do
   not paste it in as-is — an unwrapped file fails with a confusing
   "infinite recursion" error.)

Everything under `system/`, `attrs/`, and `features/` already works for any
machine; only the `hosts/<name>/` folder is machine-specific.
