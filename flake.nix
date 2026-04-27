{
  description = "A basic flake for psql and run docker compose (used for local development)";
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
          # docker
          postgresql
          flyway
        ];

        shellHook = ''
          clear
          echo "Nix dev shell activated"
          sudo docker compose up --detach

          trap '
            sudo docker compose down
            deactivate > /dev/null;
            echo "Nix dev shell deactivated"
          ' EXIT
        '';
      };
    };
}
