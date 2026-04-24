module Nyaa.Magnet
  ( magnetBuilder
  , magnetTrackers
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Network.HTTP.Types.URI as URI

magnetTrackers :: [Text]
magnetTrackers =
  [ "http://nyaa.tracker.wf:7777/announce"
  , "udp://open.stealth.si:80/announce"
  , "udp://tracker.opentrackr.org:1337/announce"
  , "udp://exodus.desync.com:6969/announce"
  , "udp://tracker.torrent.eu.org:451/announce"
  ]

magnetBuilder :: Text -> Text -> Text
magnetBuilder infoHash title =
  "magnet:?xt=urn:btih:" <> infoHash
  <> "&dn=" <> pct title
  <> T.concat (map (\t -> "&tr=" <> pct t) magnetTrackers)

pct :: Text -> Text
pct = TE.decodeUtf8 . URI.urlEncode False . TE.encodeUtf8