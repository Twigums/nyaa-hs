module Nyaa.MagnetSpec (spec) where

import qualified Data.Text as T
import Test.Hspec
import Nyaa.Magnet

spec :: Spec
spec = do
  describe "magnetBuilder" $ do
    it "produces a magnet URI starting with magnet:?xt=urn:btih:" $ do
      let result = magnetBuilder "ABCDEF1234" "My Title"
      result `shouldSatisfy` T.isPrefixOf "magnet:?xt=urn:btih:ABCDEF1234"

    it "includes the info hash" $ do
      let hash   = "DEADBEEFDEADBEEF"
          result = magnetBuilder hash "Foo"
      result `shouldSatisfy` T.isInfixOf hash

    it "includes all default trackers" $ do
      let result = magnetBuilder "HASH" "Title"
      mapM_ (\_ -> result `shouldSatisfy` T.isInfixOf "tr=") magnetTrackers

    it "percent-encodes spaces in title" $ do
      let result = magnetBuilder "HASH" "My Title"
      result `shouldSatisfy` T.isInfixOf "My%20Title"

    it "appends all magnetTrackers" $ do
      let result   = magnetBuilder "HASH" "T"
          trCount  = length (T.breakOnAll "&tr=" result)
      trCount `shouldBe` length magnetTrackers

  describe "magnetTrackers" $ do
    it "is non-empty" $
      magnetTrackers `shouldSatisfy` (not . null)

    it "all entries are non-empty strings" $
      mapM_ (\t -> t `shouldSatisfy` (not . T.null)) magnetTrackers