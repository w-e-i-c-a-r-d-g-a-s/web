const fs = require('fs');
const _ = require('lodash');
const etherSetting = require('./etherSetting.json');
const { cardMasterAddress } = etherSetting;
const helper = require('./guard/helper');

const { web3 } = helper;

// signatureはkey-valueの形式にする
require.extensions['.signatures'] = (module, filename) => {
  const data = fs.readFileSync(filename, 'utf8');
  const kv = _.fromPairs(data.split('\n')
    .filter((f) => f) //空文字を除去
    .map((d) => d.replace(' ', '').split(':'))
  );
  module.exports = kv;
};

// コントラクトメタデータの取得
const cardMasterSol = require('./contracts/build/contracts/CardMaster.json');
const cardSol = require('./contracts/build/contracts/Card.json');
const bidInfoSol = require('./contracts/build/contracts/BidInfo.json');
const cardMasterContract = web3.eth.contract(cardMasterSol.abi);
const cardContract = web3.eth.contract(cardSol.abi);
const bidInfoContract = web3.eth.contract(bidInfoSol.abi);

const cardMasterSIG = require('./contracts/build/signatures/CardMaster.signatures');
const cardSIG = require('./contracts/build/signatures/Card.signatures');

const cardMasterInstance = cardMasterContract.at(cardMasterAddress);

// ブロックをずらす数
const backwordNum = 0;

// トランザクション登録
const putTransaction = (tx) => {
  const receipt = web3.eth.getTransactionReceipt(tx.hash);
  // console.log('---------------------------------------------------');
  // console.log(tx);
  // console.log(receipt);
  // console.log('---------------------------------------------------');
  const { timestamp } = web3.eth.getBlock(tx.blockNumber);
  const { gas, gasPrice, hash, value, transactionIndex } = tx;
  const { gasUsed } = receipt;

  helper.getStructLogs(tx.hash).then((structLogs) => {
    let isSuccess = false
    if (structLogs.length > 0) {
      const lastStatement = structLogs[structLogs.length - 1];
      // 成功かどうか
      isSuccess = lastStatement.error === null && lastStatement.op === 'STOP';
      if(!isSuccess){ console.error(lastStatement); }
    }
    // カードかカーマスターかの判定
    if(cardMasterAddress.toLowerCase() === tx.to.toLowerCase()){
      const txData = {
        gas,
        gasPrice: gasPrice.toNumber(),
        gasUsed,
        value: value.toNumber(),
        inputRaw: tx.input,
        inputMethod: helper.getMethod(tx.input, cardMasterSIG),
        inputArgs: helper.getArguments(tx.input, cardMasterSIG),
        timestamp,
        // データを時系列昇順で並べられるようにする
        sortKey: Number.MAX_SAFE_INTEGER - (timestamp + transactionIndex),
        isSuccess
      };

      // カードのログデータを作成
      // カードのアドレスがlogsにあるがこれでいいのか・・・？？
      const logData = receipt.logs[0].data;
      const cardAddress = `0x${logData.slice(26)}`;
      console.log('Card Master Transaction => ', cardAddress);

      // 成功していた場合のみ関連するカードに設定
      if(isSuccess){
        helper.firebase.putCardActivities(tx.to, hash, txData);
      }

      // ユーザに登録
      const card = cardContract.at(cardAddress);
      // カードの所有者を導出
      const owners = card.getOwnerList().filter((address) => {
        return +card.balanceOf(address).toString(10) > 0;
      });

      helper.firebase.putAccountActivities(owners, hash, txData);
      // 履歴データに書き込み
      helper.firebase.putTransactionRecord(hash, txData);
      return;
    }

    // TODO ここに書くとちょっと重いかもしれない。。
    const cardAddresses = cardMasterInstance.getCardAddresses();

    if (cardAddresses.indexOf(tx.to.toLowerCase()) >= 0) {
      const inputMethod = helper.getMethod(tx.input, cardSIG);
      console.log('Card Transaction => ', inputMethod);
      // 売り注文の取り消しは無視する
      if(inputMethod === 'closeAsk'){
        return;
      }
      const logData = receipt.logs[0];
      if(logData){
        const logs = logData.data.slice(2).match(/.{1,64}/g);
        const transactionCount = web3.toDecimal(`0x${logs[0]}`);
        const marketPrice = web3.toDecimal(`0x${logs[1]}`);
        const diff = web3.toDecimal(`0x${logs[2]}`);
        const isNegative = web3.toDecimal(`0x${logs[3]}`) === 1;
        console.log(transactionCount, marketPrice, diff, isNegative);
        helper.firebase.putCardPrice(tx.to, transactionCount, marketPrice, diff, isNegative);
        if(/^(acceptAsk|acceptBid)$/.test(inputMethod)){
          helper.firebase.putCardTrades(tx.to, new Date().getTime(), marketPrice);
        }
      }
      const txData = {
        gas,
        gasPrice: gasPrice.toNumber(),
        gasUsed,
        value: value.toNumber(),
        inputRaw: tx.input,
        inputMethod,
        inputArgs: helper.getArguments(tx.input, cardSIG),
        timestamp,
        sortKey: Number.MAX_SAFE_INTEGER - (timestamp + transactionIndex),
        isSuccess
      };
      // 関連するユーザ
      // tx.toを1枚入以上所有しているユーザ
      const card = cardContract.at(tx.to);
      // カードの所有者を導出
      const owners = card.getOwnerList().filter((address) => {
        return +card.balanceOf(address).toString(10) > 0;
      });

      // from が含まれていない場合
      if (owners.indexOf(tx.from) === -1) {
        owners.push(tx.from);
      }

      helper.firebase.putAccountActivities(owners, hash, txData);

      // 成功していた場合のみ関連するカードに設定
      if(isSuccess){
        helper.firebase.putCardActivities(tx.to, hash, txData);
      }
      // 履歴データに書き込み
      helper.firebase.putTransactionRecord(hash, txData);
      return;
    }
  });
};

/*
Transaction({
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

Transaction({
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

const filter = web3.eth.filter('latest');

filter.watch((error) => {
  if (error) {
    console.log(error);
    return;
  }

  // 確定したブロックを参照するため、ある程度遡ったブロックを参照
  const confirmedBlock = web3.eth.getBlock(web3.eth.blockNumber - backwordNum);

  if(confirmedBlock.transactions.length > 0){
    // console.log("block =>", confirmedBlock.hash, confirmedBlock.transactions.length);
    confirmedBlock.transactions.forEach((txId) => {
      const tx = web3.eth.getTransaction(txId);
      // console.log('putTransaction', tx.hash);
      putTransaction(tx);
    })
  }
});
console.log('watch start');
