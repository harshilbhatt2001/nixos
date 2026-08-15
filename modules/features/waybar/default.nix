{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.nixosModules.waybar = moduleWithSystem ({self', ...}: {
    environment.systemPackages = with self'.packages; [
      waybar
    ];
  });
  perSystem = {pkgs, ...}: {
    packages.waybar = inputs.wrappers.wrappers.waybar.wrap {
      inherit pkgs;
      "style.css".path = ./style.css;
      configFile.content = ''
        {
        		"include": [
        			"${./modules.jsonc}"
        		],
            "height": 20,
            "margin": "3 6",
            "reload_style_on_change": true,
            "position": "top",
            "modules-left": [
                "custom/logo",
                "hyprland/workspaces"
            ],
            "modules-center": [
                "mpris"
            ],
            "modules-right": [
                "network",
                "bluetooth",
                "custom/notifs",
        				"battery",
                "clock"
            ]
        }
      '';
    };
  };
}
