module Nyaa.Internal.Parser.HtmlSpec (spec) where

import qualified Data.ByteString as BS
import Test.Hspec
import Nyaa.Internal.Parser.Html
import Nyaa.Types

loadFixture :: FilePath -> IO BS.ByteString
loadFixture name = BS.readFile ("test/fixtures/" <> name)

spec :: Spec
spec = do
  describe "parseNyaa" $ do
    it "parses all rows from listing fixture" $ do
      bytes <- loadFixture "listing.html"
      let result = parseNyaa NyaaSi Nothing bytes
      case result of
        Left err -> expectationFailure (show err)
        Right ts -> length ts `shouldBe` 2

    it "respects the limit parameter" $ do
      bytes <- loadFixture "listing.html"
      let result = parseNyaa NyaaSi (Just 1) bytes
      case result of
        Left err -> expectationFailure (show err)
        Right ts -> length ts `shouldBe` 1

    it "parses the torrent id from view href" $ do
      bytes <- loadFixture "listing.html"
      case parseNyaa NyaaSi Nothing bytes of
        Left err     -> expectationFailure (show err)
        Right (t:_)  -> torrentId t `shouldBe` "123456"
        Right []     -> expectationFailure "no torrents parsed"

    it "parses the torrent name" $ do
      bytes <- loadFixture "listing.html"
      case parseNyaa NyaaSi Nothing bytes of
        Left err     -> expectationFailure (show err)
        Right (t:_)  -> torrentName t `shouldBe` "Test Anime S01E01"
        Right []     -> expectationFailure "no torrents parsed"

    it "parses seeders and leechers" $ do
      bytes <- loadFixture "listing.html"
      case parseNyaa NyaaSi Nothing bytes of
        Left err     -> expectationFailure (show err)
        Right (t:_)  -> do
          torrentSeeders  t `shouldBe` 42
          torrentLeechers t `shouldBe` 7
        Right []     -> expectationFailure "no torrents parsed"

    it "parses completed downloads when present" $ do
      bytes <- loadFixture "listing.html"
      case parseNyaa NyaaSi Nothing bytes of
        Left err     -> expectationFailure (show err)
        Right (t:_)  -> torrentCompletedDownloads t `shouldBe` Just 100
        Right []     -> expectationFailure "no torrents parsed"

    it "parses torrent type from row class" $ do
      bytes <- loadFixture "listing.html"
      case parseNyaa NyaaSi Nothing bytes of
        Left err        -> expectationFailure (show err)
        Right (_:t2:_)  -> torrentType t2 `shouldBe` Trusted
        Right _         -> expectationFailure "not enough torrents"

    it "constructs correct view url" $ do
      bytes <- loadFixture "listing.html"
      case parseNyaa NyaaSi Nothing bytes of
        Left err     -> expectationFailure (show err)
        Right (t:_)  -> torrentUrl t `shouldBe` "https://nyaa.si/view/123456"
        Right []     -> expectationFailure "no torrents parsed"

    it "returns Right [] for empty tbody" $ do
      let empty = "<html><body><table><tbody></tbody></table></body></html>"
      parseNyaa NyaaSi Nothing empty `shouldBe` Right []

  describe "parseSingle" $ do
    it "parses title from detail page" $ do
      bytes <- loadFixture "detail.html"
      case parseSingle NyaaSi bytes of
        Left err -> expectationFailure (show err)
        Right d  -> detailTitle d `shouldBe` "Test Anime S01E01"

    it "parses uploader" $ do
      bytes <- loadFixture "detail.html"
      case parseSingle NyaaSi bytes of
        Left err -> expectationFailure (show err)
        Right d  -> detailUploader d `shouldBe` "testuser"

    it "parses info hash" $ do
      bytes <- loadFixture "detail.html"
      case parseSingle NyaaSi bytes of
        Left err -> expectationFailure (show err)
        Right d  -> detailInfoHash d `shouldBe` "ABCDEF1234567890ABCDEF1234567890ABCDEF12"

    it "parses seeders and leechers" $ do
      bytes <- loadFixture "detail.html"
      case parseSingle NyaaSi bytes of
        Left err -> expectationFailure (show err)
        Right d  -> do
          detailSeeders  d `shouldBe` 42
          detailLeechers d `shouldBe` 7

    it "parses file list" $ do
      bytes <- loadFixture "detail.html"
      case parseSingle NyaaSi bytes of
        Left err -> expectationFailure (show err)
        Right d  -> map fileName (detailFiles d) `shouldBe` ["TestAnime_S01E01.mkv"]

    it "parses description" $ do
      bytes <- loadFixture "detail.html"
      case parseSingle NyaaSi bytes of
        Left err -> expectationFailure (show err)
        Right d  -> detailDescription d `shouldBe` "A test description."

    it "returns ParseError for empty document" $ do
      let empty = "<html><body></body></html>"
      parseSingle NyaaSi empty `shouldBe` Left (ParseError "Failed to parse torrent detail page.")