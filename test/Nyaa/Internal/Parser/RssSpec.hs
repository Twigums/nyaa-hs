module Nyaa.Internal.Parser.RssSpec (spec) where

import qualified Data.ByteString as BS
import qualified Data.Text as T
import Test.Hspec
import Nyaa.Internal.Parser.Rss
import Nyaa.Types

loadFixture :: FilePath -> IO BS.ByteString
loadFixture name = BS.readFile ("test/fixtures/" <> name)

spec :: Spec
spec = do
  describe "parseNyaaRss" $ do
    it "parses all items from RSS fixture" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err -> expectationFailure (show err)
        Right ts -> length ts `shouldBe` 2

    it "respects the limit parameter" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi (Just 1) bytes of
        Left err -> expectationFailure (show err)
        Right ts -> length ts `shouldBe` 1

    it "parses torrent name from title" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err    -> expectationFailure (show err)
        Right (t:_) -> torrentName t `shouldBe` "Test Anime S01E01"
        Right []    -> expectationFailure "no torrents"

    it "parses seeders and leechers" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err    -> expectationFailure (show err)
        Right (t:_) -> do
          torrentSeeders  t `shouldBe` 42
          torrentLeechers t `shouldBe` 7
        Right []    -> expectationFailure "no torrents"

    it "extracts view id from guid" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err    -> expectationFailure (show err)
        Right (t:_) -> torrentId t `shouldBe` "123456"
        Right []    -> expectationFailure "no torrents"

    it "uses category name from nyaa:category when present" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err    -> expectationFailure (show err)
        Right (t:_) -> torrentCategory t `shouldBe` "Anime - English-translated"
        Right []    -> expectationFailure "no torrents"

    it "builds magnet URI from infoHash and title" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err    -> expectationFailure (show err)
        Right (t:_) -> torrentMagnet t `shouldSatisfy`
                         T.isPrefixOf "magnet:?xt=urn:btih:ABCDEF1234567890"
        Right []    -> expectationFailure "no torrents"

    it "parses Trusted type" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err    -> expectationFailure (show err)
        Right (t:_) -> torrentType t `shouldBe` Trusted
        Right []    -> expectationFailure "no torrents"

    it "parses Remake type" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err        -> expectationFailure (show err)
        Right (_:t2:_)  -> torrentType t2 `shouldBe` Remake
        Right _         -> expectationFailure "not enough torrents"

    it "completedDownloads is always Nothing for RSS" $ do
      bytes <- loadFixture "search.rss"
      case parseNyaaRss NyaaSi Nothing bytes of
        Left err    -> expectationFailure (show err)
        Right (t:_) -> torrentCompletedDownloads t `shouldBe` Nothing
        Right []    -> expectationFailure "no torrents"

    it "returns ParseError for malformed XML" $
      case parseNyaaRss NyaaSi Nothing "not xml at all <<<" of
        Left (ParseError _) -> pure ()
        other               -> expectationFailure ("expected ParseError, got: " <> show other)