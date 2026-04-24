module Nyaa.Internal.UtilsSpec (spec) where

import Test.Hspec
import Nyaa.Internal.Utils

spec :: Spec
spec = do
  describe "lastSegment" $ do
    it "returns last path component" $
      lastSegment "/view/123456" `shouldBe` "123456"

    it "returns last component with extension" $
      lastSegment "/download/123456.torrent" `shouldBe` "123456.torrent"

    it "handles single segment" $
      lastSegment "abc" `shouldBe` "abc"

    it "handles empty string" $
      lastSegment "" `shouldBe` ""

  describe "readInt" $ do
    it "parses a plain integer" $
      readInt "42" `shouldBe` 42

    it "strips whitespace" $
      readInt "  100  " `shouldBe` 100

    it "returns 0 for non-numeric input" $
      readInt "abc" `shouldBe` 0

    it "returns 0 for empty string" $
      readInt "" `shouldBe` 0

    it "parses integer ignoring trailing text" $
      readInt "7 leechers" `shouldBe` 7