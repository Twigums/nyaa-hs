module Nyaa.Internal.Parser.Rss
  ( parseNyaaRss
  ) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.Maybe (listToMaybe, mapMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Default.Class (def)
import Text.XML (parseLBS, Name (..))
import Text.XML.Cursor
  ( Cursor, fromDocument
  , ($//), element, child, content
  )
import Nyaa.Categories (categoryForSite)
import Nyaa.Magnet (magnetBuilder)
import Nyaa.Types
import Nyaa.Internal.Utils (lastSegment, readInt)


nyaaNs :: Text
nyaaNs = "https://nyaa.si/xmlns/nyaa"

nyaaName :: Text -> Name
nyaaName local = Name local (Just nyaaNs) Nothing

parseNyaaRss :: TorrentSite -> Maybe Int -> BS.ByteString -> Either NyaaError [Torrent]
parseNyaaRss site mlimit bytes =
  case parseLBS def (LBS.fromStrict bytes) of
    Left err  -> Left (ParseError (T.pack $ show err))
    Right doc ->
      let cursor  = fromDocument doc
          items   = cursor $// element "item"
          limited = maybe items (`take` items) mlimit
      in Right (mapMaybe (itemToTorrent site) limited)

itemToTorrent :: TorrentSite -> Cursor -> Maybe Torrent
itemToTorrent site cur = do
  title  <- listToMaybe $ elemText "title"  cur
  link   <- listToMaybe $ elemText "link"   cur
  guid   <- listToMaybe $ elemText "guid"   cur
  let pubDate   = headMayDef "" $ elemText "pubDate"                cur
      infoHash  = headMayDef "" $ nyaaText "infoHash"               cur
      catName   = headMayDef "" $ nyaaText "category"               cur
      catId     = headMayDef "" $ nyaaText "categoryId"             cur
      seeders   = readInt   $ headMayDef "0" $ nyaaText "seeders"   cur
      leechers  = readInt   $ headMayDef "0" $ nyaaText "leechers"  cur
      trusted   = headMayDef "No" $ nyaaText "trusted"              cur
      remake    = headMayDef "No" $ nyaaText "remake"               cur
      category  = if T.null catName
                    then categoryForSite site catId
                    else catName
      torType   = torrentType' remake trusted
      viewId    = lastSegment guid
      magnet    = if T.null infoHash then "" else magnetBuilder infoHash title

  return Torrent
    { torrentId                 = viewId
    , torrentCategory           = category
    , torrentUrl                = guid
    , torrentName               = title
    , torrentDownloadUrl        = link
    , torrentMagnet             = magnet
    , torrentSize               = headMayDef "" (nyaaText "size" cur)
    , torrentDate               = pubDate
    , torrentSeeders            = seeders
    , torrentLeechers           = leechers
    , torrentCompletedDownloads = Nothing
    , torrentType               = torType
    }

elemText :: Text -> Cursor -> [Text]
elemText name c = (c $// element (Name name Nothing Nothing)) >>= child >>= content

nyaaText :: Text -> Cursor -> [Text]
nyaaText name c = (c $// element (nyaaName name)) >>= child >>= content

torrentType' :: Text -> Text -> TorrentType
torrentType' "Yes" _     = Remake
torrentType' _     "Yes" = Trusted
torrentType' _     _     = Normal

headMayDef :: a -> [a] -> a
headMayDef d [] = d
headMayDef _ (x:_) = x