/* global BROWSER_RUNTIME */

let lib;
if (typeof BROWSER_RUNTIME != "undefined" && BROWSER_RUNTIME) {
  lib = require("@emurgo/cardano-serialization-lib-browser");
} else {
  lib = require("@emurgo/cardano-serialization-lib-nodejs");
}
lib = require("@mlabs-haskell/csl-gc-wrapper")(lib);

const setter = prop => obj => value => () => obj["set_" + prop](value);

export function newAuxiliaryData() {
  return lib.AuxiliaryData.new();
}

export function _hashAuxiliaryData(auxiliaryData) {
  return lib.hash_auxiliary_data(auxiliaryData);
}

export var setAuxiliaryDataNativeScripts = setter("native_scripts");
export var setAuxiliaryDataPlutusScripts = setter("plutus_scripts");
export var setAuxiliaryDataGeneralTransactionMetadata = setter("metadata");

export function newGeneralTransactionMetadata(containerHelper) {
  return entries => () =>
    containerHelper.packMap(lib.GeneralTransactionMetadata, entries);
}

export function newMetadataMap(containerHelper) {
  return entries => () =>
    lib.TransactionMetadatum.new_map(
      containerHelper.packMap(lib.MetadataMap, entries)
    );
}

export function newMetadataList(containerHelper) {
  return entries => () =>
    lib.TransactionMetadatum.new_list(
      containerHelper.pack(lib.MetadataList, entries)
    );
}

export function newMetadataInt(int) {
  return () => lib.TransactionMetadatum.new_int(int);
}

export function newMetadataBytes(bytes) {
  return () =>
    lib.TransactionMetadatum.new_bytes(bytes);
}

export function newMetadataText(text) {
  return () => lib.TransactionMetadatum.new_text(text);
}
