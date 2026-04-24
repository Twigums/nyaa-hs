module Nyaa.Site.Sukebei
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
import qualified Nyaa.Search as S

lastUploads :: Maybe Int -> IO (Either NyaaError [Torrent])
lastUploads = S.lastUploads SukebeiNyaaSi

lastUploadsWith :: NyaaHttpConfig -> Maybe Int -> IO (Either NyaaError [Torrent])
lastUploadsWith cfg = S.lastUploadsWith cfg SukebeiNyaaSi

search :: SearchParams -> IO (Either NyaaError [Torrent])
search = S.search SukebeiNyaaSi

searchWith :: NyaaHttpConfig -> SearchParams -> IO (Either NyaaError [Torrent])
searchWith cfg = S.searchWith cfg SukebeiNyaaSi

getTorrent :: Int -> IO (Either NyaaError TorrentDetail)
getTorrent = S.getTorrent SukebeiNyaaSi

getTorrentWith :: NyaaHttpConfig -> Int -> IO (Either NyaaError TorrentDetail)
getTorrentWith cfg = S.getTorrentWith cfg SukebeiNyaaSi

getFromUser :: Text -> Maybe Int -> IO (Either NyaaError [Torrent])
getFromUser = S.getFromUser SukebeiNyaaSi

getFromUserWith :: NyaaHttpConfig -> Text -> Maybe Int -> IO (Either NyaaError [Torrent])
getFromUserWith cfg = S.getFromUserWith cfg SukebeiNyaaSi