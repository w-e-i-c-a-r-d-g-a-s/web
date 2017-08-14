const fs = require('fs');
const _ = require('lodash');
const Web3 = require('web3')
const admin = require("firebase-admin");
const etherSetting = require('./etherSetting.json');
const serviceAccount = require("./serviceAccountKey.json");
const { adminAddress, cardMasterAddress, rpcEndpointLocal } = etherSetting;

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

const backwordNum = 0;

let web3;
if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(rpcEndpointLocal));
}

const CardMasterABI = JSON.parse(require('./sol/dist/CardMaster.abi'));
const CardMasterSIG = require('./sol/dist/CardMaster.signatures');

const CardMasterAddress = cardMasterAddress;
const CardMasterContract = web3.eth.contract(CardMasterABI);
const CardMasterInstance = CardMasterContract.at(CardMasterAddress);

const CardABI = JSON.parse(require('./sol/dist/Card.abi'));
const CardSIG = require('./sol/dist/Card.signatures');

const CardContract = web3.eth.contract(CardABI);
// const BuyOrderContract = web3.eth.contract(BuyOrderABI);


// メソッド名を返す
const getMethod = (input, signatures) => {
  const method = input.slice(0, 10);
  return signatures[method.slice(2)].replace(/\(.+\)/, '');
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
      return web3.toAscii('0x'+a).replace(/\u0000/g, '');
    }
  });
  console.log(argsData);
  return argsData;
};


const setTransactionRecord = (hash, data) => {
  const documentName = 'transactions';
  const newHistoryKey = database.ref().child(`${documentName}/${hash}`)
    .set(data).then(() => {
      console.log('put history');
    }).catch((e) => {
      console.log(e);
    });
};

// トランザクション登録
const setTransaction = (tx) => {
  const receipt = web3.eth.getTransactionReceipt(tx.hash);
  const { timestamp } = web3.eth.getBlock(tx.blockNumber);
  const { gas, gasPrice, hash, value, transactionIndex } = tx;
  const { gasUsed } = receipt;


  // カードかカーマスターかの判定
  if(cardMasterAddress === tx.to){
    const txData = {
      gas,
      gasPrice: gasPrice.toNumber(),
      gasUsed,
      value: value.toNumber(),
      inputRaw: tx.input,
      inputMethod: getMethod(tx.input, CardMasterSIG),
      inputArgs: getArguments(tx.input, CardMasterSIG),
      timestamp,
      // データを時系列昇順で並べられるようにする
      sortKey: Number.MAX_SAFE_INTEGER - (timestamp + transactionIndex)
    };
    console.log('カードマスタに関する実行');

    // カードのログデータを作成
    // カードのアドレスがlogsにあるがこれでいいのか・・・？？
    const logData = receipt.logs[0].data;
    const cardAddress = `0x${logData.slice(26)}`;
    // カードにtxを追加
    const caRef = database.ref(`cardAccounts/${cardAddress}/txs/${hash}`)
    caRef.set(txData);
    // ユーザに登録
    const card = CardContract.at(cardAddress);
    // カードの所有者を導出
    const owners = card.getOwnerList().filter((address) => {
      return +card.owns(address).toString(10) > 0;
    });
    const accRef = database.ref().child('accounts');
    const payload = {};
    owners.forEach((addr) => {
      payload[`${addr}/txs/${hash}`] = txData;
    });
    accRef.update(payload);
    // 履歴データに書き込み
    setTransactionRecord(hash, txData);
    return;
  }

  // TODO ここに書くとちょっと重いかもしれない。。
  const cardAddresses = CardMasterInstance.getCardAddressList();

  if (cardAddresses.indexOf(tx.to) >= 0) {
    console.log('カードに関する');
    const txData = {
      gas,
      gasPrice: gasPrice.toNumber(),
      gasUsed,
      value: value.toNumber(),
      inputRaw: tx.input,
      inputMethod: getMethod(tx.input, CardSIG),
      inputArgs: getArguments(tx.input, CardSIG),
      timestamp,
      sortKey: Number.MAX_SAFE_INTEGER - (timestamp + transactionIndex)
    };
    // 関連するユーザ
    // tx.toを1枚入以上所有しているユーザ
    const card = CardContract.at(tx.to);
    // カードの所有者を導出
    const owners = card.getOwnerList().filter((address) => {
      return +card.owns(address).toString(10) > 0;
    });
    // console.log(owners);

    const accRef = database.ref().child('accounts');
    const payload = {};
    owners.forEach((addr) => {
      payload[`${addr}/txs/${hash}`] = txData;
    });
    accRef.update(payload);

    // 関連するカードに設定
    const caRef = database.ref(`cardAccounts/${tx.to}/txs/${hash}`)
    caRef.set(txData);
    // 履歴データに書き込み
    setTransactionRecord(hash, txData);
    return;
  }

};

/*
setTransaction({
  blockHash: '0xb51471f27c760c9c363503883e589d63cd87cbde6fe848740aedb1356f6aac58',
  blockNumber: 32199,
  from: '0x0f6fc65c0a544ecd6f9d31894c8e9e193c3b7fd4',
  gas: 200000,
  gasPrice:  web3.toBigNumber(18000000000),
  hash: '0x8d3838d7f582fcb622bf2c857dd290138086dbf0dbed0a345d3c12baff1d6c32',
  input: '0xcd61a95a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000de0b6b3a7640000',
  nonce: 36,
  to: '0x7410c7d6a3e8ae7b5788335b82cfb97ed73ef561',
  transactionIndex: 0,
  value: web3.toBigNumber(0)
});

setTransaction({
  blockHash: '0x71510047fff611f0ba4e740a4f29a9c817e09a10c34d48793188bc76a2c8cd91',
  blockNumber: 32200,
  from: '0x0f6fc65c0a544ecd6f9d31894c8e9e193c3b7fd4',
  gas: 1599659,
  gasPrice:  web3.toBigNumber(18000000000),
  hash: '0x83b48babc68ead2673a02e09b004d928ae45634bfe0d75ff2e1e8808c59f1ff6',
  input: '0x1dc6ad0b4c424f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000703562393430616438323539313366643539663963333434343465643335643337',
  to: '0xb3c975dfbf25486c39975ee98736c4d81d37d092',
  transactionIndex: 0,
  value: web3.toBigNumber(0)
});
*/

let filter = web3.eth.filter('latest')
filter.watch(function(error) {
  if (error) {
    console.log(error);
    return;
  }

  // 確定したブロックを参照するため、ある程度遡ったブロックを参照
  const confirmedBlock = web3.eth.getBlock(web3.eth.blockNumber - backwordNum);
  console.log("block =>", confirmedBlock.hash, confirmedBlock.transactions.length);
  confirmedBlock.transactions.forEach(function(txId) {
    const tx = web3.eth.getTransaction(txId);
    setTransaction(tx);
  })
});
console.log('watch start');
