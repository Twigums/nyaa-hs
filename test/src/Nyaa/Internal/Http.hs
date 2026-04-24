{-# LANGUAGE DataKinds #-}
module Nyaa.Internal.Http
  ( fetchListing
  , fetchListingWith
  , fetchView
  , fetchViewWith
  , fetchUserPage
  , fetchUserPageWith
  , fetchSearchRss
  , fetchSearchRssWith
  , fetchSearchHtml
  , fetchSearchHtmlWith
  ) where

import Control.Exception (try, SomeException)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString as BS
import Network.HTTP.Client (Proxy (..))
import Network.HTTP.Req
import Nyaa.Types


siteUrl :: TorrentSite -> Url 'Https
siteUrl = https . siteDomain

categoryParam :: SearchParams -> Text
categoryParam sp =
  T.pack (show (spCategory sp)) <> "_" <> T.pack (show (spSubcategory sp))

toReqConfig :: NyaaHttpConfig -> HttpConfig
toReqConfig cfg = defaultHttpConfig
  { httpConfigProxy         = fmap toProxy (nhcProxy cfg)
  , httpConfigRedirectCount = nhcRedirectCount cfg
  }
  where
    toProxy p = Proxy (TE.encodeUtf8 (nyaaProxyHost p)) (nyaaProxyPort p)

userAgentOpt :: NyaaHttpConfig -> Option 'Https
userAgentOpt cfg = case nhcUserAgent cfg of
  Nothing -> mempty
  Just ua -> header "User-Agent" (TE.encodeUtf8 ua)

runSafe :: NyaaHttpConfig -> Req BS.ByteString -> IO (Either NyaaError BS.ByteString)
runSafe cfg action = do
  result <- try @SomeException (runReq (toReqConfig cfg) action)
  return $ case result of
    Left e  -> Left  (HttpError (T.pack $ show e))
    Right b -> Right b

get :: Url 'Https -> Option 'Https -> Req BS.ByteString
get url opts = responseBody <$> req GET url NoReqBody bsResponse opts

fetchListing :: TorrentSite -> IO (Either NyaaError BS.ByteString)
fetchListing = fetchListingWith defaultNyaaHttpConfig

fetchListingWith :: NyaaHttpConfig -> TorrentSite -> IO (Either NyaaError BS.ByteString)
fetchListingWith cfg site =
  runSafe cfg (get (siteUrl site) (userAgentOpt cfg))

fetchView :: TorrentSite -> Int -> IO (Either NyaaError BS.ByteString)
fetchView = fetchViewWith defaultNyaaHttpConfig

fetchViewWith :: NyaaHttpConfig -> TorrentSite -> Int -> IO (Either NyaaError BS.ByteString)
fetchViewWith cfg site vid =
  runSafe cfg (get (siteUrl site /: "view" /: T.pack (show vid)) (userAgentOpt cfg))

fetchUserPage :: TorrentSite -> Text -> IO (Either NyaaError BS.ByteString)
fetchUserPage = fetchUserPageWith defaultNyaaHttpConfig

fetchUserPageWith :: NyaaHttpConfig -> TorrentSite -> Text -> IO (Either NyaaError BS.ByteString)
fetchUserPageWith cfg site username =
  runSafe cfg (get (siteUrl site /: "user" /: username) (userAgentOpt cfg))

fetchSearchRss :: TorrentSite -> SearchParams -> IO (Either NyaaError BS.ByteString)
fetchSearchRss = fetchSearchRssWith defaultNyaaHttpConfig

fetchSearchRssWith :: NyaaHttpConfig -> TorrentSite -> SearchParams -> IO (Either NyaaError BS.ByteString)
fetchSearchRssWith cfg site sp = runSafe cfg $ get (siteUrl site) opts
  where
    opts = mconcat
      [ "f"    =: spFilters sp
      , "c"    =: categoryParam sp
      , "q"    =: spKeyword sp
      , "s"    =: sortFieldText (spSort sp)
      , "o"    =: sortOrderText (spOrder sp)
      , "page" =: ("rss" :: Text)
      , userAgentOpt cfg
      ]

fetchSearchHtml :: TorrentSite -> SearchParams -> IO (Either NyaaError BS.ByteString)
fetchSearchHtml = fetchSearchHtmlWith defaultNyaaHttpConfig

fetchSearchHtmlWith :: NyaaHttpConfig -> TorrentSite -> SearchParams -> IO (Either NyaaError BS.ByteString)
fetchSearchHtmlWith cfg site sp = runSafe cfg $ get url opts
  where
    username = fromMaybe "" (spUser sp)
    url      = siteUrl site /: "user" /: username
    pageOpt  = if spPage sp > 0 then "p" =: spPage sp else mempty
    opts     = mconcat
      [ "f" =: spFilters sp
      , "c" =: categoryParam sp
      , "q" =: spKeyword sp
      , "s" =: sortFieldText (spSort sp)
      , "o" =: sortOrderText (spOrder sp)
      , pageOpt
      , userAgentOpt cfg
      ]