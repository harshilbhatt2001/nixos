# nixos

NixOS config for the machine `anton`.

How it works, in short: every `.nix` file under `modules/` is picked up
automatically ([import-tree](https://github.com/vic/import-tree) +
[flake-parts](https://flake.parts)). There is no import list. Add a file and
it is part of the system; delete it and it is gone. Desktop apps are wrapped
with [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules):
each app's config is baked into its binary, so there are no dotfiles.

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
                       (niri, hyprland, kitty, neovim, fish, git, waybar, ...)
```

Rules of thumb: an app with config goes in `features/`. A plain package with
no config goes in an `attrs/` bundle. Anything true only for this machine
goes in `hosts/anton/`. Everything else stays reusable for a future machine.

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
   in `modules/hosts/anton/default.nix`. Then rebuild.

Nothing touches the running system until you `nixos-rebuild switch`.

## How to add a user

Users are defined in `modules/system/core/user.nix`. Add a block:

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

```bash
nix flake update            # update every input
nix flake update nvim       # update one input
sudo nixos-rebuild switch --flake .
```

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
2. Add `<name>Configuration.nix` with the hostname, bootloader, and disks.
3. Run `nixos-generate-config` on the new machine and copy the output into a
   `hardware.nix`, wrapped the same way as `hosts/anton/hardware.nix`. (Do
   not paste it in as-is — an unwrapped file fails with a confusing
   "infinite recursion" error.)

Everything under `system/`, `attrs/`, and `features/` already works for any
machine; only the `hosts/<name>/` folder is machine-specific.
