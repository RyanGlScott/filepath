{-# LANGUAGE CPP #-}

module TestUtil(
    module TestUtil,
    module Test.QuickCheck,
    module Data.List,
    module Data.Maybe
    ) where

import Test.QuickCheck hiding ((==>))
import Data.ByteString.Short (ShortByteString)
import Data.List
import Data.Maybe
import Control.Monad
import qualified System.FilePath.Windows as W
import qualified System.FilePath.Posix as P
#ifdef GHC_MAKE
import qualified System.AbstractFilePath.Windows.Internal as AFP_W
import qualified System.AbstractFilePath.Posix.Internal as AFP_P
#else
import qualified System.AbstractFilePath.Windows as AFP_W
import qualified System.AbstractFilePath.Posix as AFP_P
import System.AbstractFilePath.Types
#endif
import System.AbstractFilePath.Data.ByteString.Short.Decode
import System.AbstractFilePath.Data.ByteString.Short.Encode


infixr 0 ==>
a ==> b = not a || b


newtype QFilePathValidW = QFilePathValidW FilePath deriving Show

instance Arbitrary QFilePathValidW where
    arbitrary = fmap (QFilePathValidW . W.makeValid) arbitraryFilePath
    shrink (QFilePathValidW x) = shrinkValid QFilePathValidW W.makeValid x

newtype QFilePathValidP = QFilePathValidP FilePath deriving Show

instance Arbitrary QFilePathValidP where
    arbitrary = fmap (QFilePathValidP . P.makeValid) arbitraryFilePath
    shrink (QFilePathValidP x) = shrinkValid QFilePathValidP P.makeValid x

newtype QFilePath = QFilePath FilePath deriving Show

instance Arbitrary QFilePath where
    arbitrary = fmap QFilePath arbitraryFilePath
    shrink (QFilePath x) = shrinkValid QFilePath id x


-- | Generate an arbitrary FilePath use a few special (interesting) characters.
arbitraryFilePath :: Gen FilePath
arbitraryFilePath = sized $ \n -> do
    k <- choose (0,n)
    replicateM k $ elements "?./:\\a ;_"

-- | Shrink, but also apply a validity function. Try and make shorter, or use more
--   @a@ (since @a@ is pretty dull), but make sure you terminate even after valid.
shrinkValid :: (FilePath -> a) -> (FilePath -> FilePath) -> FilePath -> [a]
shrinkValid wrap valid o =
    [ wrap y
    | y <- map valid $ shrinkList (\x -> ['a' | x /= 'a']) o
    , length y < length o || (length y == length o && countA y > countA o)]
    where countA = length . filter (== 'a')

#ifdef GHC_MAKE
newtype QFilePathValidAFP_W = QFilePathValidAFP_W ShortByteString deriving Show

instance Arbitrary QFilePathValidAFP_W where
    arbitrary = fmap (QFilePathValidAFP_W . AFP_W.makeValid . encodeUtf16LE) arbitraryFilePath
    shrink (QFilePathValidAFP_W x) = shrinkValid (QFilePathValidAFP_W . encodeUtf16LE) (decodeUtf16LE . AFP_W.makeValid . encodeUtf16LE) (decodeUtf16LE x)

newtype QFilePathValidAFP_P = QFilePathValidAFP_P ShortByteString deriving Show

instance Arbitrary QFilePathValidAFP_P where
    arbitrary = fmap (QFilePathValidAFP_P . AFP_P.makeValid . encodeUtf8) arbitraryFilePath
    shrink (QFilePathValidAFP_P x) = shrinkValid (QFilePathValidAFP_P . encodeUtf8) (decodeUtf8 . AFP_P.makeValid . encodeUtf8) (decodeUtf8 x)

newtype QFilePathAFP_W = QFilePathAFP_W ShortByteString deriving Show
newtype QFilePathAFP_P = QFilePathAFP_P ShortByteString deriving Show

instance Arbitrary QFilePathAFP_W where
    arbitrary = fmap (QFilePathAFP_W . encodeUtf16LE) arbitraryFilePath
    shrink (QFilePathAFP_W x) = shrinkValid (QFilePathAFP_W . encodeUtf16LE) id (decodeUtf16LE x)

instance Arbitrary QFilePathAFP_P where
    arbitrary = fmap (QFilePathAFP_P . encodeUtf8) arbitraryFilePath
    shrink (QFilePathAFP_P x) = shrinkValid (QFilePathAFP_P . encodeUtf8) id (decodeUtf8 x)

newtype QFilePathsAFP_W = QFilePathsAFP_W [ShortByteString] deriving Show
newtype QFilePathsAFP_P = QFilePathsAFP_P [ShortByteString] deriving Show

instance Arbitrary QFilePathsAFP_W where
    arbitrary = fmap (QFilePathsAFP_W . fmap encodeUtf16LE) (listOf arbitraryFilePath)

instance Arbitrary QFilePathsAFP_P where
    arbitrary = fmap (QFilePathsAFP_P . fmap encodeUtf8) (listOf arbitraryFilePath)

#else


newtype QFilePathValidAFP_W = QFilePathValidAFP_W WindowsFilePath deriving Show

instance Arbitrary QFilePathValidAFP_W where
    arbitrary = fmap (QFilePathValidAFP_W . AFP_W.makeValid . WS . encodeUtf16LE) arbitraryFilePath
    shrink (QFilePathValidAFP_W x) = shrinkValid (QFilePathValidAFP_W . WS . encodeUtf16LE) (decodeUtf16LE . unWFP . AFP_W.makeValid . WS . encodeUtf16LE) (decodeUtf16LE . unWFP $ x)

newtype QFilePathValidAFP_P = QFilePathValidAFP_P PosixFilePath deriving Show

instance Arbitrary QFilePathValidAFP_P where
    arbitrary = fmap (QFilePathValidAFP_P . AFP_P.makeValid . PS . encodeUtf8) arbitraryFilePath
    shrink (QFilePathValidAFP_P x) = shrinkValid (QFilePathValidAFP_P . PS . encodeUtf8) (decodeUtf8 . unPFP . AFP_P.makeValid . PS . encodeUtf8) (decodeUtf8 . unPFP $ x)

newtype QFilePathAFP_W = QFilePathAFP_W WindowsFilePath deriving Show
newtype QFilePathAFP_P = QFilePathAFP_P PosixFilePath deriving Show

instance Arbitrary QFilePathAFP_W where
    arbitrary = fmap (QFilePathAFP_W . WS . encodeUtf16LE) arbitraryFilePath
    shrink (QFilePathAFP_W x) = shrinkValid (QFilePathAFP_W . WS . encodeUtf16LE) id (decodeUtf16LE . unWFP $ x)

instance Arbitrary QFilePathAFP_P where
    arbitrary = fmap (QFilePathAFP_P . PS . encodeUtf8) arbitraryFilePath
    shrink (QFilePathAFP_P x) = shrinkValid (QFilePathAFP_P . PS . encodeUtf8) id (decodeUtf8 . unPFP $ x)

newtype QFilePathsAFP_W = QFilePathsAFP_W [WindowsFilePath] deriving Show
newtype QFilePathsAFP_P = QFilePathsAFP_P [PosixFilePath] deriving Show

instance Arbitrary QFilePathsAFP_W where
    arbitrary = fmap (QFilePathsAFP_W . fmap (WS . encodeUtf16LE)) (listOf arbitraryFilePath)

instance Arbitrary QFilePathsAFP_P where
    arbitrary = fmap (QFilePathsAFP_P . fmap (PS . encodeUtf8)) (listOf arbitraryFilePath)

instance Arbitrary WindowsChar where
  arbitrary = WW <$> arbitrary

instance Arbitrary PosixChar where
  arbitrary = PW <$> arbitrary
#endif
