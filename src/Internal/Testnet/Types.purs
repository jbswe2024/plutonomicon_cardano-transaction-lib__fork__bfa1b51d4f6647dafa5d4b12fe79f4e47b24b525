module Internal.Testnet.Types
  ( CardanoTestnetStartupParams
  , Era (..)
  , LoggingFormat (..)
  , OptionalStartupParams
  , defaultOptionalStartupParams
  , defaultStartupParams
  ) where


import Contract.Prelude
import Data.Time.Duration (Milliseconds, Seconds)
import Record as Record

data Era
  = Byron
  | Shelley
  | Allegra
  | Mary
  | Alonzo
  | Babbage

instance Show Era where
  show = case _ of
    Byron -> "byron_era"
    Shelley -> "shelley_era"
    Allegra -> "allegra_era"
    Mary -> "mary_era"
    Alonzo -> "alonzo_era"
    Babbage -> "babbage_era"

data LoggingFormat = LogAsJson | LogAsText
instance Show LoggingFormat where
  show = case _ of
    LogAsJson -> "json" 
    LogAsText -> "text"

type OptionalStartupParams =
  ( numPoolNodes :: Maybe Int
  , era :: Maybe Era
  , epochLength :: Maybe Milliseconds
  , slotLength :: Maybe Seconds
  , activeSlotsCoeff :: Maybe Number
  , enableP2p :: Maybe Boolean
  , nodeLoggingFormat :: Maybe LoggingFormat
  )

-- | Command line params for the cardano-testnet executable
type CardanoTestnetStartupParams =
  { testnetMagic :: Int
  | OptionalStartupParams
  }

defaultStartupParams :: {testnetMagic :: Int} -> CardanoTestnetStartupParams
defaultStartupParams necessaryParams =
  defaultOptionalStartupParams `Record.union` necessaryParams

defaultOptionalStartupParams :: Record OptionalStartupParams 
defaultOptionalStartupParams =
  { numPoolNodes: Nothing
  , era: Nothing
  , epochLength: Nothing
  , slotLength: Nothing
  , activeSlotsCoeff: Nothing
  , enableP2p: Nothing
  , nodeLoggingFormat: Nothing
  }