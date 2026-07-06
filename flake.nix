{
  description = "NGI Invoices Template Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      devshell,
      treefmt-nix,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkTreefmt =
        pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.black.enable = true;
          programs.nixfmt.enable = true;
        };
    in
    {
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        (mkTreefmt pkgs).config.build.wrapper
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ devshell.overlays.default ];
          };
          treefmtWrapper = (mkTreefmt pkgs).config.build.wrapper;
          create-invoice = pkgs.writeShellScriptBin "create-invoice" ''
            exec ${pkgs.python3}/bin/python3 ${./invoice.py} "$@"
          '';
        in
        {
          default = pkgs.devshell.mkShell {
            name = "invoices-template-shell";
            packages = with pkgs; [
              typst
              roboto
            ];
            commands = [
              {
                name = "create-invoice";
                help = "Generate invoice from Notion timesheet CSV export";
                package = create-invoice;
                category = "main";
              }
              {
                name = "treefmt";
                help = "Format python and nix files";
                package = treefmtWrapper;
              }
            ];
            env = [
              {
                name = "TYPST_FONT_PATHS";
                value = "${pkgs.roboto}/share/fonts/truetype";
              }
            ];
          };
        }
      );
    };
}
