module Main (main) where

import Test.Hspec
import qualified Nyaa.MagnetSpec
import qualified Nyaa.CategoriesSpec
import qualified Nyaa.Internal.UtilsSpec
import qualified Nyaa.Internal.Parser.HtmlSpec
import qualified Nyaa.Internal.Parser.RssSpec

main :: IO ()
main = hspec $ do
  describe "Nyaa.Magnet"                   Nyaa.MagnetSpec.spec
  describe "Nyaa.Categories"               Nyaa.CategoriesSpec.spec
  describe "Nyaa.Internal.Utils"           Nyaa.Internal.UtilsSpec.spec
  describe "Nyaa.Internal.Parser.Html"     Nyaa.Internal.Parser.HtmlSpec.spec
  describe "Nyaa.Internal.Parser.Rss"      Nyaa.Internal.Parser.RssSpec.spec