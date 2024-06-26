# parsec-cloud-nix

Packaging parsec-cloud in NixOS

## Useful links

- [Parsec-cloud-2.16.3 - poetry.lock](https://github.com/Scille/parsec-cloud/blob/v2.16.3/poetry.lock)
- Cachix:
  - [Cachix docs](https://docs.cachix.org/)
  - [NixOS CI with Github Actions](https://nix.dev/tutorials/nixos/continuous-integration-github-actions)
    - [`cachix/install-nix-action` - Github Action](https://github.com/cachix/install-nix-action)
    - [`cachix/cachix-action` - Github Action](https://github.com/cachix/cachix-action)

- [Poetry2Nix](https://github.com/nix-community/poetry2nix).
  - [Poetry2Nix - `Mypy` patch failing](https://github.com/nix-community/poetry2nix/issues/561)

- [NixOS QT Wiki](https://nixos.wiki/wiki/Qt)
- [Python package using `maturin`](https://ryantm.github.io/nixpkgs/languages-frameworks/rust/#python-package-using-maturin)

- Languages:
  - [Nixos Python](https://nixos.org/manual/nixpkgs/stable/#python)
    - [Packaging python - Nixos Wiki](https://nixos.wiki/wiki/Packaging/Python)
    - [`nixpkgs.fetchPypi`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/fetchpypi/default.nix)
  - [NixosRust](https://nixos.org/manual/nixpkgs/stable/#rust)
  - [Nixos node](https://nixos.org/manual/nixpkgs/stable/#language-javascript)
    - [npm packages](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/node-packages/node-packages.nix)
    - [nixos vscode](https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/applications/editors/vscode/generic.nix)
    - [wiki vscode](https://nixos.wiki/wiki/Visual_Studio_Code)
  - [Nixos Rust](https://nixos.org/manual/nixpkgs/stable/#rust)
    - [wiki Rust](https://nixos.wiki/wiki/Rust)

- Nix Derivations:
  - [`mkDerivation` hooks](https://nixos.org/manual/nixpkgs/stable/#chap-hooks)
  - [`stdenv`](https://nixos.org/manual/nixpkgs/stable/#chap-stdenv)
  - [`wrapProgram`](https://nixos.org/manual/nixpkgs/stable/#fun-wrapProgram)
  - [`makeWrapper`](https://nixos.org/manual/nixpkgs/stable/#fun-makeWrapper)
  - [Meta attrs (`pkgs.{pkgs}.meta`)](https://nixos.org/manual/nixpkgs/stable/#sec-standard-meta-attributes)
  - [Nixpks patches](https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md#patches)
  - [`makeDesktopItem`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/make-desktopitem/default.nix)

- Home manager module:
  - [`Anyrun` module](https://github.com/Kirottu/anyrun/blob/master/nix/hm-module.nix)
  - [`Nixos` module wiki](https://nixos.wiki/wiki/NixOS_modules)
  - [Writing home manager modules](https://nix-community.github.io/home-manager/index.xhtml#ch-writing-modules)
