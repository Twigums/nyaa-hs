module Nyaa.Site.Nyaa
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
lastUploads = S.lastUploads NyaaSi

lastUploadsWith :: NyaaHttpConfig -> Maybe Int -> IO (Either NyaaError [Torrent])
lastUploadsWith cfg = S.lastUploadsWith cfg NyaaSi

search :: SearchParams -> IO (Either NyaaError [Torrent])
search = S.search NyaaSi

searchWith :: NyaaHttpConfig -> SearchParams -> IO (Either NyaaError [Torrent])
searchWith cfg = S.searchWith cfg NyaaSi

getTorrent :: Int -> IO (Either NyaaError TorrentDetail)
getTorrent = S.getTorrent NyaaSi

getTorrentWith :: NyaaHttpConfig -> Int -> IO (Either NyaaError TorrentDetail)
getTorrentWith cfg = S.getTorrentWith cfg NyaaSi

getFromUser :: Text -> Maybe Int -> IO (Either NyaaError [Torrent])
getFromUser = S.getFromUser NyaaSi

getFromUserWith :: NyaaHttpConfig -> Text -> Maybe Int -> IO (Either NyaaError [Torrent])
getFromUserWith cfg = S.getFromUserWith cfg NyaaSi