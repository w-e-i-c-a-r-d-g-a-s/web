import Web3 from 'web3';
import _ from 'lodash';
import ethers from 'ethers';
import request from 'superagent';
import { adminAddress, cardMasterAddress, rpcEndpoint } from '../../../etherSetting.json';

let web3;
if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  web3 = new Web3(new Web3.providers.HttpProvider(rpcEndpoint));
}

import cardMasterSol from '../../../contracts/build/contracts/CardMaster.json';
import cardSol from '../../../contracts/build/contracts/Card.json';
import bidInfoSol from '../../../contracts/build/contracts/BidInfo.json';

// contractなど
const cardMasterContract = web3.eth.contract(cardMasterSol.abi);
const cardContract = web3.eth.contract(cardSol.abi);
const bidInfoContract = web3.eth.contract(bidInfoSol.abi);

const cardMasterInstance = cardMasterContract.at(cardMasterAddress);

/*
var filter = web3.eth.filter('latest');
// watch for changes
filter.watch((error, result) => {
  if (error) {
    console.error(error);
    return;
  }
  // console.log(result);
  const block = web3.eth.getBlock(result, true);
  if(block.transactions.length > 0){
    block.transactions.forEach((tx, i) => {
      var receipt = web3.eth.getTransactionReceipt(tx.hash);
      console.log(tx, receipt);
      // 注 指定したgasとgasUsedがドンピシャだと成功したことになっている
      if(receipt.gasUsed === tx.gas){
        const errorMsg = `Transaction failed (out of gas, thrown) ${receipt.gasUsed}`;
        console.log(errorMsg);
        return;
      }
    });
  }
});
*/

const web3c = {
  web3,
  cardMasterAddress,

  // アンロック
  unlock: async (userName, password, unlockDurationSec = 0) => {
    const jsonData = createJSONdata('personal_unlockAccount',
      [ userName, password, unlockDurationSec ]
    );

    return new Promise((resolve, reject) => {
      executeJsonRpc(jsonData).then((res) => {
        const data = res.body;
        if(data.error){
          reject(new Error(data.error.message));
        } else {
          resolve();
        }
      }, (e) => {
        reject(e);
      });
    });
  },

  // カードマスターを登録
  deployCardMaster() {
    var card_sol_cardmaster = cardMasterContract.new({
      from: adminAddress,
      data: cardMasterSol.unlinked_binary,
      gas: '4700000'
    }, function (e, contract){
      if(e){
        throw new Error(e);
      }
      if (typeof contract.address !== 'undefined') {
        console.log('Contract mined! ⛏ address: ' + contract.address + ' transactionHash: ' + contract.transactionHash);
      }
    })
  },

  // カードを登録
  addCard(from, name, totalSupply, imageHash, gas) {
    return cardMasterInstance.addCard(name, totalSupply, imageHash, { from, gas });
  },

  /**
   * カードを取得
   * @param {string} account 絞り込むユーザアカウント。省略した場合はすべてのカードを返す
   * @returns {array} カードデータのリスト
   */
  getCards(account){
    const cards = cardMasterInstance.getCardAddresses().map((address) => {
      const card = cardContract.at(address);
      return {
        card,
        address,
        name: web3.toAscii(card.name()),
        imageHash: web3.toAscii(card.imageHash()),
        author: card.author(),
        totalSupply: card.totalSupply().toString(10),
        currentMarketPrice: web3.fromWei(card.currentMarketPrice().toNumber(), 'ether')
      }
    });
    return account ? cards.filter((c) => {
      return c.card.getOwnerList().filter((address) => address === account && c.card.balanceOf(address).toNumber() > 0).length > 0;
    }) : cards;
  },

  /**
   * イメージハッシュからカードデータを取得
   * ※ 重いです
   *
   * @param {string} imageHash イメージハッシュの文字列
   * @returns {object} カードデータ
   */
  getCardByImageHash(imageHash){
    const cards = cardMasterInstance.getCardAddresses();
    const hitAddress = _.find(cards, (address) => {
      const card = cardContract.at(address);
      return imageHash === web3.toAscii(card.imageHash());
    });
    const card = cardContract.at(hitAddress);
    return {
      card,
      address: card.address,
      name: web3.toAscii(card.name()),
      imageHash: web3.toAscii(card.imageHash()),
      author: card.author(),
      totalSupply: card.totalSupply().toString(10)
    };
  },

  // カード情報を取得
  getCard(cardAddress){
    const card = cardContract.at(cardAddress);
    const askInfo = this.getAskInfo(card);
    const bidInfo = this.getBidInfo(card);
    const owners = card.getOwnerList().map((address) => {
      return { address, num: card.balanceOf(address).toString(10) };
    });

    return {
      address: card.address,
      name: web3.toAscii(card.name()),
      imageHash: web3.toAscii(card.imageHash()),
      author: card.author(),
      totalSupply: card.totalSupply().toString(10),
      currentMarketPrice: web3.fromWei(card.currentMarketPrice().toNumber(), 'ether'),
      owners,
      askInfo,
      bidInfo
    }
  },

  /**
   * 売り注文(ask)を発行
   * @param {number} quantity 枚数
   * @param {number} price 金額
   * @param {string} cardAddress カードアドレス
   * @param {string} from 実行ユーザアカウント
   * @param {number} gas 送信gas
   */
  ask: (quantity, price, cardAddress, from, gas) => {
    const card = cardContract.at(cardAddress);
    return card.ask(quantity, price, { from, gas });
  },

  /**
   * 売り注文を購入
   * @param {string} from ユーザアカウント
   * @param {string} cardAddress カードアドレス
   * @param {number} price 選択したaskの金額
   * @param {number} quantity 枚数
   * @param {number} gas gas
   */
  acceptAsk: (from, cardAddress, price, quantity, gas) => {
    const card = cardContract.at(cardAddress);
    return card.acceptAsk(price, quantity, { from, gas, value: price * quantity });
  },

  /**
   * 売り注文(ask)をキャンセル
   * @param {string} from 送信者
   * @param {string} cardAddress カードアドレス
   * @param {number} askIndex 買い注文インデックス
   * @param {number} gas gas
   */
  cancelAsk(from, cardAddress, askIndex, gas){
    const card = cardContract.at(cardAddress);
    return card.closeAsk(askIndex, { from, gas });
  },

  refreshAskInfo(cardAddress){
    const card = cardContract.at(cardAddress);
    return this.getAskInfo(card);
  },

  getAskInfo(card){
    const askInfo = [];
    const askInfoPrices = card.getAskInfoPrices();
    for (let i = 0, len = card.getAskInfoPricesCount().toNumber(); i < len; i++) {
      const priceKey = askInfoPrices[i];
      const [from, quantity] = card.readAskInfo(priceKey, 0);
      const price = web3.toDecimal(priceKey);
      const idx = _.findIndex(askInfo, ['price', price]);
      if(idx !== -1){
        askInfo[idx].quantity += quantity.toNumber();
      } else {
        askInfo.push({
          id: i,
          from,
          quantity: quantity.toNumber(),
          price,
          priceEth: web3.fromWei(price, 'ether'),
          totalPrice: quantity.mul(price).toNumber(),
          totalPriceEth: quantity.mul(web3.fromWei(price, 'ether')).toNumber()
        });
      }
    }
    return _.sortBy(askInfo, ['price', 'totalPrice']);
  },

  bid(from, cardAddress, quantity, price, gas){
    const card = cardContract.at(cardAddress);
    const value = quantity * web3.toWei(price, 'ether');
    return card.bid(quantity, price, { from, gas, value });
  },

  /**
   * 買い注文(bid)一覧を取得
   * @param {object} card カードコントラクト
   */
  getBidInfo(card){
    const bidInfos = [];
    for (let i = 0, len = card.getBidInfosCount().toNumber(); i < len; i++) {
      const bidInfo = bidInfoContract.at(card.bidInfos(i));
      if(!bidInfo.ended()){
        bidInfos.push({
          id: i,
          buyer: bidInfo.buyer(),
          totalPrice: bidInfo.value().toNumber(), // トータル wei
          totalPriceEth: web3.fromWei(bidInfo.value(), 'ether').toNumber(),
          quantity: bidInfo.quantity().toNumber(),
          price: bidInfo.price().toNumber(), // 単価 wei
          priceEth:web3.fromWei(bidInfo.price(), 'ether').toNumber()
        });
      }
    }
    return _.orderBy(bidInfos, ['price', 'totalPrice'], ['desc', 'desc']);
  },

  refreshBidInfo(cardAddress){
    const card = cardContract.at(cardAddress);
    return this.getBidInfo(card);
  },

  /**
   * 買い注文(bid)に対して売る
   * @param {string} from 送信者
   * @param {string} cardAddress カードアドレス
   * @param {number} bidIndex 買い注文インデックス
   */
  acceptBid(from, cardAddress, bidIndex, quantity, gas){
    const card = cardContract.at(cardAddress);
    const bidInfo = bidInfoContract.at(card.bidInfos(bidIndex));
    const value = web3.fromWei(bidInfo.price(), 'ether').mul(quantity).toNumber();
    return card.acceptBid(bidIndex, quantity, { from, gas, value });
  },

  /**
   * 買い注文(bid)をキャンセル
   * @param {string} from 送信者
   * @param {string} cardAddress カードアドレス
   * @param {number} bidIndex 買い注文インデックス
   * @param {number} gas gas
   */
  cancelBid(from, cardAddress, bidIndex, gas){
    const card = cardContract.at(cardAddress);
    const bidInfo = bidInfoContract.at(card.bidInfos(bidIndex));
    return bidInfo.close({ from, gas });
  },

  /**
   * 買い注文情報を取得
   * @param {string} cardAddress カードアドレス
   * @param {number} askIndex 買い注文インデックス
   */
  getBid(cardAddress, askIndex){
    const card = cardContract.at(cardAddress);
    return bidInfoContract.at(card.bidInfos(askIndex));
  },

  /**
   * カード送信
   * @param {string} from 送信者
   * @param {string} cardAddress カードアドレス
   * @param {number} quantity 数量
   * @param {string} receiver 受領者
   * @param {number} gas gas
   */
  deal(from, cardAddress, quantity, receiver, gas){
    const card = cardContract.at(cardAddress);
    return card.deal(receiver, quantity, { from, gas });
  },

  /**
   * weiをEthに変換
   * @param {number} wei weiの金額
   * @returns {number} Ethの額
   */
  weiToEth(wei){
    return +web3.fromWei(wei, 'ether');
  }

};

const createJSONdata = (method, params) => ({
  jsonrpc: "2.0",
  id: null,
  method: method,
  params: params
});

const executeJsonRpc = (json) => {
  return request.post(rpcEndpoint)
    .set('Content-Type', 'application/json')
    .send(JSON.stringify(json))
};

export default web3c;
