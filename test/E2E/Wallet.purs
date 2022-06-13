module Test.E2E.Wallet where

import Control.Promise
import Data.Maybe
import Prelude
import Toppokki
import Mote
import TestM
import Toppokki as Toki
import Effect
import Effect.Aff
import Effect.Class
import Effect.Class.Console
import Foreign
import Test.Spec.Assertions
import Wallet

namiHash :: String
namiHash = "lpfcbjknijpeeillifnkikgncikgfhdo"

namiPath :: String
namiPath = "/home/mike/.config/google-chrome/Default/Extensions/" <> namiHash <> "/3.2.5_1"

chromeArgsWithNami :: Array String
chromeArgsWithNami = [ "--disable-extensions-except=" <> namiPath
                     , "--load-extension=" <> namiPath
                     , "--headless=chrome"
                     ]

launchWithNami :: Aff Browser
launchWithNami = Toki.launch { args : chromeArgsWithNami }

initializeNami :: Browser -> Aff Toki.Page
initializeNami browser = do
  page <- Toki.newPage browser
  outputJs <- liftEffect _outputJsPath
  _ <- flip Toki.unsafeEvaluateStringFunction page $ "document.write(\"<html><head>"
    <> "<script src='"<>jsPage<>"' type='text/javascript'></script>"
    <> "<script src='file:///'"<>outputJs<>" type='text/javascript'></script>"
    <> "</head><body></body></html>\");"
--  _ <- pageWaitForSelector (Selector "window") {} page
  pure page
  where jsPage = "chrome-extension://lpfcbjknijpeeillifnkikgncikgfhdo/injected.bundle.js"

suite :: TestPlanM Unit
suite = group "Nami" $ do
  
  test "Launch headless Chrome with Nami" $ do
    _ <- launchWithNami
    pure unit

  test "Initialize Nami" $ do
    browser <- launchWithNami
    page <- initializeNami browser
    fgn <- unsafeEvaluateStringFunction "window.cardano" page
    typeOf fgn `shouldEqual` "object"
    
  test "getNamiWalletAddress" $ do
    browser <- launchWithNami
    page <- initializeNami browser
    fgn <- unsafeEvaluateStringFunction "window.cardano" page
    typeOf fgn `shouldEqual` "object"    

  test "getAlwaysSucceedsExample" $ do
    browser <- launchWithNami
    page <- initializeNami browser
    fgn <- unsafeEvaluateStringFunction "PS['Examples.AlwaysSucceeds']" page
    typeOf fgn `shouldEqual` "object"
--    wallet <- mkNamiWalletAff
--    pure unit
{-    case wallet of
      Nami wallet' -> do
        address <- wallet'.getWalletAddress wallet'.connection
        address `shouldEqual` Nothing        
      Gero _ -> true `shouldEqual` false
-}

foreign import _outputJsPath :: Effect String
