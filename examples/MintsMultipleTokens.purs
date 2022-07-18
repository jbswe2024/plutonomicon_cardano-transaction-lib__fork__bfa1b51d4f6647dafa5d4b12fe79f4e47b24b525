-- | This module demonstrates how the `Contract` interface can be used to build,
-- | balance, and submit a smart-contract transaction. It creates a transaction
-- | that mints a value using three minting policies with different redeemers.
module Examples.MintsMultipleTokens (main) where

import Contract.Prelude

import Contract.Aeson (decodeAeson, fromString)
import Contract.Monad
  ( Contract
  , launchAff_
  , liftContractAffM
  , liftContractM
  , liftedE
  , liftedM
  , logInfo'
  , runContract_
  , traceTestnetContractConfig
  )
import Contract.PlutusData (PlutusData(Integer), Redeemer(Redeemer))
import Contract.Prim.ByteArray (byteArrayFromAscii)
import Contract.ScriptLookups as Lookups
import Contract.Scripts (MintingPolicy)
import Contract.Transaction (balanceAndSignTx, submit, plutusV1Script)
import Contract.TxConstraints as Constraints
import Contract.Value (CurrencySymbol, TokenName)
import Contract.Value as Value
import Data.BigInt (fromInt) as BigInt

main :: Effect Unit
main = launchAff_ $ do
  cfg <- traceTestnetContractConfig
  runContract_ cfg $ do
    logInfo' "Running Examples.MintsMultipleTokens"
    tn1 <- mkTokenName "Token with a long name"
    tn2 <- mkTokenName "Token"
    mp1 /\ cs1 <- mkCurrencySymbol mintingPolicyRdmrInt1
    mp2 /\ cs2 <- mkCurrencySymbol mintingPolicyRdmrInt2
    mp3 /\ cs3 <- mkCurrencySymbol mintingPolicyRdmrInt3

    let
      constraints :: Constraints.TxConstraints Void Void
      constraints = mconcat
        [ Constraints.mustMintValueWithRedeemer
            (Redeemer $ Integer (BigInt.fromInt 1))
            (Value.singleton cs1 tn1 one <> Value.singleton cs1 tn2 one)
        , Constraints.mustMintValueWithRedeemer
            (Redeemer $ Integer (BigInt.fromInt 2))
            (Value.singleton cs2 tn1 one <> Value.singleton cs2 tn2 one)
        , Constraints.mustMintValueWithRedeemer
            (Redeemer $ Integer (BigInt.fromInt 3))
            (Value.singleton cs3 tn1 one <> Value.singleton cs3 tn2 one)
        ]

      lookups :: Lookups.ScriptLookups Void
      lookups =
        Lookups.mintingPolicy mp1
          <> Lookups.mintingPolicy mp2
          <> Lookups.mintingPolicy mp3

    ubTx <- liftedE $ Lookups.mkUnbalancedTx lookups constraints
    bsTx <-
      liftedM "Failed to balance/sign tx" $ balanceAndSignTx ubTx
    txId <- submit bsTx
    logInfo' $ "Tx ID: " <> show txId

mkTokenName :: forall (r :: Row Type). String -> Contract r TokenName
mkTokenName =
  liftContractM "Cannot make token name"
    <<< (Value.mkTokenName <=< byteArrayFromAscii)

mkCurrencySymbol
  :: forall (r :: Row Type)
   . Maybe MintingPolicy
  -> Contract r (MintingPolicy /\ CurrencySymbol)
mkCurrencySymbol mintingPolicy = do
  mp <- liftContractM "Invalid script JSON" mintingPolicy
  cs <- liftContractAffM "Cannot get cs" $ Value.scriptCurrencySymbol mp
  pure (mp /\ cs)

mintingPolicyRdmrInt1 :: Maybe MintingPolicy
mintingPolicyRdmrInt1 = map (wrap <<< plutusV1Script) $ hush $ decodeAeson $
  fromString
    "5909960100003232323322332233322232323332223232323233322233322233333333222222\
    \2233223333322222333322223322332233223332223322332233223322332232323232323232\
    \323232323232323232323232323232323232335001011223304849010e77726f6e6720726564\
    \65656d657200333504b04a00233504904f4800848888c014cc00cc010008c01800494cd4c124\
    \00441484d4060d4c144cd5ce2481025064000524988c8c8c8c8c8c8cccd5cd19b8735573aa00\
    \a90001280112803a4c26603ca002a0042600c6ae8540084c050d5d09aba25001135573ca0022\
    \6ea80084d405d262323232323232323232323232323232323232323232323333573466e1cd55\
    \cea80aa40004a0044a02e9309999999999817a800a8012801a8022802a8032803a8042804a80\
    \5099a81080b1aba15012133502001635742a0202666aa032eb94060d5d0a8070999aa80c3ae5\
    \01735742a018266a03a0426ae8540284cd4070cd54078085d69aba15008133501675a6ae8540\
    \184cd4069d71aba150041335019335501b75c0346ae8540084c080d5d09aba25001135744a00\
    \226ae8940044d5d1280089aba25001135744a00226ae8940044d5d1280089aba25001135573c\
    \a00226ea80084d40592623232323232323333573466e1cd55cea802a40004a0044a00e930998\
    \102800a8010980b9aba1500213005357426ae8940044d55cf280089baa0021350154988c8c8c\
    \8c8c8c8c8c8cccd5cd19b8735573aa00e90001280112804a4c2666046a002a004a006260106a\
    \e8540104ccd54029d728049aba15002133500775c6ae84d5d1280089aba25001135573ca0022\
    \6ea80084d40512623232323232323333573466e1cd55cea802a40004a0044a00e93099811280\
    \0a8010980a1aba150021335005012357426ae8940044d55cf280089baa002135013498488c8c\
    \8c8c8c8c8cccd5cd19b87500448000940089401126135025500113006357426aae79400c4ccc\
    \d5cd19b875001480089408c9401126135573aa00226ea80084d404d261335500175ceb444888\
    \c8c8c004dd58019a80090008918009aa82811191919191919191999aab9f0085505125300212\
    \001056350022200135001220023555505712223300321300a357440124266a0a8a00aa600624\
    \002266aa0a8a002a004260106aae7540084c018d55cf280089aba10011223232323232323333\
    \573466e1cd55cea802a40004a0044a00e93099a8122800a801099a8038031aba150021335007\
    \005357426ae8940044d55cf280089baa002135010498488c8c8c8c8c8c8cccd5cd19b8735573\
    \aa00a90001280112803a4c266a04ea002a004266a01000c6ae8540084c020d5d09aba2500113\
    \5573ca00226ea80084d403d261223232323232323333573466e1cd55cea802a40004a0044a00\
    \e93099a8122800a801099a8038031aba1500213007357426ae8940044d55cf280089baa00213\
    \500e498488c8c8c8c8c8c8c8cccd5cd19b87500548010940a8940092613333573466e1d40112\
    \00225002250044984d40a540044c018d5d09aab9e500313333573466e1d40052000250272500\
    \44984d55cea80089baa00213500d4988c8c8c8cccd5cd19b8750024800881089400926133335\
    \73466e1d400520002040250034984d55ce9baa00213500b498488c8c8c004dd60019a8009000\
    \8918009aa824911999aab9f00125047233504630063574200460066ae88008120800444888c8\
    \c8c8c8c8c8cccd5cd19b8735573aa00a90001280112803a4c266aa096a002a0042600e6ae854\
    \0084c014d5d09aba25001135573ca00226ea80084d4029262323232323232323232323232323\
    \23333573466e1d4029200625002250044984c0c140044c038d5d09aab9e500b13333573466e1\
    \d401d200425002250044984c0ad40044c030d5d09aab9e500813333573466e1d401120022500\
    \2250044984c09d40044c02cd5d09aab9e500513333573466e1d4005200025003250064984d55\
    \cea80189812a80089bae357426aae7940044dd500109a803a4c4646464646464646464646464\
    \646464646464646464646464646666ae68cdc3a80aa401840844a0049309999ab9a3370ea028\
    \900510211280124c26666ae68cdc3a809a40104a0044a00c9309981e2800a80109bae35742a0\
    \0426eb4d5d09aba25001135573ca02426666ae68cdc3a8072400c4a0044a00c9309981c2800a\
    \80109bae35742a00426eb8d5d09aba25001135573ca01a26666ae68cdc3a804a40084a0044a0\
    \0c9309981ba800a801098069aba150021375c6ae84d5d1280089aab9e500813333573466e1d4\
    \011200225002250044984c0cd40044c020d5d09aab9e500513333573466e1d40052000250032\
    \50064984d55cea80189816a800898021aba135573ca00226ea80084d40192623232323232323\
    \232323232323333573466e1d4021200225002250084984ccc0e140054009400c4dd69aba1500\
    \41375a6ae8540084dd69aba135744a00226ae8940044d55cf280289999ab9a3370ea00290001\
    \28019280324c26aae75400c4c0c540044c010d5d09aab9e50011375400426a00a93119191919\
    \191919191999ab9a3370ea0089001128011280224c2606ca00226eb8d5d09aab9e5005133335\
    \73466e1d4005200025003250064984d55cea80189819a80089bae357426aae7940044dd50010\
    \9a80224c46464646464646666ae68cdc39aab9d500548000940089401d261330265001500213\
    \00635742a00426eb4d5d09aba25001135573ca00226ea80084d400d2623232323333573466e1\
    \cd55cea801240004a0044a0089309bae357426aae7940044dd500109a80124c24c4424660020\
    \060044002444444444424666666666600201601401201000e00c00a008006004400244246600\
    \2006004400244424666002008006004400244246600200600440022424460040062244002240\
    \0224424660020060042400224424660020060042400224424660020060042400224244460060\
    \08224440042244400224002424444600800a424444600600a424444600400a424444600200a4\
    \0024424660020060044002424444444600e01044244444446600c012010424444444600a0102\
    \4444444008244444440064424444444660040120104424444444660020120104002424460040\
    \0644424466600200a00800640024244600400642446002006400244a66a600c0022010266ae7\
    \000801c4800488ccd5cd19baf00200100600512001122002122001200123750002224a008224\
    \4004244244660020080062400224002400222442466002006004224002224646002002446600\
    \660040040022222466a0044246600246a00644600400646a0064460020060022464646002002\
    \4466006600400400244246a6008246a60080066a0060020021"

mintingPolicyRdmrInt2 :: Maybe MintingPolicy
mintingPolicyRdmrInt2 = map (wrap <<< plutusV1Script) $ hush $ decodeAeson $
  fromString
    "5909960100003232323322332233322232323332223232323233322233322233333333222222\
    \2233223333322222333322223322332233223332223322332233223322332232323232323232\
    \323232323232323232323232323232323232335001011223304849010e77726f6e6720726564\
    \65656d657200333504b04a00233504904f4801048888c014cc00cc010008c01800494cd4c124\
    \00441484d4060d4c144cd5ce2481025064000524988c8c8c8c8c8c8cccd5cd19b8735573aa00\
    \a90001280112803a4c26603ca002a0042600c6ae8540084c050d5d09aba25001135573ca0022\
    \6ea80084d405d262323232323232323232323232323232323232323232323333573466e1cd55\
    \cea80aa40004a0044a02e9309999999999817a800a8012801a8022802a8032803a8042804a80\
    \5099a81080b1aba15012133502001635742a0202666aa032eb94060d5d0a8070999aa80c3ae5\
    \01735742a018266a03a0426ae8540284cd4070cd54078085d69aba15008133501675a6ae8540\
    \184cd4069d71aba150041335019335501b75c0346ae8540084c080d5d09aba25001135744a00\
    \226ae8940044d5d1280089aba25001135744a00226ae8940044d5d1280089aba25001135573c\
    \a00226ea80084d40592623232323232323333573466e1cd55cea802a40004a0044a00e930998\
    \102800a8010980b9aba1500213005357426ae8940044d55cf280089baa0021350154988c8c8c\
    \8c8c8c8c8c8cccd5cd19b8735573aa00e90001280112804a4c2666046a002a004a006260106a\
    \e8540104ccd54029d728049aba15002133500775c6ae84d5d1280089aba25001135573ca0022\
    \6ea80084d40512623232323232323333573466e1cd55cea802a40004a0044a00e93099811280\
    \0a8010980a1aba150021335005012357426ae8940044d55cf280089baa002135013498488c8c\
    \8c8c8c8c8cccd5cd19b87500448000940089401126135025500113006357426aae79400c4ccc\
    \d5cd19b875001480089408c9401126135573aa00226ea80084d404d261335500175ceb444888\
    \c8c8c004dd58019a80090008918009aa82811191919191919191999aab9f0085505125300212\
    \001056350022200135001220023555505712223300321300a357440124266a0a8a00aa600624\
    \002266aa0a8a002a004260106aae7540084c018d55cf280089aba10011223232323232323333\
    \573466e1cd55cea802a40004a0044a00e93099a8122800a801099a8038031aba150021335007\
    \005357426ae8940044d55cf280089baa002135010498488c8c8c8c8c8c8cccd5cd19b8735573\
    \aa00a90001280112803a4c266a04ea002a004266a01000c6ae8540084c020d5d09aba2500113\
    \5573ca00226ea80084d403d261223232323232323333573466e1cd55cea802a40004a0044a00\
    \e93099a8122800a801099a8038031aba1500213007357426ae8940044d55cf280089baa00213\
    \500e498488c8c8c8c8c8c8c8cccd5cd19b87500548010940a8940092613333573466e1d40112\
    \00225002250044984d40a540044c018d5d09aab9e500313333573466e1d40052000250272500\
    \44984d55cea80089baa00213500d4988c8c8c8cccd5cd19b8750024800881089400926133335\
    \73466e1d400520002040250034984d55ce9baa00213500b498488c8c8c004dd60019a8009000\
    \8918009aa824911999aab9f00125047233504630063574200460066ae88008120800444888c8\
    \c8c8c8c8c8cccd5cd19b8735573aa00a90001280112803a4c266aa096a002a0042600e6ae854\
    \0084c014d5d09aba25001135573ca00226ea80084d4029262323232323232323232323232323\
    \23333573466e1d4029200625002250044984c0c140044c038d5d09aab9e500b13333573466e1\
    \d401d200425002250044984c0ad40044c030d5d09aab9e500813333573466e1d401120022500\
    \2250044984c09d40044c02cd5d09aab9e500513333573466e1d4005200025003250064984d55\
    \cea80189812a80089bae357426aae7940044dd500109a803a4c4646464646464646464646464\
    \646464646464646464646464646666ae68cdc3a80aa401840844a0049309999ab9a3370ea028\
    \900510211280124c26666ae68cdc3a809a40104a0044a00c9309981e2800a80109bae35742a0\
    \0426eb4d5d09aba25001135573ca02426666ae68cdc3a8072400c4a0044a00c9309981c2800a\
    \80109bae35742a00426eb8d5d09aba25001135573ca01a26666ae68cdc3a804a40084a0044a0\
    \0c9309981ba800a801098069aba150021375c6ae84d5d1280089aab9e500813333573466e1d4\
    \011200225002250044984c0cd40044c020d5d09aab9e500513333573466e1d40052000250032\
    \50064984d55cea80189816a800898021aba135573ca00226ea80084d40192623232323232323\
    \232323232323333573466e1d4021200225002250084984ccc0e140054009400c4dd69aba1500\
    \41375a6ae8540084dd69aba135744a00226ae8940044d55cf280289999ab9a3370ea00290001\
    \28019280324c26aae75400c4c0c540044c010d5d09aab9e50011375400426a00a93119191919\
    \191919191999ab9a3370ea0089001128011280224c2606ca00226eb8d5d09aab9e5005133335\
    \73466e1d4005200025003250064984d55cea80189819a80089bae357426aae7940044dd50010\
    \9a80224c46464646464646666ae68cdc39aab9d500548000940089401d261330265001500213\
    \00635742a00426eb4d5d09aba25001135573ca00226ea80084d400d2623232323333573466e1\
    \cd55cea801240004a0044a0089309bae357426aae7940044dd500109a80124c24c4424660020\
    \060044002444444444424666666666600201601401201000e00c00a008006004400244246600\
    \2006004400244424666002008006004400244246600200600440022424460040062244002240\
    \0224424660020060042400224424660020060042400224424660020060042400224244460060\
    \08224440042244400224002424444600800a424444600600a424444600400a424444600200a4\
    \0024424660020060044002424444444600e01044244444446600c012010424444444600a0102\
    \4444444008244444440064424444444660040120104424444444660020120104002424460040\
    \0644424466600200a00800640024244600400642446002006400244a66a600c0022010266ae7\
    \000801c4800488ccd5cd19baf00200100600512001122002122001200123750002224a008224\
    \4004244244660020080062400224002400222442466002006004224002224646002002446600\
    \660040040022222466a0044246600246a00644600400646a0064460020060022464646002002\
    \4466006600400400244246a6008246a60080066a0060020021"

mintingPolicyRdmrInt3 :: Maybe MintingPolicy
mintingPolicyRdmrInt3 = map (wrap <<< plutusV1Script) $ hush $ decodeAeson $
  fromString
    "5909960100003232323322332233322232323332223232323233322233322233333333222222\
    \2233223333322222333322223322332233223332223322332233223322332232323232323232\
    \323232323232323232323232323232323232335001011223304849010e77726f6e6720726564\
    \65656d657200333504b04a00233504904f4801848888c014cc00cc010008c01800494cd4c124\
    \00441484d4060d4c144cd5ce2481025064000524988c8c8c8c8c8c8cccd5cd19b8735573aa00\
    \a90001280112803a4c26603ca002a0042600c6ae8540084c050d5d09aba25001135573ca0022\
    \6ea80084d405d262323232323232323232323232323232323232323232323333573466e1cd55\
    \cea80aa40004a0044a02e9309999999999817a800a8012801a8022802a8032803a8042804a80\
    \5099a81080b1aba15012133502001635742a0202666aa032eb94060d5d0a8070999aa80c3ae5\
    \01735742a018266a03a0426ae8540284cd4070cd54078085d69aba15008133501675a6ae8540\
    \184cd4069d71aba150041335019335501b75c0346ae8540084c080d5d09aba25001135744a00\
    \226ae8940044d5d1280089aba25001135744a00226ae8940044d5d1280089aba25001135573c\
    \a00226ea80084d40592623232323232323333573466e1cd55cea802a40004a0044a00e930998\
    \102800a8010980b9aba1500213005357426ae8940044d55cf280089baa0021350154988c8c8c\
    \8c8c8c8c8c8cccd5cd19b8735573aa00e90001280112804a4c2666046a002a004a006260106a\
    \e8540104ccd54029d728049aba15002133500775c6ae84d5d1280089aba25001135573ca0022\
    \6ea80084d40512623232323232323333573466e1cd55cea802a40004a0044a00e93099811280\
    \0a8010980a1aba150021335005012357426ae8940044d55cf280089baa002135013498488c8c\
    \8c8c8c8c8cccd5cd19b87500448000940089401126135025500113006357426aae79400c4ccc\
    \d5cd19b875001480089408c9401126135573aa00226ea80084d404d261335500175ceb444888\
    \c8c8c004dd58019a80090008918009aa82811191919191919191999aab9f0085505125300212\
    \001056350022200135001220023555505712223300321300a357440124266a0a8a00aa600624\
    \002266aa0a8a002a004260106aae7540084c018d55cf280089aba10011223232323232323333\
    \573466e1cd55cea802a40004a0044a00e93099a8122800a801099a8038031aba150021335007\
    \005357426ae8940044d55cf280089baa002135010498488c8c8c8c8c8c8cccd5cd19b8735573\
    \aa00a90001280112803a4c266a04ea002a004266a01000c6ae8540084c020d5d09aba2500113\
    \5573ca00226ea80084d403d261223232323232323333573466e1cd55cea802a40004a0044a00\
    \e93099a8122800a801099a8038031aba1500213007357426ae8940044d55cf280089baa00213\
    \500e498488c8c8c8c8c8c8c8cccd5cd19b87500548010940a8940092613333573466e1d40112\
    \00225002250044984d40a540044c018d5d09aab9e500313333573466e1d40052000250272500\
    \44984d55cea80089baa00213500d4988c8c8c8cccd5cd19b8750024800881089400926133335\
    \73466e1d400520002040250034984d55ce9baa00213500b498488c8c8c004dd60019a8009000\
    \8918009aa824911999aab9f00125047233504630063574200460066ae88008120800444888c8\
    \c8c8c8c8c8cccd5cd19b8735573aa00a90001280112803a4c266aa096a002a0042600e6ae854\
    \0084c014d5d09aba25001135573ca00226ea80084d4029262323232323232323232323232323\
    \23333573466e1d4029200625002250044984c0c140044c038d5d09aab9e500b13333573466e1\
    \d401d200425002250044984c0ad40044c030d5d09aab9e500813333573466e1d401120022500\
    \2250044984c09d40044c02cd5d09aab9e500513333573466e1d4005200025003250064984d55\
    \cea80189812a80089bae357426aae7940044dd500109a803a4c4646464646464646464646464\
    \646464646464646464646464646666ae68cdc3a80aa401840844a0049309999ab9a3370ea028\
    \900510211280124c26666ae68cdc3a809a40104a0044a00c9309981e2800a80109bae35742a0\
    \0426eb4d5d09aba25001135573ca02426666ae68cdc3a8072400c4a0044a00c9309981c2800a\
    \80109bae35742a00426eb8d5d09aba25001135573ca01a26666ae68cdc3a804a40084a0044a0\
    \0c9309981ba800a801098069aba150021375c6ae84d5d1280089aab9e500813333573466e1d4\
    \011200225002250044984c0cd40044c020d5d09aab9e500513333573466e1d40052000250032\
    \50064984d55cea80189816a800898021aba135573ca00226ea80084d40192623232323232323\
    \232323232323333573466e1d4021200225002250084984ccc0e140054009400c4dd69aba1500\
    \41375a6ae8540084dd69aba135744a00226ae8940044d55cf280289999ab9a3370ea00290001\
    \28019280324c26aae75400c4c0c540044c010d5d09aab9e50011375400426a00a93119191919\
    \191919191999ab9a3370ea0089001128011280224c2606ca00226eb8d5d09aab9e5005133335\
    \73466e1d4005200025003250064984d55cea80189819a80089bae357426aae7940044dd50010\
    \9a80224c46464646464646666ae68cdc39aab9d500548000940089401d261330265001500213\
    \00635742a00426eb4d5d09aba25001135573ca00226ea80084d400d2623232323333573466e1\
    \cd55cea801240004a0044a0089309bae357426aae7940044dd500109a80124c24c4424660020\
    \060044002444444444424666666666600201601401201000e00c00a008006004400244246600\
    \2006004400244424666002008006004400244246600200600440022424460040062244002240\
    \0224424660020060042400224424660020060042400224424660020060042400224244460060\
    \08224440042244400224002424444600800a424444600600a424444600400a424444600200a4\
    \0024424660020060044002424444444600e01044244444446600c012010424444444600a0102\
    \4444444008244444440064424444444660040120104424444444660020120104002424460040\
    \0644424466600200a00800640024244600400642446002006400244a66a600c0022010266ae7\
    \000801c4800488ccd5cd19baf00200100600512001122002122001200123750002224a008224\
    \4004244244660020080062400224002400222442466002006004224002224646002002446600\
    \660040040022222466a0044246600246a00644600400646a0064460020060022464646002002\
    \4466006600400400244246a6008246a60080066a0060020021"
