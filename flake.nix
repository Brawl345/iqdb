{
  description = "iqdb";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ]
          (system: function nixpkgs.legacyPackages.${system});
    in
    {

      packages = forAllSystems
        (
          pkgs:
          let
            sqlite_orm = pkgs.fetchFromGitHub {
              owner = "fnc12";
              repo = "sqlite_orm";
              rev = "1.6";
              # hash = pkgs.lib.fakeHash;
              hash = "sha256-wk117q+cngphXj9Lu6wzF+2IYQUzsNkGZWr4dDMTBnw=";
            };

            httplib_0_8_9 = pkgs.httplib.overrideAttrs (oldAttrs: {
              version = "0.8.9";
              src = pkgs.fetchFromGitHub {
                owner = "yhirose";
                repo = "cpp-httplib";
                rev = "v0.8.9";
                # hash = pkgs.lib.fakeHash;
                hash = "sha256-Ok1BLN0OhnhiWUaYeKzBwO2DPyauXSiqBxUCyaNQRmk=";
              };
            });
          in
          {
            default = pkgs.stdenv.mkDerivation {
              pname = "iqdb";
              version = "109444c0533300d945de0f6253ddfa672899c571";

              src = pkgs.fetchFromGitHub {
                owner = "danbooru";
                repo = "iqdb";
                rev = "109444c0533300d945de0f6253ddfa672899c571";
                fetchSubmodules = true;
                # hash = pkgs.lib.fakeHash;
                hash = "sha256-JPI0wWs9kzFn5fvg286NBeW9aezI+QWef5e6vT2yd8o=";
              };

              enableParallelBuilding = true;

              patches = [
                (pkgs.substituteAll {
                  src = ./remove-fetchcontent-usage.patch;
                  catch2_src = pkgs.catch2.src;
                  httplib_src = httplib_0_8_9.src;
                  json_src = pkgs.nlohmann_json.src;
                  fmt_src = pkgs.fmt.src;
                  sqliteorm_src = sqlite_orm;
                  backwardcpp_src = pkgs.backward-cpp.src;
                })
              ];

              postPatch = ''
                substituteInPlace src/CMakeLists.txt  \
                  --replace "-march=x86-64" ""
              '';

              installPhase = ''
                runHook preInstall

                install -Dm755 src/iqdb $out/bin/iqdb

                runHook postInstall
              '';

              nativeBuildInputs = [
                pkgs.cmake
                pkgs.python3
                pkgs.sqlite
                pkgs.pkg-config
              ];

              buildInputs = [
                pkgs.libpng
                pkgs.gd
                pkgs.zlib
                pkgs.freetype
                pkgs.fontconfig
                pkgs.expat
                pkgs.libjpeg
              ];

              meta = {
                description = "Lets you search a database of images to find those that are visually similar to a given image.";
                homepage = "https://github.com/danbooru/iqdb";
                platforms = pkgs.lib.platforms.all;
              };
            };
          }
        );

    };
}
