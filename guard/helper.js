const admin = require("firebase-admin");
const Web3 = require('web3');
const serviceAccount = require("../serviceAccountKey.json");
const etherSetting = require('../etherSetting.json');
const { firebaseURL, rpcEndpointLocal } = etherSetting;
let web3;
if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(rpcEndpointLocal));
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: firebaseURL || "https://td-demo-5c73d.firebaseio.com"
});

const database = admin.database();

// firebaseのdoc名
const FB_DOC = {
  TRANSACTIONS: 'transactions',
  CARD_ACTIVITIES: 'cardActivities',
  CARD_PRICE: 'cardPrice',
  ACCOUNT_ACTIVITIES: 'accountActivities',
  LATEST_CARD_TRADES: 'latestCardTrades'
};

// メソッド名を返す
module.exports = {
  web3,
  getMethod: (input, signatures) => {
    const method = input.slice(0, 10);
    return signatures[method.slice(2)].replace(/\(.+\)/, '');
  },

  /**
   * 引数を解析
   * @param {string} input
   * @param {object} signatures contractのsignature
   */
  getArguments: (input, signatures) => {
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
  },

  /**
   * トランザクションのログを変更
   * @param {string} txHash トランザクションアドレス
   * @returns {Promise}
   */
  getStructLogs: (txHash) => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.sendAsync({
        method: "debug_traceTransaction",
        params: [txHash, {}],
        jsonrpc: "2.0",
        id: "2"
      }, (err, res) => {
        if(err){
          reject(new Error(e.message));
        }
        resolve(res.result.structLogs);
      });
    });
  },

  firebase: {
    putTransactionRecord: (hash, data) => {
      database.ref()
        .child(`${FB_DOC.TRANSACTIONS}/${hash}`)
        .set(data).then(() => {
          console.log(`put ${FB_DOC.TRANSACTIONS}`);
        }).catch((e) => {
          console.log(e);
        });
    },

    putCardActivities: (cardAddress, txHash, txData) => {
      database.ref(`${FB_DOC.CARD_ACTIVITIES}/${cardAddress}/txs/${txHash}`).set(txData);
    },

    putCardTrades: (cardAddress, time, marketPrice) => {
      database.ref(`${FB_DOC.LATEST_CARD_TRADES}/${cardAddress}`).set({
        time, marketPrice
      });
    },

    putCardPrice: (cardAddress, transactionCount, marketPrice, diff, isNegative) => {
      database.ref(`${FB_DOC.CARD_PRICE}/${cardAddress}/${transactionCount}`).set({
        transactionCount, marketPrice, diff, isNegative
      });
    },

    /**
     * アカウントアクティビティを追加
     *
     * @param {Array} owners オーナーのアドレス
     * @param {string} txHash ハッシュ
     * @param {object} txData トランザクションデータ
     */
    putAccountActivities: (owners, txHash, txData) => {
      const accRef = database.ref().child(FB_DOC.ACCOUNT_ACTIVITIES);
      const payload = {};
      owners.forEach((addr) => {
        payload[`${addr}/txs/${txHash}`] = txData;
      });
      accRef.update(payload);
    }


  }
};

