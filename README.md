# my nix-darwin and home-manager config

## set up a macOS machine from scratch

1. install developer tools

```sh
xcode-select --install
```

2. install nix following the instructions at https://nixos.org/download.html

3. clone this repository

```sh
cd ~
git clone https://github.com/madmaxieee/nix-config.git
```

4. run the darwin configuration

```sh
sudo nix --extra-experimental-features 'nix-command flakes' \
  run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch --flake ~/nix-config
```

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
