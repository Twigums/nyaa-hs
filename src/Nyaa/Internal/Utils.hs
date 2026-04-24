module Nyaa.Internal.Utils
  ( lastSegment
  , readInt
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Read as TR

lastSegment :: Text -> Text
lastSegment t = case T.splitOn "/" t of
  [] -> t
  xs -> last xs

readInt :: Text -> Int
readInt t = case TR.decimal (T.strip t) of
  Right (n, _) -> n
  Left _        -> 0