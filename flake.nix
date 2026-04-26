{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          postgresql-client
        ];
        shellHook = ''
          docker compose up
          echo "Nix dev shell activated (venv ready)"
          trap '
            docker compose down
            deactivate > /dev/null;
            echo "Nix dev shell deactivated"
          ' EXIT
        '';
      };
    };
}
