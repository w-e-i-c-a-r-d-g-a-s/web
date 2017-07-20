import Web3 from 'Web3';
import ethers from 'ethers';
import request from 'superagent';

const url = 'http://localhost:8545';
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
const CardMasterAddress = '0x50bb84493b63b1e68fdb3bf28db05c221e19949e';
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
          // console.log(tx, receipt);
          // 注 指定したgasとgasUsedがドンピシャだと成功したことになっている
          if(receipt.gasUsed === tx.gas){
            const text = `Transaction failed (out of gas, thrown) ${receipt.gasUsed}`;
            cb(text, 'error');
            return;
          }
          const text = `🔨mined! (${i}) => blockNumber: ${tx.blockNumber}, from: ${tx.from}, to: ${tx.to}, value: ${tx.value.toString(10)}, gasUsed: ${receipt.gasUsed}, gas: ${tx.gas}`;
          cb(text, 'success');
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
  deployCardMaster(account) {
    var card_sol_cardmaster = CardMasterContract.new({
      from: account,
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
  addCard(account, name, issued, gas) {
    web3.eth.defaultAccount = account;
    // const tx = CardMasterInstance.addCard(name, issued, { gas: 542564 }) // 初回
    // const tx = CardMasterInstance.addCard(name, issued, { gas: 527564 }) // ２回目
    const tx = CardMasterInstance.addCard(name, issued, { gas }) // ２回目
    console.log(`transaction send! => ${tx}`);
  },

  // カードを取得
  getCards(account){
    const cards = CardMasterInstance.getCardAddressList().map((address) => {
      const card = CardContract.at(address);
      return {
        address,
        name: web3.toAscii(card.name()),
        author: card.author(),
        issued: card.issued().toString(10)
      }
    });
    return account ? cards.filter((c) => c.author === account) : cards;
  },

  // カード情報を取得
  getCard(cardAddress){
    const card = CardContract.at(cardAddress);
    const sellInfo = this.getSellInfo(card);
    const buyOrderInfo = this.getBuyOrderInfo(card);
    const owners = card.getOwnerList().map((address) => {
      return { address, num: card.owns(address).toString(10) };
    });

    return {
      address: card.address,
      name: web3.toAscii(card.name()),
      author: card.author(),
      issued: card.issued().toString(10),
      owners,
      sellInfo,
      buyOrderInfo
    }
  },

  // 売る
  sell: (quantity, price, cardAddress, account, gas) => {
    // console.log('sell', quantity, price, cardAddress, account, {gas});
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    return card.sellOrder(quantity, price, { gas });
  },

  // 買う
  buy: (account, cardAddress, sellInfoId, gas, ether = 0) => {
    console.log(account, cardAddress, sellInfoId, gas, ether);
    // 選択したsellデータ
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    const value = web3.toWei(ether, 'ether');
    return card.buy(sellInfoId, { gas, value });
  },

  refreshSellInfo(cardAddress){
    const card = CardContract.at(cardAddress);
    const sellInfo = this.getSellInfo(card);
    return sellInfo;
  },

  getSellInfo(card){
    const sellInfo = [];
    for (let i = 0, len = card.sellInfosLength().toNumber(); i < len; i++) {
      const [from, quantity, price, active] = card.sellInfos(i);
      if(!active){
        continue;
      }
      sellInfo.push({
        id: i,
        from,
        quantity: quantity.toNumber(),
        price: price.toNumber(),
        priceEth: web3.fromWei(price, 'ether').toNumber(),
        totalPrice: quantity * price,
        totalPriceEth: quantity * web3.fromWei(price, 'ether'),
        active
      });
    }

    console.log(sellInfo);
    return sellInfo;
  },

  buyOrder(account, cardAddress, quantity, price, gas,){
    console.log(account, cardAddress, quantity, gas, price);
    // 選択したsellデータ
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    const value = quantity * web3.toWei(price, 'ether');
    return card.createBuyOrder(quantity, price, { gas, value });
  },

  /**
   * 買い注文を取得
   * @param {object} card
   */
  getBuyOrderInfo(card){
    const buyOrderInfo = [];
    for (let i = 0, len = card.getBuyOrdersCount().toNumber(); i < len; i++) {
      const buyOrder = BuyOrderContract.at(card.buyOrders(i));
      if(!buyOrder.ended()){
        buyOrderInfo.push({
          buyer: buyOrder.buyer(),
          totalPrice: buyOrder.value().toNumber(), // トータル wei
          totalPriceEth: web3.fromWei(buyOrder.value(), 'ether').toNumber(),
          quantity: buyOrder.quantity().toNumber(),
          price: buyOrder.price().toNumber(), // 単価 wei
          priceEth:web3.fromWei(buyOrder.price(), 'ether').toNumber()
        });
      }
    }
    return buyOrderInfo;
  },

  refreshBuyOrderInfo(cardAddress){
    const card = CardContract.at(cardAddress);
    return this.getBuyOrderInfo(card);
  },

  acceptBid(account, cardAddress, bidIndex, quantity, gas){
    web3.eth.defaultAccount = account;
    const card = CardContract.at(cardAddress);
    const buyOrder = BuyOrderContract.at(card.buyOrders(bidIndex));
    const value = quantity * buyOrder.price().toNumber();
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
