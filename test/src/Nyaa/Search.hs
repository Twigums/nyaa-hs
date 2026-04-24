module Nyaa.Search
  ( lastUploads
  , lastUploadsWith
  , search
  , searchWith
  , getTorrent
  , getTorrentWith
  , getFromUser
  , getFromUserWith
  ) where

import Data.Text (Text)
import Nyaa.Types
import Nyaa.Internal.Http
import Nyaa.Internal.Parser


lastUploads :: TorrentSite -> Maybe Int -> IO (Either NyaaError [Torrent])
lastUploads = lastUploadsWith defaultNyaaHttpConfig

lastUploadsWith :: NyaaHttpConfig -> TorrentSite -> Maybe Int -> IO (Either NyaaError [Torrent])
lastUploadsWith cfg site mlimit = do
  result <- fetchListingWith cfg site
  return $ result >>= parseNyaa site mlimit

search :: TorrentSite -> SearchParams -> IO (Either NyaaError [Torrent])
search = searchWith defaultNyaaHttpConfig

searchWith :: NyaaHttpConfig -> TorrentSite -> SearchParams -> IO (Either NyaaError [Torrent])
searchWith cfg site sp =
  case spUser sp of
    Nothing -> do
      result <- fetchSearchRssWith cfg site sp
      return $ result >>= parseNyaaRss site Nothing
    Just _ -> do
      result <- fetchSearchHtmlWith cfg site sp
      return $ result >>= parseNyaa site Nothing

getTorrent :: TorrentSite -> Int -> IO (Either NyaaError TorrentDetail)
getTorrent = getTorrentWith defaultNyaaHttpConfig

getTorrentWith :: NyaaHttpConfig -> TorrentSite -> Int -> IO (Either NyaaError TorrentDetail)
getTorrentWith cfg site vid = do
  result <- fetchViewWith cfg site vid
  return $ result >>= parseSingle site

getFromUser :: TorrentSite -> Text -> Maybe Int -> IO (Either NyaaError [Torrent])
getFromUser = getFromUserWith defaultNyaaHttpConfig

getFromUserWith :: NyaaHttpConfig -> TorrentSite -> Text -> Maybe Int -> IO (Either NyaaError [Torrent])
getFromUserWith cfg site username mlimit = do
  result <- fetchUserPageWith cfg site username
  return $ result >>= parseNyaa site mlimit