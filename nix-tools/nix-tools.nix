{ system
, compiler
, flags ? {}
, pkgs
, hsPkgs
, pkgconfPkgs }:
  let
    _flags = {} // flags;
  in {
    flags = _flags;
    package = {
      specVersion = "1.10";
      identifier = {
        name = "nix-tools";
        version = "0.1.0.0";
      };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "moritz.angermann@gmail.com";
      author = "Moritz Angermann";
      homepage = "";
      url = "";
      synopsis = "";
      description = "";
      buildType = "Simple";
    };
    components = {
      "nix-tools" = {
        depends  = [
          (hsPkgs.base)
          (hsPkgs.hnix)
          (hsPkgs.aeson)
          (hsPkgs.unordered-containers)
          (hsPkgs.process)
          (hsPkgs.deepseq)
          (hsPkgs.transformers)
          (hsPkgs.data-fix)
          (hsPkgs.Cabal)
          (hsPkgs.text)
          (hsPkgs.filepath)
          (hsPkgs.directory)
          (hsPkgs.bytestring)
          (hsPkgs.cryptohash-sha256)
          (hsPkgs.base16-bytestring)
        ];
      };
      exes = {
        "cabal-to-nix" = {
          depends  = [
            (hsPkgs.base)
            (hsPkgs.hnix)
            (hsPkgs.nix-tools)
            (hsPkgs.filepath)
            (hsPkgs.directory)
            (hsPkgs.ansi-wl-pprint)
          ];
        };
        "hashes-to-nix" = {
          depends  = [
            (hsPkgs.base)
            (hsPkgs.hnix)
            (hsPkgs.nix-tools)
            (hsPkgs.data-fix)
            (hsPkgs.aeson)
            (hsPkgs.microlens)
            (hsPkgs.microlens-aeson)
            (hsPkgs.text)
            (hsPkgs.filepath)
            (hsPkgs.directory)
          ];
        };
        "plan-to-nix" = {
          depends  = [
            (hsPkgs.base)
            (hsPkgs.nix-tools)
            (hsPkgs.hnix)
            (hsPkgs.text)
            (hsPkgs.unordered-containers)
            (hsPkgs.vector)
            (hsPkgs.aeson)
            (hsPkgs.microlens)
            (hsPkgs.microlens-aeson)
          ];
        };
        "lts-to-nix" = {
          depends  = [
            (hsPkgs.base)
            (hsPkgs.nix-tools)
            (hsPkgs.hnix)
            (hsPkgs.yaml)
            (hsPkgs.aeson)
            (hsPkgs.microlens)
            (hsPkgs.microlens-aeson)
            (hsPkgs.text)
            (hsPkgs.filepath)
            (hsPkgs.directory)
            (hsPkgs.unordered-containers)
            (hsPkgs.Cabal)
          ];
        };
        "stack-to-nix" = {
          depends  = [
            (hsPkgs.base)
            (hsPkgs.nix-tools)
            (hsPkgs.transformers)
            (hsPkgs.hnix)
            (hsPkgs.yaml)
            (hsPkgs.aeson)
            (hsPkgs.microlens)
            (hsPkgs.microlens-aeson)
            (hsPkgs.text)
            (hsPkgs.Cabal)
            (hsPkgs.vector)
            (hsPkgs.ansi-wl-pprint)
            (hsPkgs.directory)
            (hsPkgs.filepath)
            (hsPkgs.extra)
            (hsPkgs.hpack)
            (hsPkgs.bytestring)
            (hsPkgs.optparse-applicative)
          ];
        };
      };
    };
  } // rec { src = ./.; }
