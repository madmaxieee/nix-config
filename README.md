# my nix-darwin and home-manager config

```sh
nix --extra-experimental-features 'nix-command flakes' \
run home-manager/master -- --extra-experimental-features 'nix-command flakes' switch --flake ~/nix-config/
```
