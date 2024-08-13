{
  description = "My Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core
    , homebrew-cask, home-manager }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      taps = {
        "homebrew/core" = homebrew-core;
        "homebrew/cask" = homebrew-cask;
      };
      brew_config = { username }:
        inputs.nix-homebrew.darwinModules.nix-homebrew {
          lib = nix-darwin.lib;
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = username;
            taps = taps;
            autoMigrate = true;
          };
        };
      configuration = { ... }: {

        # List packages installed in system profile. To search by name, run:
        environment.systemPackages = [
          pkgs.neovim
          pkgs.fish
          pkgs.tmux
          pkgs.git
          pkgs.vim
          pkgs.stow

          pkgs.sesh
          pkgs.atuin
          pkgs.fzf
          pkgs.jq
          pkgs.mods
          pkgs.gh
          pkgs.lazygit
          pkgs.pass
          pkgs.gnupg
          pkgs.git-lfs

          pkgs.ripgrep
          pkgs.fd
          pkgs.eza
          pkgs.bat
          pkgs.difftastic

          pkgs.rm-improved
          pkgs.dust
          pkgs.delta
          pkgs.mprocs
          pkgs.hyperfine
          pkgs.starship
          pkgs.tealdeer
          pkgs.tokei
          pkgs.typos
          pkgs.zoxide

          pkgs.llvm_17
          pkgs.jdk21_headless
          pkgs.micromamba
          pkgs.uv
          pkgs.go
          pkgs.zig
          pkgs.fnm

          pkgs.kitty
          pkgs.espanso
          pkgs._1password

          pkgs.luajitPackages.luv
          pkgs.luajitPackages.sqlite
          pkgs.nixfmt-classic

        ];

        homebrew = {
          enable = true;
          brews = [ "coreutils" "findutils" "imagemagick" ];
          casks = [ "hammerspoon" "spotmenu" "ubersicht" ];
          taps = builtins.attrNames taps;
          onActivation = {
            autoUpdate = true;
            cleanup = "zap";
            upgrade = true;
            extraFlags = [ "--verbose" "--debug" ];
          };
        };

        environment.shells = [ pkgs.fish ];
        environment.variables = { EDITOR = "nvim"; };

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;
        services.yabai = {
          enable = true;
          enableScriptingAddition = true;
        };
        services.skhd = { enable = true; };
        services.jankyborders = {
          enable = true;
          active_color = "0xaae1e3e4";
          inactive_color = "0x00494d64";
          width = 3.0;
        };

        fonts.packages = [
          (pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
          pkgs.victor-mono
        ];

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = system;

        security.pam.enableSudoTouchIdAuth = true;

        system.defaults = {
          finder.AppleShowAllExtensions = true;
          finder.AppleShowAllFiles = true;
        };
      };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#madmax-mbp
      darwinConfigurations."madmax-mbp" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          {
            users.users.madmax = {
              home = "/Users/madmax";
              shell = pkgs.fish;
            };
          }
          (brew_config { username = "madmax"; })
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.madmax = import ./home/madmax-mbp.nix;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."madmax-mbp".pkgs;
    };
}
