# my nix-darwin and home-manager config

## first use on linux

```sh
nix --extra-experimental-features 'nix-command flakes' \
  run home-manager/master -- \
  --extra-experimental-features 'nix-command flakes' \
  switch --flake ~/nix-config
```

## rebuild on linux

```sh
home-manager switch --flake ~/nix-config#<target>
```
