module Nyaa.CategoriesSpec (spec) where

import Test.Hspec
import Nyaa.Categories
import Nyaa.Types (TorrentSite (..))

spec :: Spec
spec = do
  describe "nyaaCategories" $ do
    it "resolves known category code" $
      nyaaCategories "1_2" `shouldBe` "Anime - English-translated"

    it "resolves category from href format" $
      nyaaCategories "?c=1_2" `shouldBe` "Anime - English-translated"

    it "returns Unknown for missing category" $
      nyaaCategories "9_9" `shouldBe` "Unknown"

    it "returns Unknown for malformed code" $
      nyaaCategories "bad" `shouldBe` "Unknown"

    it "resolves all main categories" $ do
      nyaaCategories "1_1" `shouldBe` "Anime - Anime Music Video"
      nyaaCategories "2_1" `shouldBe` "Audio - Lossless"
      nyaaCategories "6_2" `shouldBe` "Software - Games"

  describe "sukebeiCategories" $ do
    it "resolves known sukebei category" $
      sukebeiCategories "1_2" `shouldBe` "Art - Doujinshi"

    it "returns Unknown for nyaa-only category on sukebei" $
      sukebeiCategories "6_1" `shouldBe` "Unknown"

  describe "categoryForSite" $ do
    it "uses nyaa map for NyaaSi" $
      categoryForSite NyaaSi "1_2" `shouldBe` "Anime - English-translated"

    it "uses nyaa map for NyaaLand" $
      categoryForSite NyaaLand "1_2" `shouldBe` "Anime - English-translated"

    it "uses sukebei map for SukebeiNyaaSi" $
      categoryForSite SukebeiNyaaSi "1_2" `shouldBe` "Art - Doujinshi"