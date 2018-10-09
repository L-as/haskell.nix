{ pkgs ? import <nixpkgs> {} }:
let
 base = import ./pkgs.nix { inherit pkgs; };
 overlays = [
   (self: super: with pkgs.haskell.lib; { hnix = dontCheck super.hnix; })
   (self: super: with pkgs.haskell.lib; { time = dontCheck super.time;
                                          aeson = dontCheck super.aeson;
                                          filepath = dontCheck super.filepath;
                                          directory = dontCheck super.directory;
                                          attoparsec = dontCheck super.attoparsec;
                                          bytestring = dontCheck super.bytestring;
                                          QuickCheck = dontCheck super.QuickCheck;
                                          containers = dontCheck super.containers;
                                          scientific = dontCheck super.scientific;
                                          integer-logarithms = dontCheck super.integer-logarithms;
                                          text = dontCheck super.text;
                                          binary = dontCheck super.binary;
                                          hashable = dontCheck super.hashable;
                                          Cabal = dontCheck super.Cabal;
                                          dlist = dontCheck super.dlist;
                                          unordered-containers = dontCheck super.unordered-containers;
                                          uuid-types = dontCheck super.uuid-types;
                                          vector = dontCheck super.vector;
                                          base-orphans = dontCheck super.base-orphans;
                                          deriving-compat = dontCheck super.deriving-compat;
                                          exceptions = dontCheck super.exceptions;
                                          cryptonite = dontCheck super.cryptonite;
                                          http-types = dontCheck super.http-types;
                                          http-client = dontCheck super.http-client;
                                          case-insensitive = dontCheck super.case-insensitive;
                                          blaze-builder = dontCheck super.blaze-builder;
                                          network = dontCheck super.network;
                                          streaming-commons = dontCheck super.streaming-commons;
                                          async = dontCheck super.async;
                                          zlib = dontCheck super.zlib;
                                          cookie = dontCheck super.cookie;
                                          network-uri = dontCheck super.network-uri;
                                          parsec = dontCheck super.parsec;
                                          cereal = dontCheck super.cereal;
                                          tls = dontCheck super.tls;
                                          hourglass = dontCheck super.hourglass;
                                          asn1-encoding = dontCheck super.asn1-encoding;
                                          x509 = dontCheck super.x509;
                                          pem = dontCheck super.pem;
                                          x509-store = dontCheck super.x509-store;
                                          x509-validation = dontCheck super.x509-validation;
                                          haskell-src-meta = dontCheck super.haskell-src-meta;
                                          haskell-src-exts = dontCheck super.haskell-src-exts;
                                          syb = dontCheck super.syb;
                                          interpolate = dontCheck super.interpolate;
                                          th-orphans = dontCheck super.th-orphans;
                                          lens-family-th = dontCheck super.lens-family-th;
                                          megaparsec = dontCheck super.megaparsec;
                                          these = dontCheck super.these;
                                          bifunctors = dontCheck super.bifunctors;
                                          distributive = dontCheck super.distributive;
                                          adjunctions = dontCheck super.adjunctions;
                                          invariant = dontCheck super.invariant;
                                          cryptohash-md5 = dontCheck super.cryptohash-md5;
                                          cryptohash-sha1 = dontCheck super.cryptohash-sha1;
                                          cryptohash-sha256 = dontCheck super.cryptohash-sha256;
                                          cryptohash-sha512 = dontCheck super.cryptohash-sha512;
                                          serialise = dontCheck super.serialise;
                                          cborg = dontCheck super.cborg;
                                          half = dontCheck super.half;
                                          microlens-aeson = dontCheck super.microlens-aeson;
                                          yaml = dontCheck super.yaml;
                                          conduit = dontCheck super.conduit;
                                          resourcet = dontCheck super.resourcet;
                                          mono-traversable = dontCheck super.mono-traversable;
                                          extra = dontCheck super.extra;
                                          clock = dontCheck super.clock;
                                          hpack = dontCheck super.hpack;
                                          Glob = dontCheck super.Glob;
                                          infer-license = dontCheck super.infer-license;
                                          text-metrics = dontCheck super.text-metrics;

                                          vector-algorithms = dontCheck super.vector-algorithms;
                                          # doctest
                                          comonad = dontCheck super.comonad;
                                          semigroupoids = dontCheck super.semigroupoids;
                                          })
 ];
in
 builtins.foldl' (pkgs: overlay: pkgs.extend overlay) base overlays
