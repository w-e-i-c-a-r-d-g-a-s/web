import Web3 from 'web3';
import ethers from 'ethers';
import request from 'superagent';
import { adminAddress, cardMasterAddress, rpcEndpoint } from '../../../etherSetting.json';

const url = rpcEndpoint;
let web3;
if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(url));
}

const CardMasterABI = JSON.parse(require('../../../sol/dist/CardMaster.abi'));
const CardMasterBIN = `0x${require('../../../sol/dist/CardMaster.bin')}`;
const CardABI = JSON.parse(require('../../../sol/dist/Card.abi'));
const BuyOrderABI = JSON.parse(require('../../../sol/dist/BuyOrder.abi'));

// 定数
// const CardMasterAddress = '0xf8240cdebce4390211ddc9b775820df562364234';
const CardMasterAddress = cardMasterAddress;
const CardMasterContract = web3.eth.contract(CardMasterABI);
const CardMasterInstance = CardMasterContract.at(CardMasterAddress);

const CardContract = web3.eth.contract(CardABI);
const BuyOrderContract = web3.eth.contract(BuyOrderABI);

var filter = web3.eth.filter('latest');


const web3c = {
  web3,
  watch(cb){
    // watch for changes
    filter.watch(function(error, result){
      if (error) {
        console.alert(error);
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
            cb({ isError: true, errorMsg, receipt, tx, txIndex: i });
            return;
          }
          cb({ isError: false, receipt, tx, txIndex: i });
        });
      }
    });
  },

  // アンロック
  unlock: (userName, password, cb = () => {}, err = () => {}) => {
    const unlockDurationSec = 0; // 0の場合永続的
    const jsonData = createJSONdata('personal_unlockAccount',
      [
        userName,
        password,
        unlockDurationSec
      ]
    );
    executeJsonRpc(url, jsonData, (data) => {
      // Success
      if(data.error == null){
        console.log('account unlocked! 😀', userName);
      } else {
        err(`login error: ${data.error.message}`);
        return;
      }
      cb();
    }, (data) => {
      // fail
      err(`login error`);
    });
  },

  // カードマスターを登録
  deployCardMaster() {
    var card_sol_cardmaster = CardMasterContract.new({
      from: adminAddress,
      data: CardMasterBIN,
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
  addCard(account, name, issued, imageHash, gas) {
    web3.eth.defaultAccount = account;
    return CardMasterInstance.addCard(name, issued, imageHash, { gas });
  },

  /**
   * カードを取得
   * @param {string} account 絞り込むユーザアカウント。省略した場合はすべてのカードを返す
   * @returns {array} カードデータのリスト
   */
  getCards(account){
    const cards = CardMasterInstance.getCardAddressList().map((address) => {
      const card = CardContract.at(address);
      return {
        card,
        address,
        name: web3.toAscii(card.name()),
        imageHash: web3.toAscii(card.imageHash()),
        author: card.author(),
        issued: card.issued().toString(10)
      }
    });
    return account ? cards.filter((c) => {
      return c.card.getOwnerList().filter((address) => address === account && c.card.owns(address).toNumber() > 0).length > 0;
    }) : cards;
  },

  // カード情報を取得
  getCard(cardAddress){
    const card = CardContract.at(cardAddress);
    const bidInfo = this.getBidInfo(card);
    const askInfo = this.getAskInfo(card);
    const owners = card.getOwnerList().map((address) => {
      return { address, num: card.owns(address).toString(10) };
    });

    return {
      address: card.address,
      name: web3.toAscii(card.name()),
      imageHash: web3.toAscii(card.imageHash()),
      author: card.author(),
      issued: card.issued().toString(10),
      owners,
      bidInfo,
      askInfo
    }
  },

  /**
   * 売り注文(bid)を発行
   * @param {枚数} quantity 枚数
   * @param {number} price 金額
   * @param {string} cardAddress カードアドレス
   * @param {string} account 実行ユーザアカウント
   * @param {number} gas 送信gas
   */
  bid: (quantity, price, cardAddress, account, gas) => {
    // console.log('sell', quantity, price, cardAddress, account, {gas});
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    return card.sellOrder(quantity, price, { gas });
  },

  /**
   * 売り注文を購入
   *
   * @param {string} account ユーザアカウント
   * @param {string} cardAddress カードアドレス
   * @param {number} bidId 選択したbidのid
   * @param {number} gas gas
   * @param {number} ether=0 総価格(eth)
   */
  acceptBid: (account, cardAddress, bidId, gas, ether = 0) => {
    console.log(account, cardAddress, bidId, gas, ether);
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    const value = web3.toWei(ether, 'ether');
    return card.buy(bidId, { gas, value });
  },

  refreshBidInfo(cardAddress){
    const card = CardContract.at(cardAddress);
    return this.getBidInfo(card);
  },

  getBidInfo(card){
    const bidInfo = [];
    for (let i = 0, len = card.sellInfosLength().toNumber(); i < len; i++) {
      const [from, quantity, price, active] = card.sellInfos(i);
      if(!active){
        continue;
      }
      bidInfo.push({
        id: i,
        from,
        quantity: quantity.toNumber(),
        price: price.toNumber(),
        priceEth: web3.fromWei(price, 'ether').toNumber(),
        totalPrice: quantity.mul(price).toNumber(),
        totalPriceEth: quantity.mul(web3.fromWei(price, 'ether')).toNumber(),
        active
      });
    }

    return bidInfo;
  },

  ask(account, cardAddress, quantity, price, gas,){
    // console.log(account, cardAddress, quantity, gas, price);
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    const value = quantity * web3.toWei(price, 'ether');
    return card.createBuyOrder(quantity, price, { gas, value });
  },

  /**
   * 買い注文(Ask)一覧を取得
   * @param {object} card カードコントラクト
   */
  getAskInfo(card){
    const askInfo = [];
    // console.log(card.getBuyOrdersCount().toNumber());
    for (let i = 0, len = card.getBuyOrdersCount().toNumber(); i < len; i++) {
      const buyOrder = BuyOrderContract.at(card.buyOrders(i));
      if(!buyOrder.ended()){
        askInfo.push({
          id: i,
          buyer: buyOrder.buyer(),
          totalPrice: buyOrder.value().toNumber(), // トータル wei
          totalPriceEth: web3.fromWei(buyOrder.value(), 'ether').toNumber(),
          quantity: buyOrder.quantity().toNumber(),
          price: buyOrder.price().toNumber(), // 単価 wei
          priceEth:web3.fromWei(buyOrder.price(), 'ether').toNumber()
        });
      }
    }
    return askInfo;
  },

  refreshAskInfo(cardAddress){
    const card = CardContract.at(cardAddress);
    return this.getAskInfo(card);
  },

  acceptAsk(account, cardAddress, bidIndex, quantity, gas){
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    const buyOrder = BuyOrderContract.at(card.buyOrders(bidIndex));
    const value = web3.fromWei(buyOrder.price(), 'ether').mul(quantity).toNumber();
    // console.log(bidIndex, quantity, { gas, value });
    return card.sell(bidIndex, quantity, { gas, value });
  }

};

const createJSONdata = (method, params) => ({
  jsonrpc: "2.0",
  id: null,
  method: method,
  params: params
});

const executeJsonRpc = (url, json, s, er) => {
  request.post(url)
    .set('Content-Type', 'application/json')
    .send(JSON.stringify(json))
    .then((res) => {
      s(res.body);
    }, (e) => {
      console.log(e);
      er(e);
    });
};

export default web3c;
