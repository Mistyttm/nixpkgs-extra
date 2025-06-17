# nixpkgs-extra

Some extra packages and modules I make for myself that I don't feel like upstreaming atm

## Installation

To use `nixpkgs-extra` in your Nix setup, follow these steps:

### Step 1: Add to Flake Inputs

Include `nixpkgs-extra` in your flake inputs by adding the following line:

```nix
nixpkgs-extra.url = "github:Mistyttm/nixpkgs-extra";
```

### Step 2: Configure Your Flake Outputs

Import the packages overlay and/or the modules in your `flake.nix`. Below is an example configuration:

```nix
outputs = inputs@{ nixpkgs-extra, ... }: {
    nixosConfigurations.myConfig = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
            nixpkgs-extra.nixosModules.default
            {
                nixpkgs.overlays = [
                    nixpkgs-extra.overlays.default
                ];
            }
        ];
    };
};
```

> [!NOTE]
>
> - You can choose to use either the overlay or the module, depending on your needs. Both are optional and can be used independently.
> - The overlay provides additional packages, while the module integrates system-level configurations.

For more details, refer to the [Nix documentation](https://nixos.org/manual/nix/).

## Usage

### Packages (`pkgs`)

You can add the provided packages to your `environment.systemPackages` in your NixOS or Home Manager configuration, just like any other package from `nixpkgs`. For example:

```nix
{
    environment.systemPackages = with pkgs; [
        vpm
    ];

    home.packages = with pkgs; [
        vpm
    ];
}
```

### Modules

If you are using the module, it will automatically apply the configurations specified in the module to your NixOS system. This simplifies system-level integration and ensures the settings are applied consistently.

### Using nix shell

You can also use the packages in a temporary environment with `nix shell`. This is useful for testing or one-off usage without modifying your system configuration. For example:

```bash
nix shell github:Mistyttm/nixpkgs-extra#vpm
```

This command will start a shell with the `vpm` package available, allowing you to use it immediately.
