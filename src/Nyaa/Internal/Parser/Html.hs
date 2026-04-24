module Nyaa.Internal.Parser.Html
  ( parseNyaa
  , parseSingle
  ) where

import Control.Monad (guard)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.List (find)
import Data.Maybe (listToMaybe, mapMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Text.HTML.DOM as HTML
import Text.XML.Cursor
  ( Cursor, fromDocument
  , ($//), ($/)
  , element, attribute, attributeIs, content, child, descendant
  )
import Nyaa.Categories (categoryForSite)
import Nyaa.Types
import Nyaa.Internal.Utils (lastSegment, readInt)


parseNyaa :: TorrentSite -> Maybe Int -> BS.ByteString -> Either NyaaError [Torrent]
parseNyaa site mlimit bytes =
  let doc     = HTML.parseLBS (LBS.fromStrict bytes)
      cursor  = fromDocument doc
      rows    = (cursor $// element "tbody") >>= (\c -> c $/ element "tr")
      limited = maybe rows (`take` rows) mlimit
  in Right (mapMaybe (rowToTorrent site) limited)

rowToTorrent :: TorrentSite -> Cursor -> Maybe Torrent
rowToTorrent site tr = do
  let tds  = tr $/ element "td"
      cls  = listToMaybe (attribute "class" tr)
      base = siteBaseUrl site

  guard (length tds >= 7)

  let td0 = tds !! 0
      td1 = tds !! 1
      td2 = tds !! 2
      td3 = tds !! 3
      td4 = tds !! 4
      td5 = tds !! 5
      td6 = tds !! 6

  catHref <- listToMaybe ((td0 $// element "a") >>= attribute "href")

  let category  = categoryForSite site catHref
  let viewLinks = filter (not . isCommentLink) (td1 $// element "a")
  nameLink <- listToMaybe viewLinks
  viewHref <- listToMaybe (attribute "href" nameLink)
  torName  <- listToMaybe
                (  attribute "title" nameLink
                <> (child nameLink >>= content)
                )

  let viewId = lastSegment viewHref

  let allLinks = td2 $// element "a"
      dlLinks  = filter (not . isMagnetLink) allLinks
      magLinks = filter isMagnetLink allLinks

  dlHref  <- listToMaybe (dlLinks  >>= attribute "href")
  magHref <- listToMaybe (magLinks >>= attribute "href")

  let size      = curDescText td3
      date      = curDescText td4
      seeders   = readInt (curDescText td5)
      leechers  = readInt (curDescText td6)
      completed = if length tds >= 8
                    then Just (readInt (curDescText (tds !! 7)))
                    else Nothing

  return Torrent
    { torrentId                 = viewId
    , torrentCategory           = category
    , torrentUrl                = base <> "/view/" <> viewId
    , torrentName               = torName
    , torrentDownloadUrl        = base <> dlHref
    , torrentMagnet             = magHref
    , torrentSize               = size
    , torrentDate               = date
    , torrentSeeders            = seeders
    , torrentLeechers           = leechers
    , torrentCompletedDownloads = completed
    , torrentType               = classToType cls
    }


parseSingle :: TorrentSite -> BS.ByteString -> Either NyaaError TorrentDetail
parseSingle site bytes =
  let doc    = HTML.parseLBS (LBS.fromStrict bytes)
      cursor = fromDocument doc
      base   = siteBaseUrl site
  in maybe
       (Left (ParseError "Failed to parse torrent detail page."))
       Right
       (extractDetail base cursor)

extractDetail :: Text -> Cursor -> Maybe TorrentDetail
extractDetail base cursor = do
  title <- listToMaybe
    ((cursor $// element "h3") >>= filterClass "panel-title"
             >>= child >>= content)

  let fields = buildFieldMap cursor

  category  <- lookupField "Category"   fields
  date      <- lookupField "Date"        fields
  uploader  <- lookupField "Submitter"   fields
  seeders   <- lookupField "Seeders"     fields
  leechers  <- lookupField "Leechers"    fields
  size      <- lookupField "File size"   fields
  completed <- lookupField "Completed"   fields
  infoHash  <- lookupField "Info hash"   fields

  let website     = lookupField "Information" fields >>= nonEmpty
      uploaderUrl = base <> "/user/" <> uploader

  let dlUrlM  = listToMaybe
          ((cursor $// element "a") >>= filterClass "card-footer-item"
                  >>= attribute "href")
      viewId  = maybe "" lastSegment dlUrlM

  magnetHref <- listToMaybe
    (filter (T.isPrefixOf "magnet:") ((cursor $// element "a") >>= attribute "href"))

  let files = map (FileEntry . T.strip)
        (  (cursor $// element "div") >>= filterClass "torrent-file-list"
        >>= (\c -> c $// element "li")
        >>= child >>= content
        )

  let desc = T.concat
        ((cursor $// element "div") >>= attributeIs "id" "torrent-description"
                >>= descendant >>= content)

  let panelCls = listToMaybe
        (  (cursor $// element "div") >>= filterClass "panel"
        >>= attribute "class"
        )
      torType = classToType panelCls

  return TorrentDetail
    { detailId              = viewId
    , detailTitle           = title
    , detailCategory        = category
    , detailUrl             = base <> "/view/" <> viewId
    , detailDownloadUrl     = maybe "" (base <>) dlUrlM
    , detailMagnet          = magnetHref
    , detailSize            = size
    , detailDate            = date
    , detailSeeders         = readInt seeders
    , detailLeechers        = readInt leechers
    , detailCompleted       = readInt completed
    , detailType            = torType
    , detailUploader        = uploader
    , detailUploaderProfile = uploaderUrl
    , detailWebsite         = website
    , detailInfoHash        = infoHash
    , detailFiles           = files
    , detailDescription     = desc
    }

buildFieldMap :: Cursor -> [(Text, Text)]
buildFieldMap cursor =
  let rows = (cursor $// element "div") >>= filterClass "row"
  in concatMap rowPairs rows
  where
    rowPairs row =
      let labelCursors = (row $/ element "div") >>= filterClass "col-md-1"
          valueCursors = (row $/ element "div") >>= filterClass "col-md-5"
          labels = map (T.dropWhileEnd (== ':') . curDescText) labelCursors
          values = map curDescText valueCursors
      in zip labels values

lookupField :: Text -> [(Text, Text)] -> Maybe Text
lookupField k = fmap snd . find ((== k) . fst)

filterClass :: Text -> Cursor -> [Cursor]
filterClass cls c
  | cls `T.isInfixOf` T.concat (attribute "class" c) = [c]
  | otherwise                                          = []

classToType :: Maybe Text -> TorrentType
classToType Nothing    = Normal
classToType (Just cls)
  | "danger"  `T.isInfixOf` cls = Remake
  | "success" `T.isInfixOf` cls = Trusted
  | otherwise                    = Normal

isCommentLink :: Cursor -> Bool
isCommentLink c = any (T.isSuffixOf "#comments") (attribute "href" c)

isMagnetLink :: Cursor -> Bool
isMagnetLink c = any (T.isPrefixOf "magnet:") (attribute "href" c)

curDescText :: Cursor -> Text
curDescText c = T.strip $ T.concat (descendant c >>= content)

nonEmpty :: Text -> Maybe Text
nonEmpty t
  | T.null (T.strip t) = Nothing
  | otherwise          = Just t