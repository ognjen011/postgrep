{-# LANGUAGE OverloadedStrings #-}

-- | This module defines the various options and types associated with the log
-- line prefix.

module PostGrep.LogPrefix
  ( LogLinePrefix (..)
  , rdsPrefix
  , parseLogLinePrefix
  , LogLinePrefixComponent (..)
  , LogLinePrefixEscape (..)
  , logLinePrefixEscapeChar
  ) where

import Control.Applicative ((<|>))
import Data.Attoparsec.Text
import qualified Data.Text as T

-- | Represents a parsed log_line_prefix. This is used to extract data from log
-- entries.
newtype LogLinePrefix = LogLinePrefix { unLogLinePrefix :: [LogLinePrefixComponent] }
                      deriving (Show)

-- | Default prefix for AWS RDS.
rdsPrefix :: LogLinePrefix
rdsPrefix =
  case parseLogLinePrefix "%t:%r:%u@%d:[%p]:" of
    (Left err) -> error $ "Failed to parse RDS log line prefix: " ++ err
    (Right p) -> p

data LogLinePrefixComponent
  = LogLineLiteral T.Text
  | LogLineEscape LogLinePrefixEscape
  deriving (Show)

-- | Type enumerating the possible escape characters in a log_line_prefix.
data LogLinePrefixEscape
  = ApplicationNameEscape
  | UserNameEscape
  | DatabaseNameEscape
  | RemoteHostWithPortEscape
  | RemoteHostEscape
  | ProcessIDEscape
  | TimestampWithoutMillisecondsEscape
  | TimestampWithMillisecondsEscape
  | CommandTagEscape
  | SQLStateErrorCodeEscape
  | SessionIDEscape
  | LogLineNumberEscape
  | ProcessStartTimestampEscape
  | VirtualTransactionIDEscape
  | TransactionIDEscape
  | NonSessionStopEscape
  | LiteralPercentEscape
  deriving (Show)

-- | The corresponding escape character for each 'LogLinePrefixEscape'
logLinePrefixEscapeChar :: LogLinePrefixEscape -> Char
logLinePrefixEscapeChar ApplicationNameEscape = 'a'
logLinePrefixEscapeChar UserNameEscape = 'u'
logLinePrefixEscapeChar DatabaseNameEscape = 'd'
logLinePrefixEscapeChar RemoteHostWithPortEscape = 'r'
logLinePrefixEscapeChar RemoteHostEscape = 'h'
logLinePrefixEscapeChar ProcessIDEscape = 'p'
logLinePrefixEscapeChar TimestampWithoutMillisecondsEscape = 't'
logLinePrefixEscapeChar TimestampWithMillisecondsEscape = 'm'
logLinePrefixEscapeChar CommandTagEscape = 'i'
logLinePrefixEscapeChar SQLStateErrorCodeEscape = 'e'
logLinePrefixEscapeChar SessionIDEscape = 'c'
logLinePrefixEscapeChar LogLineNumberEscape = 'l'
logLinePrefixEscapeChar ProcessStartTimestampEscape = 's'
logLinePrefixEscapeChar VirtualTransactionIDEscape = 'v'
logLinePrefixEscapeChar TransactionIDEscape = 'x'
logLinePrefixEscapeChar NonSessionStopEscape = 'q'
logLinePrefixEscapeChar LiteralPercentEscape = '%'

charToEscape :: Char -> Maybe LogLinePrefixEscape
charToEscape 'a' = Just ApplicationNameEscape
charToEscape 'u' = Just UserNameEscape
charToEscape 'd' = Just DatabaseNameEscape
charToEscape 'r' = Just RemoteHostWithPortEscape
charToEscape 'h' = Just RemoteHostEscape
charToEscape 'p' = Just ProcessIDEscape
charToEscape 't' = Just TimestampWithoutMillisecondsEscape
charToEscape 'm' = Just TimestampWithMillisecondsEscape
charToEscape 'i' = Just CommandTagEscape
charToEscape 'e' = Just SQLStateErrorCodeEscape
charToEscape 'c' = Just SessionIDEscape
charToEscape 'l' = Just LogLineNumberEscape
charToEscape 's' = Just ProcessStartTimestampEscape
charToEscape 'v' = Just VirtualTransactionIDEscape
charToEscape 'x' = Just TransactionIDEscape
charToEscape 'q' = Just NonSessionStopEscape
charToEscape '%' = Just LiteralPercentEscape
charToEscape _ = Nothing

parseLogLinePrefix :: T.Text -> Either String LogLinePrefix
parseLogLinePrefix = parseOnly prefixParser

prefixParser :: Parser LogLinePrefix
prefixParser = LogLinePrefix <$> many1 componentParser

componentParser :: Parser LogLinePrefixComponent
componentParser = parseEscape <|> parseLiteral

parseLiteral :: Parser LogLinePrefixComponent
parseLiteral = LogLineLiteral <$> takeWhile1 (/= '%')

parseEscape :: Parser LogLinePrefixComponent
parseEscape = do
  _ <- char '%'
  escapeChar <- anyChar
  case charToEscape escapeChar of
    Nothing -> fail $ "Unknown escape character '" ++ [escapeChar] ++ "'"
    (Just e) -> return $ LogLineEscape e
