{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "cardano-transaction-lib"
, dependencies =
  [ "aeson"
  , "aff"
  , "aff-promise"
  , "aff-retry"
  , "affjax"
  , "ansi"
  , "argonaut"
  , "argonaut-codecs"
  , "arrays"
  , "avar"
  , "bifunctors"
  , "bignumber"
  , "bytearrays"
  , "cardano-hd-wallet"
  , "cardano-message-signing"
  , "cardano-plutus-data-schema"
  , "cardano-serialization-lib"
  , "cardano-types"
  , "checked-exceptions"
  , "cip30"
  , "cip30-typesafe"
  , "console"
  , "control"
  , "crypto"
  , "datetime"
  , "debug"
  , "effect"
  , "either"
  , "enums"
  , "exceptions"
  , "foldable-traversable"
  , "foreign"
  , "foreign-object"
  , "formatters"
  , "functions"
  , "heterogeneous"
  , "http-methods"
  , "identity"
  , "integers"
  , "js-bigints"
  , "js-date"
  , "lattice"
  , "lists"
  , "literals"
  , "maybe"
  , "media-types"
  , "monad-logger"
  , "mote"
  , "mote-testplan"
  , "newtype"
  , "noble-secp256k1"
  , "node-buffer"
  , "node-child-process"
  , "node-fs"
  , "node-fs-aff"
  , "node-path"
  , "node-process"
  , "node-readline"
  , "node-streams"
  , "nonempty"
  , "now"
  , "nullable"
  , "numbers"
  , "optparse"
  , "ordered-collections"
  , "orders"
  , "parallel"
  , "partial"
  , "plutus-types"
  , "posix-types"
  , "prelude"
  , "profunctor"
  , "profunctor-lenses"
  , "quickcheck"
  , "quickcheck-combinators"
  , "quickcheck-laws"
  , "random"
  , "rationals"
  , "record"
  , "refs"
  , "safe-coerce"
  , "spec"
  , "spec-quickcheck"
  , "strings"
  , "stringutils"
  , "tailrec"
  , "these"
  , "toppokki"
  , "transformers"
  , "tuples"
  , "typelevel-prelude"
  , "uint"
  , "unfoldable"
  , "unsafe-coerce"
  , "untagged-union"
  , "variant"
  , "web-html"
  , "web-storage"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "examples/**/*.purs", "test/**/*.purs" ]
}
