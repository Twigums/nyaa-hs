module Main (main) where

import Data.Aeson (encode, ToJSON)
import qualified Data.ByteString.Lazy.Char8 as BSLC
import Data.Maybe (listToMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import System.Environment (getArgs)
import System.Exit (exitFailure)

import Nyaa.Types
import qualified Nyaa.Site.Nyaa    as Nyaa
import qualified Nyaa.Site.Sukebei as Sukebei

main :: IO ()
main = do
  args <- getArgs
  case args of
    ("nyaa"    : rest) -> dispatch Nyaa.lastUploads    Nyaa.search    Nyaa.getTorrent    Nyaa.getFromUser    rest
    ("sukebei" : rest) -> dispatch Sukebei.lastUploads Sukebei.search Sukebei.getTorrent Sukebei.getFromUser rest
    _                  -> dispatch Nyaa.lastUploads    Nyaa.search    Nyaa.getTorrent    Nyaa.getFromUser    args

type LastFn   = Maybe Int     -> IO (Either NyaaError [Torrent])
type SearchFn = SearchParams  -> IO (Either NyaaError [Torrent])
type GetFn    = Int           -> IO (Either NyaaError TorrentDetail)
type UserFn   = Text -> Maybe Int -> IO (Either NyaaError [Torrent])

dispatch :: LastFn -> SearchFn -> GetFn -> UserFn -> [String] -> IO ()
dispatch lastFn searchFn getFn userFn args =
  case args of
    ["last"] ->
      printResult =<< lastFn Nothing

    ["last", n] ->
      printResult =<< lastFn (Just (read n))

    ("search" : kw : rest) -> do
      let sp = (defaultSearchParams (T.pack kw))
                 { spPage = maybe 0 read (listToMaybe rest) }
      printResult =<< searchFn sp

    ["get", vid] ->
      printResult =<< getFn (read vid)

    ["user", username] ->
      printResult =<< userFn (T.pack username) Nothing

    ["user", username, n] ->
      printResult =<< userFn (T.pack username) (Just (read n))

    _ -> putStrLn usage >> exitFailure

printResult :: ToJSON a => Either NyaaError a -> IO ()
printResult (Left e)  = putStrLn ("Error: " <> show e) >> exitFailure
printResult (Right v) = BSLC.putStrLn (encode v)

usage :: String
usage = unlines
  [ "Usage: nyaa {site} {command} {args}"
  , ""
  , "Sites {site: optional}:"
  , "  nyaa (default; sfw)"
  , "  sukebei (nsfw)"
  , ""
  , "Commands {command: required} {args: optional/required}:"
  , "  last {n}                Last `n` uploads (`n`: optional)"
  , "  search {keyword} {page} Search by `keyword` on `page` (`keyword`: required; `page`: optional)"
  , "  get {id}                View details of torrent given `id` (`id`: required)"
  , "  user {name} {lim}       View uploads by user limited to `lim` items (`name`: required; `lim`: optional)"
  , ""
  , "Examples:"
  , "  nyaa search \"attack on titan\"   -> Returns all available torrent information for \"attack on titan\""
  , "  nyaa nyaa last 10               -> Returns the last 10 uploads on nyaa"
  , "  nyaa sukebei search foo 2       -> Returns all available torrent information on page 2 of sukebei for \"foo\""
  , "  nyaa get 111                    -> Returns torrent information on torrent with `id = 111`"
  , "  nyaa user Twigums 67            -> Returns, at most, 67 torrent items by `user = Twigums`"
  ]