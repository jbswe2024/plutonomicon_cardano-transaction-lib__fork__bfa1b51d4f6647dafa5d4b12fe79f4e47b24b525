/* global BROWSER_RUNTIME */

let lib;
if (typeof BROWSER_RUNTIME != "undefined" && BROWSER_RUNTIME) {
  lib = require("@emurgo/cardano-serialization-lib-browser");
} else {
  lib = require("@emurgo/cardano-serialization-lib-nodejs");
}
lib = require("@mlabs-haskell/csl-gc-wrapper")(lib);

const call = property => object => object[property]();
const callMaybe = property => maybe => object => {
  const res = object[property]();
  return res != null ? maybe.just(res) : maybe.nothing;
};

// Classes like TransactionInputs are just monomorphic containers with `len`
// and `get()` methods. This function abstracts away converting them to Array
// of something.
const containerExtractor = obj => {
  const res = [];

  for (let i = 0; i < obj.len(); i++) {
    res.push(obj.get(i));
  }

  return res;
};

// Dictionary wrappers share the same interface (with functions keys() and
// get(k)).
const extractDict = tuple => dict => {
  const keys = containerExtractor(dict.keys());
  const res = [];
  for (let key of keys) {
    // We assume that something that is in keys() is always present in the
    // structure as well.
    res.push(tuple(key)(dict.get(key)));
  }
  return res;
};

export var getInput = call("input");
export var getOutput = call("output");
export var getTransactionHash = call("transaction_id");
export var getTransactionIndex = call("index");
export var getAddress = call("address");
export var getPlutusData = callMaybe("plutus_data");
export var getScriptRef = callMaybe("script_ref");

export function withScriptRef(ccNativeScript) {
  return ccPlutusScript => scriptRef => {
    if (scriptRef.is_native_script()) {
      return ccNativeScript(scriptRef.native_script());
    } else if (scriptRef.is_plutus_script()) {
      return ccPlutusScript(scriptRef.plutus_script());
    } else {
      throw "Impossible happened: withScriptRef: not a script";
    }
  };
}

export var getAmount = call("amount");
export var getCoin = call("coin");
export var getMultiAsset = callMaybe("multiasset");
export {extractDict as extractMultiAsset};
export {extractDict as extractAssets};
export var getDataHash = callMaybe("data_hash");

export function mkTransactionUnspentOutput(input) {
  return output =>
    lib.TransactionUnspentOutput.new(input, output);
}
