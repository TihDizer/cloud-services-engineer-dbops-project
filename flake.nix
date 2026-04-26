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
          docker
          postgresql
        ];

        shellHook = ''
          clear
          sudo docker compose up --detach
          echo "Nix dev shell activated"

          DOCKER_SOCK="./docker-sock/docker.sock"
          DOCKER_DATA="./docker-data"

          mkdir -p "$DOCKER_DATA" ./docker-sock

          dockerd \
            --data-root="$DOCKER_DATA" \
            --host="unix://$DOCKER_SOCK" \
            >./dockerd.log 2>&1 &

            while ! [ -S "$DOCKER_SOCK" ]; do
              sleep 0.1
            done

            export DOCKER_HOST="unix://$PWD/$DOCKER_SOCK"

          trap '
            sudo docker compose down
            kill %1
            rm -rf ./docker-data ./docker-sock ./dockerd.log
            deactivate > /dev/null;
            echo "Nix dev shell deactivated"
          ' EXIT
        '';
      };
    };
}
