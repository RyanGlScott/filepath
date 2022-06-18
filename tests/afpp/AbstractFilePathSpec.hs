{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ViewPatterns #-}

module AbstractFilePathSpec where

import Data.Maybe

import System.AbstractFilePath
import System.OsString.Internal.Types
import System.AbstractFilePath.Posix as Posix
import System.AbstractFilePath.Windows as Windows
import System.AbstractFilePath.Encoding
import qualified System.OsString.Internal.Types as OS
import System.AbstractFilePath.Data.ByteString.Short ( toShort )

import Data.ByteString ( ByteString )
import qualified Data.ByteString as BS

import Arbitrary
import Test.Tasty
import Test.Tasty.QuickCheck
import Test.QuickCheck.Classes
import Test.QuickCheck.Checkers


fromRight :: b -> Either a b -> b
fromRight _ (Right b) = b
fromRight b _         = b


tests :: [TestTree]
tests =
  [ testProperty "fromAbstractFilePathUtf . toAbstractFilePathUtf == id" $
    \(NonNullString str) -> (fromAbstractFilePathUtf . fromJust . toAbstractFilePathUtf) str == Just str
  , testProperty "fromPlatformStringUtf . toPlatformStringUtf == id (Posix)" $
    \(NonNullString str) -> (Posix.fromPlatformStringUtf . fromJust . Posix.toPlatformStringUtf) str == Just str
  , testProperty "fromPlatformStringUtf . toPlatformStringUtf == id (Windows)" $
    \(NonNullString str) -> (Windows.fromPlatformStringUtf . fromJust . Windows.toPlatformStringUtf) str == Just str
  , testProperty "toPlatformStringEnc ucs2le . fromPlatformStringEnc ucs2le == id (Posix)" $
    \(padEven -> bs) -> (Posix.toPlatformStringEnc ucs2le . (\(Right r) -> r) . Posix.fromPlatformStringEnc ucs2le . OS.PS . toShort) bs
           === Right (OS.PS . toShort $ bs)
  , testProperty "toPlatformStringEnc ucs2le . fromPlatformStringEnc ucs2le == id (Windows)" $
    \(padEven -> bs) -> (Windows.toPlatformStringEnc ucs2le . (\(Right r) -> r) . Windows.fromPlatformStringEnc ucs2le . OS.WS . toShort) bs
           === Right (OS.WS . toShort $ bs)

  ] ++ testBatch (ord (\(a :: AbstractFilePath) -> pure a))
    ++ testBatch (monoid (undefined :: AbstractFilePath))

    ++ testBatch (ord (\(a :: OsString) -> pure a))
    ++ testBatch (monoid (undefined :: OsString))

    ++ testBatch (ord (\(a :: WindowsString) -> pure a))
    ++ testBatch (monoid (undefined :: WindowsString))

    ++ testBatch (ord (\(a :: PosixString) -> pure a))
    ++ testBatch (monoid (undefined :: PosixString))

    ++ testBatch (ord (\(a :: PlatformString) -> pure a))
    ++ testBatch (monoid (undefined :: PlatformString))

-- | Allows to insert a 'TestBatch' into a Spec.
testBatch :: TestBatch -> [TestTree]
testBatch (_, tests') =
    fmap (\(str, prop) -> testProperty str prop) tests'


padEven :: ByteString -> ByteString
padEven bs
  | even (BS.length bs) = bs
  | otherwise = bs `BS.append` BS.pack [70]