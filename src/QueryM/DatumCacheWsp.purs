module QueryM.DatumCacheWsp
  ( DatumCacheMethod(..)
  , GetDatumByHashR(..)
  , GetDatumsByHashesR(..)
  , StartFetchBlocksR(..)
  , CancelFetchBlocksR(..)
  , JsonWspRequest
  , JsonWspResponse
  , WspFault(WspFault)
  , faultToString
  , getDatumByHashCall
  , getDatumsByHashesCall
  , startFetchBlocksCall
  , cancelFetchBlocksCall
  ) where

import Prelude

import Aeson
  ( class DecodeAeson
  , Aeson
  , caseAesonArray
  , caseAesonObject
  , decodeAeson
  , getNestedAeson
  , jsonToAeson
  , toStringifiedNumbersJson
  , (.:)
  )
import Control.Alt ((<|>))
import Data.Argonaut
  ( Json
  , JsonDecodeError(..)
  , decodeJson
  , encodeJson
  , jsonNull
  , stringify
  )
import Data.Argonaut.Encode (class EncodeJson)
import Data.Bifunctor (lmap)
import Data.Either (Either(..), either, note)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(Just, Nothing), maybe)
import Data.Newtype (class Newtype, unwrap, wrap)
import Data.Traversable (traverse)
import Data.TraversableWithIndex (forWithIndex)
import Data.Tuple.Nested (type (/\), (/\))
import Effect (Effect)
import QueryM.JsonWsp (JsonWspCall, mkCallType)
import QueryM.Ogmios as Ogmios
import QueryM.UniqueId (ListenerId, uniqueId)
import Serialization.Address (Slot)
import Type.Proxy (Proxy(..))
import Types.ByteArray (byteArrayToHex, hexToByteArray)
import Types.Datum (Datum, DatumHash)
import Types.Transaction (DataHash(DataHash), BlockId)

newtype WspFault = WspFault Json

faultToString :: WspFault -> String
faultToString (WspFault j) = stringify j

type JsonWspRequest (a :: Type) =
  { type :: String
  , version :: String
  , servicename :: String
  , methodname :: String
  , args :: a
  , mirror :: ListenerId
  }

type JsonWspResponse =
  { type :: String
  , version :: String
  , servicename :: String
  , methodname :: String
  , result :: Maybe Aeson
  , fault :: Maybe Aeson
  , reflection :: ListenerId
  }

newtype GetDatumByHashR = GetDatumByHashR (Maybe Datum)

derive instance Newtype GetDatumByHashR _

instance DecodeAeson GetDatumByHashR where
  decodeAeson r = GetDatumByHashR <$>
    let
      datumFound :: Either JsonDecodeError (Maybe Datum)
      datumFound =
        Just <$> (decodeAeson =<< getNestedAeson r [ "DatumFound", "value" ])

      datumNotFound :: Either JsonDecodeError (Maybe Datum)
      datumNotFound =
        Nothing <$ getNestedAeson r [ "DatumNotFound" ]
    in
      datumFound <|> datumNotFound

newtype GetDatumsByHashesR = GetDatumsByHashesR (Map DatumHash Datum)

derive instance Newtype GetDatumsByHashesR _

instance DecodeAeson GetDatumsByHashesR where
  decodeAeson r =
    let
      decodeDatumArray
        :: Aeson -> Either JsonDecodeError (Map DatumHash Datum)
      decodeDatumArray =
        caseAesonArray (Left $ TypeMismatch "expected array")
          $ (map Map.fromFoldable) <<< traverse decodeDatum

      decodeDatum
        :: Aeson -> Either JsonDecodeError (DatumHash /\ Datum)
      decodeDatum = caseAesonObject (Left $ TypeMismatch "expected object")
        $ \o -> (/\) <$> map wrap (o .: "hash") <*>
            (decodeAeson =<< o .: "value")
    in
      map GetDatumsByHashesR <<< decodeDatumArray =<< getNestedAeson
        r
        [ "DatumsFound", "value" ]

data StartFetchBlocksR = StartFetchBlocksR

instance DecodeAeson StartFetchBlocksR where
  decodeAeson r = StartFetchBlocksR <$ decodeDoneFlag [ "StartedBlockFetcher" ]
    r

data CancelFetchBlocksR = CancelFetchBlocksR

instance DecodeAeson CancelFetchBlocksR where
  decodeAeson r = CancelFetchBlocksR <$ decodeDoneFlag
    [ "StoppedBlockFetcher" ]
    r

decodeDoneFlag :: Array String -> Aeson -> Either JsonDecodeError Unit
decodeDoneFlag locator r =
  unlessM ((decodeAeson =<< getNestedAeson r locator))
    $ Left (TypeMismatch "Expected done flag")

-- TODO: delete
data DatumCacheMethod
  = GetDatumByHash
  | GetDatumsByHashes
  | StartFetchBlocks
  | CancelFetchBlocks

derive instance Eq DatumCacheMethod

instance Show DatumCacheMethod where
  show = datumCacheMethodToString

datumCacheMethodToString :: DatumCacheMethod -> String
datumCacheMethodToString = case _ of
  GetDatumByHash -> "GetDatumByHash"
  GetDatumsByHashes -> "GetDatumsByHashes"
  StartFetchBlocks -> "StartFetchBlocks"
  CancelFetchBlocks -> "CancelFetchBlocks"

getDatumByHashCall :: JsonWspCall DatumHash GetDatumByHashR
getDatumByHashCall = mkDatumCacheCallType
  GetDatumByHash
  ({ hash: _ } <<< byteArrayToHex <<< unwrap)

getDatumsByHashesCall :: JsonWspCall (Array DatumHash) GetDatumsByHashesR
getDatumsByHashesCall = mkDatumCacheCallType
  GetDatumsByHashes
  ({ hashes: _ } <<< map (byteArrayToHex <<< unwrap))

startFetchBlocksCall
  :: JsonWspCall { slot :: Slot, id :: BlockId } StartFetchBlocksR
startFetchBlocksCall = mkDatumCacheCallType
  StartFetchBlocks
  ( \({ slot, id }) ->
      { slot
      , id: encodeJson (byteArrayToHex $ unwrap id)
      , datumFilter: { "const": true }
      }
  )

cancelFetchBlocksCall :: JsonWspCall Unit CancelFetchBlocksR
cancelFetchBlocksCall = mkDatumCacheCallType
  CancelFetchBlocks
  (const {})

-- convenience helper
mkDatumCacheCallType
  :: forall (a :: Type) (i :: Type) (o :: Type)
   . EncodeJson (JsonWspRequest a)
  => DatumCacheMethod
  -> (i -> a)
  -> JsonWspCall i o
mkDatumCacheCallType method args = mkCallType
  { "type": "jsonwsp/request"
  , version: "1.0"
  , servicename: "ogmios"
  }
  { methodname: datumCacheMethodToString method, args }
  Proxy
