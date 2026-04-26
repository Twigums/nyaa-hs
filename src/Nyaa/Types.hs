module Nyaa.Types
  ( TorrentSite (..)
  , siteDomain
  , siteBaseUrl
  , TorrentType (..)
  , Torrent (..)
  , TorrentDetail (..)
  , FileEntry (..)
  , SearchParams (..)
  , defaultSearchParams
  , withPage
  , withSort
  , withOrder
  , withCategory
  , withUser
  , withFilters
  , SortField (..)
  , sortFieldText
  , SortOrder (..)
  , sortOrderText
  , NyaaError (..)
  , NyaaProxy (..)
  , NyaaHttpConfig (..)
  , defaultNyaaHttpConfig
  ) where

import Control.Exception (Exception)
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

data TorrentSite
  = NyaaSi
  | SukebeiNyaaSi
  | NyaaLand
  deriving stock (Eq, Show, Enum, Bounded)

siteDomain :: TorrentSite -> Text
siteDomain NyaaSi        = "nyaa.si"
siteDomain SukebeiNyaaSi = "sukebei.nyaa.si"
siteDomain NyaaLand      = "nyaa.land"

siteBaseUrl :: TorrentSite -> Text
siteBaseUrl = ("https://" <>) . siteDomain

data TorrentType = Normal | Remake | Trusted
  deriving stock (Eq, Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data Torrent = Torrent
  { torrentId                 :: Text
  , torrentCategory           :: Text
  , torrentUrl                :: Text
  , torrentName               :: Text
  , torrentDownloadUrl        :: Text
  , torrentMagnet             :: Text
  , torrentSize               :: Text
  , torrentDate               :: Text
  , torrentSeeders            :: Int
  , torrentLeechers           :: Int
  , torrentCompletedDownloads :: Maybe Int
  , torrentType               :: TorrentType
  } deriving stock (Eq, Show, Generic)
    deriving anyclass (ToJSON, FromJSON)

data TorrentDetail = TorrentDetail
  { detailId              :: Text
  , detailTitle           :: Text
  , detailCategory        :: Text
  , detailUrl             :: Text
  , detailDownloadUrl     :: Text
  , detailMagnet          :: Text
  , detailSize            :: Text
  , detailDate            :: Text
  , detailSeeders         :: Int
  , detailLeechers        :: Int
  , detailCompleted       :: Int
  , detailType            :: TorrentType
  , detailUploader        :: Text
  , detailUploaderProfile :: Text
  , detailWebsite         :: Maybe Text
  , detailInfoHash        :: Text
  , detailFiles           :: [FileEntry]
  , detailDescription     :: Text
  } deriving stock (Eq, Show, Generic)
    deriving anyclass (ToJSON, FromJSON)

newtype FileEntry = FileEntry { fileName :: Text }
  deriving stock (Eq, Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data SortField
  = SortById
  | SortBySize
  | SortBySeeders
  | SortByLeechers
  | SortByDownloads
  deriving stock (Eq, Show, Generic)

sortFieldText :: SortField -> Text
sortFieldText SortById        = "id"
sortFieldText SortBySize      = "size"
sortFieldText SortBySeeders   = "seeders"
sortFieldText SortByLeechers  = "leechers"
sortFieldText SortByDownloads = "downloads"

data SortOrder = Asc | Desc
  deriving stock (Eq, Show, Generic)

sortOrderText :: SortOrder -> Text
sortOrderText Asc  = "asc"
sortOrderText Desc = "desc"

data SearchParams = SearchParams
  { spKeyword     :: Text
  , spUser        :: Maybe Text
  , spCategory    :: Int
  , spSubcategory :: Int
  , spFilters     :: Int
  , spPage        :: Int
  , spSort        :: SortField
  , spOrder       :: SortOrder
  } deriving stock (Eq, Show)

defaultSearchParams :: Text -> SearchParams
defaultSearchParams kw = SearchParams
  { spKeyword     = kw
  , spUser        = Nothing
  , spCategory    = 0
  , spSubcategory = 0
  , spFilters     = 2
  , spPage        = 0
  , spSort        = SortById
  , spOrder       = Desc
  }

withPage :: Int -> SearchParams -> SearchParams
withPage n sp = sp { spPage = n }

withSort :: SortField -> SearchParams -> SearchParams
withSort f sp = sp { spSort = f }

withOrder :: SortOrder -> SearchParams -> SearchParams
withOrder o sp = sp { spOrder = o }

withCategory :: Int -> Int -> SearchParams -> SearchParams
withCategory cat sub sp = sp { spCategory = cat, spSubcategory = sub }

withUser :: Text -> SearchParams -> SearchParams
withUser u sp = sp { spUser = Just u }

withFilters :: Int -> SearchParams -> SearchParams
withFilters f sp = sp { spFilters = f }

data NyaaError
  = HttpError Text
  | ParseError Text
  | NotFound Text
  deriving stock (Eq, Show)

instance Exception NyaaError

data NyaaProxy = NyaaProxy
  { nyaaProxyHost :: Text
  , nyaaProxyPort :: Int
  } deriving stock (Eq, Show)

data NyaaHttpConfig = NyaaHttpConfig
  { nhcUserAgent     :: Maybe Text
  , nhcProxy         :: Maybe NyaaProxy
  , nhcRedirectCount :: Int
  } deriving stock (Eq, Show)

defaultNyaaHttpConfig :: NyaaHttpConfig
defaultNyaaHttpConfig = NyaaHttpConfig
  { nhcUserAgent     = Nothing
  , nhcProxy         = Nothing
  , nhcRedirectCount = 10
  }