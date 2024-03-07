module Ctl.Internal.Types.MintingPolicy
  ( MintingPolicy(PlutusMintingPolicy, NativeMintingPolicy)
  , hash
  ) where

import Prelude

import Aeson (class DecodeAeson, class EncodeAeson, encodeAeson)
import Cardano.Plutus.Types.MintingPolicyHash (MintingPolicyHash)
import Cardano.Types.NativeScript (NativeScript)
import Cardano.Types.NativeScript as NativeScript
import Cardano.Types.PlutusScript (PlutusScript)
import Cardano.Types.PlutusScript as PlutusScript
import Control.Alt ((<|>))
import Ctl.Internal.Helpers (decodeTaggedNewtype)
import Data.Generic.Rep (class Generic)
import Data.Newtype (wrap)
import Data.Show.Generic (genericShow)

-- | `MintingPolicy` is a sum type of `PlutusScript` and `NativeScript` which are used as
-- | validators for minting constraints.
data MintingPolicy
  = PlutusMintingPolicy PlutusScript
  | NativeMintingPolicy NativeScript

derive instance Generic MintingPolicy _
derive instance Eq MintingPolicy

instance DecodeAeson MintingPolicy where
  decodeAeson aes =
    decodeTaggedNewtype "getPlutusMintingPolicy" PlutusMintingPolicy aes <|>
      decodeTaggedNewtype "getNativeMintingPolicy" NativeMintingPolicy aes

instance EncodeAeson MintingPolicy where
  encodeAeson (NativeMintingPolicy nscript) =
    encodeAeson { "getNativeMintingPolicy": nscript }
  encodeAeson (PlutusMintingPolicy script) =
    encodeAeson { "getPlutusMintingPolicy": script }

instance Show MintingPolicy where
  show = genericShow

hash :: MintingPolicy -> MintingPolicyHash
hash (PlutusMintingPolicy ps) = wrap $ PlutusScript.hash ps
hash (NativeMintingPolicy ns) = wrap $ NativeScript.hash ns
