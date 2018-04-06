{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleInstances #-}

module Main where

import System.Environment (getArgs)
import Distribution.PackageDescription.Parsec (readGenericPackageDescription)
import Distribution.Verbosity (normal)
import Distribution.Text (disp)
import Distribution.Pretty (pretty)
import Data.Char (toUpper)

import Distribution.Types.CondTree
import Distribution.Types.Library
import Distribution.Types.ForeignLib
import Distribution.PackageDescription
import Distribution.Types.Dependency
import Distribution.Types.ExeDependency

import Data.String (fromString)
import Nix.Pretty (prettyNix)

-- import Distribution.Types.GenericPackageDescription
-- import Distribution.Types.PackageDescription
import Distribution.Types.PackageId
--import Distribution.Types.Condition
import Distribution.Types.UnqualComponentName
import Nix.Expr
import Data.Fix(Fix(..))
import Data.Text (Text)

pkgs, hsPkgs, flags :: Text
pkgs   = "pkgs"
hsPkgs = "hsPkgs"
flags  = "_flags"

main :: IO ()
main = getArgs >>= \case
  [file] -> do
    gpd <- readGenericPackageDescription normal file
    print . prettyNix $
      mkFunction (mkParamset [ ("system", Nothing)
                             , ("compiler", Nothing)
                             , ("flags", Just $ mkNonRecSet [])
                             , (pkgs, Nothing)
                             , (hsPkgs, Nothing)]) $
      mkLets [ flags $= (mkNonRecSet . fmap toNixBinding $ genPackageFlags gpd) $// mkSym "flags" ] $ toNix gpd
  _ -> putStrLn "call with cabalfile (Cabal2Nix file.cabal)."

class HasBuildInfo a where
  getBuildInfo :: a -> BuildInfo

instance HasBuildInfo Library where
  getBuildInfo = libBuildInfo

instance HasBuildInfo ForeignLib where
  getBuildInfo = foreignLibBuildInfo

instance HasBuildInfo Executable where
  getBuildInfo = buildInfo

instance HasBuildInfo TestSuite where
  getBuildInfo = testBuildInfo

instance HasBuildInfo Benchmark where
  getBuildInfo = benchmarkBuildInfo

--- Clean the Tree from empty nodes
-- CondBranch is empty if the true and false branch are empty.
shakeTree :: (Foldable t, Foldable f) => CondTree v (t c) (f a) -> Maybe (CondTree v (t c) (f a))
shakeTree (CondNode d c bs) = case (null d, null bs') of
                                (True, True) -> Nothing
                                _            -> Just (CondNode d c bs')
  where bs' = [b | Just b <- shakeBranch <$> bs ]

shakeBranch :: (Foldable t, Foldable f) => CondBranch v (t c) (f a) -> Maybe (CondBranch v (t c) (f a))
shakeBranch (CondBranch c t f) = case (shakeTree t, f >>= shakeTree) of
  (Nothing, Nothing) -> Nothing
  (Nothing, Just f') -> shakeBranch (CondBranch (CNot c) f' Nothing)
  (Just (CondNode d _c [(CondBranch c' t' f')]), Nothing) | null d -> Just $ CondBranch (CAnd c c') t' f'
  (Just t', f') -> Just (CondBranch c t' f')

--- String helper
transformFst :: (Char -> Char) -> String -> String
transformFst _ [] = []
transformFst f (x:xs) = (f x):xs
capitalize :: String -> String
capitalize = transformFst toUpper

--- Turn something into a NExpr

class ToNixExpr a where
  toNix :: a -> NExpr

class ToNixBinding a where
  toNixBinding :: a -> Binding NExpr

instance ToNixExpr PackageIdentifier where
  toNix ident = mkNonRecSet [ "name"    $= mkStr (fromString (show (disp (pkgName ident))))
                            , "version" $= mkStr (fromString (show (disp (pkgVersion ident))))]

instance ToNixExpr PackageDescription where
  toNix pd = mkNonRecSet [ "specVersion" $= mkStr (fromString (show (disp (specVersion pd))))
                         , "identifier"  $= toNix (package pd)
                         , "license"     $= mkStr (fromString (show (pretty (license pd))))

                         , "copyright"   $= mkStr (fromString (copyright pd))
                         , "maintainer"  $= mkStr (fromString (maintainer pd))
                         , "author"      $= mkStr (fromString (author pd))

                         , "homepage"    $= mkStr (fromString (homepage pd))
                         , "url"         $= mkStr (fromString (pkgUrl pd))

                         , "synopsis"    $= mkStr (fromString (synopsis pd))
                         , "description" $= mkStr (fromString (description pd))

                         , "buildType"   $= mkStr (fromString (show (pretty (buildType pd)))) ]

newtype SysDependency = SysDependency { unSysDependency :: String } deriving (Show, Eq, Ord)

mkSysDep :: String -> SysDependency
mkSysDep = SysDependency

instance ToNixExpr GenericPackageDescription where
  toNix gpd = mkNonRecSet [ "package"    $= (toNix (packageDescription gpd))
                          , "components" $= components ]
    where packageName = fromString . show . disp . pkgName . package . packageDescription $ gpd
          component unQualName comp
            = name $= mkNonRecSet ([ "depends "   $= toNix deps | Just deps <- [shakeTree . fmap (         targetBuildDepends . getBuildInfo) $ comp ] ] ++
                                   [ "libs"       $= toNix deps | Just deps <- [shakeTree . fmap (  fmap mkSysDep . extraLibs . getBuildInfo) $ comp ] ] ++
                                   [ "frameworks" $= toNix deps | Just deps <- [shakeTree . fmap ( fmap mkSysDep . frameworks . getBuildInfo) $ comp ] ])
              where name = fromString $ unUnqualComponentName unQualName

          components = mkNonRecSet $
            [ component packageName lib | Just lib <- [condLibrary gpd] ] ++
            (bindTo "sublibs"     . mkNonRecSet <$> filter (not . null) [ uncurry component <$> condSubLibraries gpd ]) ++
            (bindTo "foreignlibs" . mkNonRecSet <$> filter (not . null) [ uncurry component <$> condForeignLibs  gpd ]) ++
            (bindTo "exes"        . mkNonRecSet <$> filter (not . null) [ uncurry component <$> condExecutables  gpd ]) ++
            (bindTo "tests"       . mkNonRecSet <$> filter (not . null) [ uncurry component <$> condTestSuites   gpd ]) ++
            (bindTo "benchmarks"  . mkNonRecSet <$> filter (not . null) [ uncurry component <$> condBenchmarks   gpd ])

instance ToNixExpr Dependency where
  toNix = mkDot (mkSym hsPkgs) . fromString . show . pretty . depPkgName

instance ToNixExpr SysDependency where
  toNix = mkDot (mkSym pkgs) . fromString . unSysDependency

instance ToNixExpr ExeDependency where
  toNix (ExeDependency pkgName _unqualCompName _versionRange) = mkSym . fromString . show . pretty $ pkgName

instance {-# OVERLAPPABLE #-} ToNixExpr String where
  toNix = mkStr . fromString

instance {-# OVERLAPS #-} ToNixExpr a => ToNixExpr [a] where
  toNix = mkList . fmap toNix

instance ToNixExpr ConfVar where
  toNix (OS os) = mkSym "system" !. (fromString . ("is" ++) . capitalize . show . pretty $ os)
  toNix (Arch arch) = mkSym "system" !. (fromString . ("is" ++) . capitalize . show . pretty $ arch)
  toNix (Flag flag) = mkSym flags !. (fromString . show . pretty $ flag)
  toNix (Impl flavour _range) = mkSym "compiler" !. (fromString . ("is" ++) . capitalize . show . pretty $ flavour)

instance ToNixExpr a => ToNixExpr (Condition a) where
  toNix (Var a) = toNix a
  toNix (Lit b) = mkBool b
  toNix (CNot c) = mkNot (toNix c)
  toNix (COr l r) = toNix l $|| toNix r
  toNix (CAnd l r) = toNix l $&& toNix r

instance (Foldable t, ToNixExpr (t a), ToNixExpr v, ToNixExpr c) => ToNixExpr (CondBranch v c (t a)) where
  toNix (CondBranch c t Nothing) = case toNix t of
    (Fix (NList [e])) -> mkSym pkgs !. "lib" !. "optional" @@ toNix c @@ e
    e -> mkSym "optionals" @@ toNix c @@ e
  toNix (CondBranch _c t (Just f)) | toNix t == toNix f = toNix t
  toNix (CondBranch c  t (Just f)) = mkIf (toNix c) (toNix t) (toNix f)

instance (Foldable t, ToNixExpr (t a), ToNixExpr v, ToNixExpr c) => ToNixExpr (CondTree v c (t a)) where
  toNix (CondNode d _c []) = toNix d
  toNix (CondNode d _c bs) | null d = foldl1 ($++) (fmap toNix bs)
                           | otherwise = foldl ($++) (toNix d) (fmap toNix bs)

instance ToNixBinding Flag where
  toNixBinding (MkFlag name _desc def _manual) = (fromString . show . pretty $ name) $= mkBool def
