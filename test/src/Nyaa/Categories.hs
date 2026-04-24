module Nyaa.Categories
  ( nyaaCategories
  , sukebeiCategories
  , categoryForSite
  ) where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T
import Nyaa.Types (TorrentSite (..))


nyaaCategoryMap :: Map (Text, Text) Text
nyaaCategoryMap = Map.fromList
  [ (("1","1"), "Anime - Anime Music Video")
  , (("1","2"), "Anime - English-translated")
  , (("1","3"), "Anime - Non-English-translated")
  , (("1","4"), "Anime - Raw")
  , (("2","1"), "Audio - Lossless")
  , (("2","2"), "Audio - Lossy")
  , (("3","1"), "Literature - English-translated")
  , (("3","2"), "Literature - Non-English-translated")
  , (("3","3"), "Literature - Raw")
  , (("4","1"), "Live Action - English-translated")
  , (("4","2"), "Live Action - Idol/Promotional Video")
  , (("4","3"), "Live Action - Non-English-translated")
  , (("4","4"), "Live Action - Raw")
  , (("5","1"), "Pictures - Graphics")
  , (("5","2"), "Pictures - Photos")
  , (("6","1"), "Software - Applications")
  , (("6","2"), "Software - Games")
  ]

sukebeyCategoryMap :: Map (Text, Text) Text
sukebeyCategoryMap = Map.fromList
  [ (("1","1"), "Art - Anime")
  , (("1","2"), "Art - Doujinshi")
  , (("1","3"), "Art - Games")
  , (("1","4"), "Art - Manga")
  , (("1","5"), "Art - Pictures")
  , (("2","1"), "Real Life - Photobooks & Pictures")
  , (("2","2"), "Real Life - Videos")
  ]

lookupCategory :: Map (Text, Text) Text -> Text -> Text
lookupCategory m raw =
  let code  = if "=" `T.isInfixOf` raw
                then T.drop 1 $ T.dropWhile (/= '=') raw
                else raw
      parts = T.splitOn "_" code
  in case parts of
       [cat, sub] -> Map.findWithDefault "Unknown" (cat, sub) m
       _          -> "Unknown"

nyaaCategories :: Text -> Text
nyaaCategories = lookupCategory nyaaCategoryMap

sukebeiCategories :: Text -> Text
sukebeiCategories = lookupCategory sukebeyCategoryMap

categoryForSite :: TorrentSite -> Text -> Text
categoryForSite NyaaSi        = nyaaCategories
categoryForSite NyaaLand      = nyaaCategories
categoryForSite SukebeiNyaaSi = sukebeiCategories