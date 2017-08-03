const fs = require('fs');
const _ = require('lodash');
const Web3 = require('web3')
const admin = require("firebase-admin");
const etherSetting = require('./etherSetting.json');
const serviceAccount = require("./serviceAccountKey.json");
const { adminAddress, cardMasterAddress, rpcEndpoint } = etherSetting;

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: etherSetting.firebaseURL || "https://td-demo-5c73d.firebaseio.com"
});
const database = admin.database();

// abi,binファイルをテキストとしてrequire
require.extensions['.abi'] = require.extensions['.bin'] = (module, filename) => {
  module.exports = fs.readFileSync(filename, 'utf8');
};

// signatureはkey-valueの形式にする
require.extensions['.signatures'] = (module, filename) => {
  const data = fs.readFileSync(filename, 'utf8');
  const kv = _.fromPairs(data.split('\n')
    .filter((f) => f) //空文字を除去
    .map((d) => d.replace(' ', '').split(':'))
  );
  module.exports = kv;
};

const url = 'http://localhost:8545';
const backwordNum = 11;

let web3;
if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(url));
}

const CardMasterABI = JSON.parse(require('./sol/dist/CardMaster.abi'));
const CardMasterBIN = `0x${require('./sol/dist/CardMaster.bin')}`;
const CardMasterSIG = require('./sol/dist/CardMaster.signatures');

const CardMasterAddress = cardMasterAddress;
const CardMasterContract = web3.eth.contract(CardMasterABI);
const CardMasterInstance = CardMasterContract.at(CardMasterAddress);

const CardABI = JSON.parse(require('./sol/dist/Card.abi'));
const CardBIN = `0x${require('./sol/dist/Card.bin')}`;
const CardSIG = require('./sol/dist/Card.signatures');

let cardAddresses = CardMasterInstance.getCardAddressList();

// メソッド定義を返す
const getMethod = (input, signatures) => {
  const method = input.slice(0, 10);
  return signatures[method.slice(2)];
};

// 引数解析
const getArguments = (input, signatures) => {
  const method = input.slice(0, 10);
  const methodDef = signatures[method.slice(2)];
  // 引数の型を取得
  const argsText = methodDef.match(/\((.+)\)/);
  const argsDefs = argsText[1].split(',');
  if(!argsText){
    return null;
  }

  const args = input.slice(10).match(/.{1,64}/g);
  const argsData = args.map((a, i) => {
    if(argsDefs[i] === 'address'){
      // addressの場合40文字の値がそのままアドレスとなる
      return '0x'+a.slice(24);
    }

    // 数値の場合
    if(argsDefs[i].indexOf('uint') === 0){
      return web3.toDecimal('0x'+a);
    }

    // 文字列の場合
    if(argsDefs[i].indexOf('bytes32') === 0){
      return web3.toAscii('0x'+a).replace(/\u0000/g, '') ;;
    }
  });
  console.log(argsData);
  return argsData;
};

// カード発行
const putHistory = (tx, receipt, signatures, documentName) => {
  const { blockHash, blockNumber, gas, gasPrice, hash, to, from, value } = tx;
  const { gasUsed } = receipt;

  const newHistoryKey = database.ref().child(documentName).push().set({
    blockHash,
    blockNumber,
    gas,
    gasPrice: gasPrice.toNumber(),
    gasUsed,
    hash,
    to,
    from,
    value: value.toNumber(),
    inputRaw: tx.input,
    inputMethod: getMethod(tx.input, signatures),
    inputArgs: getArguments(tx.input, signatures)
  }).then((data) => {
    console.log('put history');
  }).catch((e) => {
    console.log(e);
  });
};

let filter = web3.eth.filter('latest')
filter.watch(function(error) {
  if (error) {
    return;
  }

  // 確定したブロックを参照するため、ある程度遡ったブロックを参照
  const confirmedBlock = web3.eth.getBlock(web3.eth.blockNumber - backwordNum);

  confirmedBlock.transactions.forEach(function(txId) {
    let tx = web3.eth.getTransaction(txId)

    // カード発行などカードマスターに関するtx
    if(cardMasterAddress === tx.to){
      const receipt = web3.eth.getTransactionReceipt(tx.hash);
      // カードアドレスをアップデート
      cardAddresses = CardMasterInstance.getCardAddressList();
      console.log('カード発行');
      console.log(tx);
      console.log('---------------------------------');
      console.log(receipt);
      putHistory(tx, receipt, CardMasterSIG, 'histories');
    }

    // カード売買などカードに関するtx
    if (cardAddresses.indexOf(tx.to) >= 0) {
      const receipt = web3.eth.getTransactionReceipt(tx.hash);
      console.log('カード売買');
      console.log(tx);
      console.log('---------------------------------');
      console.log(receipt);
      putHistory(tx, receipt, CardSIG, 'notifies');
    }

  })
})
