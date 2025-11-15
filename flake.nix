{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # for nixpkgs overlay
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    sketchybar-app-font-src = {
      url = "github:madmaxieee/sketchybar-app-font";
      flake = false;
    };

    # yazi plugins
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
    lazygit-yazi = {
      url = "github:Lil-Dank/lazygit.yazi";
      flake = false;
    };
    searchjump-yazi = {
      url = "github:DreamMaoMao/searchjump.yazi";
      flake = false;
    };
    what-size-yazi = {
      url = "github:madmaxieee/what-size.yazi";
      flake = false;
    };
    ouch-yazi = {
      url = "github:ndtoan96/ouch.yazi";
      flake = false;
    };
    tv-yazi = {
      url = "github:madmaxieee/tv.yazi";
      flake = false;
    };

    # fish plugins
    autopair-fish = {
      url = "github:jorgebucaran/autopair.fish";
      flake = false;
    };
    fzf-fish = {
      url = "github:patrickf1/fzf.fish";
      flake = false;
    };
    vipe-fish = {
      url = "github:madmaxieee/vipe.fish";
      flake = false;
    };

    # misc
    fabric = {
      url = "github:danielmiessler/Fabric";
      flake = false;
    };
    tokyonight = {
      url = "github:folke/tokyonight.nvim";
      flake = false;
    };
  };

  outputs =
    { self, nix-darwin, nixpkgs, home-manager, nix-homebrew, ... }@inputs:

    let
      overlays = [
        inputs.neovim-nightly-overlay.overlays.default
        (final: prev: {
          sketchybar-app-font = prev.sketchybar-app-font.overrideAttrs (old: {
            version = "myfork";
            src = inputs.sketchybar-app-font-src;
          });
        })
      ];

      extraSpecialArgs = {
        inherit overlays;
        sources = {
          inherit (inputs)
            yazi-plugins lazygit-yazi searchjump-yazi what-size-yazi ouch-yazi
            tv-yazi;
          inherit (inputs) autopair-fish fzf-fish vipe-fish;
          inherit (inputs) fabric tokyonight;
        };
      };

      brew_config = { username }: {
        nix-homebrew = {
          enable = true;
          enableRosetta = false;
          user = username;
          taps = {
            "homebrew/core" = inputs.homebrew-core;
            "homebrew/cask" = inputs.homebrew-cask;
          };
          mutableTaps = false;
        };
      };

      darwin_config = { pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = overlays;

        environment.systemPackages = [ pkgs.git pkgs.vim pkgs.fish ];

        fonts.packages = [ pkgs.nerd-fonts.symbols-only pkgs.victor-mono ];

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        security.pam.services.sudo_local.touchIdAuth = true;
        environment.etc."pam.d/sudo_local".text = ''
          # Written by nix-darwin
          auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
          auth       sufficient     pam_tid.so
        '';

        system.defaults = {
          WindowManager = {
            EnableStandardClickToShowDesktop = false;
            StandardHideDesktopIcons = true;
          };
          finder = {
            AppleShowAllExtensions = true;
            AppleShowAllFiles = true;
          };
          dock = {
            autohide = true;
            showhidden = true;
            show-recents = false;
            mru-spaces = false;
          };
          NSGlobalDomain = {
            AppleICUForce24HourTime = true;
            AppleInterfaceStyle = "Dark";
            NSWindowShouldDragOnGesture = true;
            # sets how long it takes before it starts repeating.
            # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
            InitialKeyRepeat = 15;
            # sets how fast it repeats once it starts.
            # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)
            KeyRepeat = 3;
            ApplePressAndHoldEnabled = false;
          };
        };
        system.startup.chime = false;
      };

    in {
      darwinConfigurations."madmax-mbp" = nix-darwin.lib.darwinSystem {
        modules = [
          darwin_config
          ({ pkgs, ... }: {
            system.primaryUser = "madmax";
            ids.gids.nixbld = 350;
            programs.zsh.enable = true;
            programs.fish.enable = true;
            environment.shells = [ pkgs.fish ];
            users.users.madmax = {
              home = "/Users/madmax";
              shell = pkgs.fish;
            };
          })

          nix-homebrew.darwinModules.nix-homebrew
          (brew_config { username = "madmax"; })
          (import ./modules/madmax-brew.nix)

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.madmax = import ./home/madmax-mbp.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = extraSpecialArgs;
          }

          (import ./modules/madmax-dock.nix {
            homeDirectory = "/Users/madmax";
          })

          (import ./modules/window-management)
        ];
      };

      darwinConfigurations."maxcchuang-mac" = nix-darwin.lib.darwinSystem {
        modules = [
          darwin_config
          ({ pkgs, ... }: {
            system.primaryUser = "maxcchuang";
            ids.gids.nixbld = 350;
            system.defaults.universalaccess.reduceMotion = true;
            programs.zsh.enable = false;
            programs.bash.enable = false;
            programs.fish.enable = true;
            environment.shells = [ pkgs.fish ];
            users.users.maxcchuang = {
              home = "/Users/maxcchuang";
              shell = pkgs.fish;
            };
          })

          nix-homebrew.darwinModules.nix-homebrew
          (brew_config { username = "maxcchuang"; })
          (import ./modules/maxcchuang-mac-brew.nix)

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.maxcchuang = import ./home/maxcchuang-mac.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = extraSpecialArgs;
          }

          (import ./modules/maxcchuang-mac-dock.nix {
            homeDirectory = "/Users/maxcchuang";
          })

          (import ./modules/window-management)
        ];
      };

      # vps homemanager config
      homeConfigurations."vps" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = overlays;
        };

        extraSpecialArgs = extraSpecialArgs;

        modules = [ ./home/madmax-vps.nix ];
      };

      # cloudtop homemanager config
      homeConfigurations."maxcchuang" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = overlays;
          };

          extraSpecialArgs = extraSpecialArgs;

          modules = [ ./home/maxcchuang.nix ];
        };
    };
}
