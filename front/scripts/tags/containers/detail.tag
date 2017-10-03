detail
  .container.page.page-detail
    .columns
      .column.col-3.col-xs-12.col-sm-12.col-md-12.col-lg-4.col-xl-3
        .columns
          .column.col-12.col-xs-12.col-sm-6.col-md-5.col-lg-12.col-xl-12.my-2
            card(card="{card}" single="{true}" )
            button.btn.btn-primary.btn-block.mt-2 最安値で購入する
          .column.col-12.col-xs-12.col-sm-6.col-md-7.col-lg-12.col-xl-12
            card-prices(card="{card}")
            card-tags(card="{card}")
            // card-owners(card="{card}")

      .column.col-9.col-xs-12.col-sm-12.col-md-12.col-lg-8.col-xl-9
        card-ask(
          ether-jpy="{etherJPY}"
          accept-ask="{acceptAsk}"
          ask="{ask}"
          ask-info="{card.askInfo}"
          cancel-ask="{cancelAsk}"
          ask-id="{askId}"
          number-of-card="{numberOfCard}"
        )
        card-ask-form(
          number-of-card="{numberOfCard}"
          ether-jpy="{etherJPY}"
          ask="{ask}"
        )
        card-bid(
          ether-jpy="{etherJPY}"
          bid-info="{card.bidInfo}"
          accept-bid="{acceptBid}"
          cancel-bid="{cancelBid}"
        )
        card-bid-form(
          bid="{bid}"
          ether-jpy="{etherJPY}"
          change-bid-quantity="{changeBidQuantity}"
          quantity-error="{quantityError}"
          quantity-error-msg="{quantityErrorMsg}"
          total-supply="{card.totalSupply}"
        )
        // card-deal(deal="{deal}" total-supply="{card.totalSupply}" number-of-card="{numberOfCard}")
        card-activity(card-address="{opts.cardAddress}" activities="{activities}")
    password-modal(
      unlock="{unlock}"
      show="{showPasswordModal}"
      deferred="{deferred}"
      obs="{opts.obs}"
    )

  script.
    import Deferred from 'es6-deferred';
    import { assign, throttle } from 'lodash';
    this.card = {
      bidInfo: [],
      askInfo: []
    };
    this.activities = [];
    this.cardActivityRef = null;
    this.showPasswordModal = false;
    // 自身の保有枚数
    this.numberOfCard = 0;

    opts.obs.on('updateEthPrice', (({ etherJPY }) => {
      this.etherJPY = etherJPY;
      this.update();
    }));

    this.on('mount', async () => {
      const { cardAddress } = this.opts;
      this.cardActivityRef = this.firebase.getCardTransactions(cardAddress);

      this.card = this.web3c.getCard(cardAddress);
      const cardData = await this.firebase.getCard(this.card.imageHash);
      this.card.imageUrl = cardData.url;
      this.card.tags = cardData.tags;

      // 自身の保有枚数導出
      const owned = this.card.owners.find((own) => {
        return own.address === this.user.etherAccount
      })
      this.numberOfCard = owned ? owned.num : 0;
      this.update();
      const setUpdateData = throttle(this.setUpdateData, 1000, {
        trailing: false,
        leading: true
      });

      // カード履歴
      this.cardActivityRef.on('child_added', (ss, prevChildKey) => {
        const v = ss.val();
        v.key = ss.key;
        // Transactionデータを取得
        v.receipt = this.web3c.web3.eth.getTransactionReceipt(v.key);
        v.card = this.web3c.getCard(v.receipt.to);
        v.text = this.createActivitiesText(v);
        v.isDeal = this.isDeal(v.inputMethod);
        // 初回にまとめて取ってくるとき以外は prevChildKeyがnullになる
        if(prevChildKey){
          // 前のデータがあるときは後ろに
          this.activities.push(v);
        }else{
          // 前のデータがないときは先頭に
          this.activities.unshift(v);
        }
        this.update();
        // オーナ情報、ask, bidを付け直す
        setUpdateData();
      });
    });

    this.on('unmount', () => {
      this.cardActivityRef.off('child_added');
    });

    /**
     * カードの更新データを取得
     */
    setUpdateData(){
      const newCardData = this.web3c.getCard(this.opts.cardAddress);
      this.card.bidInfo = newCardData.bidInfo;
      this.card.askInfo = newCardData.askInfo;
      this.card.currentMarketPrice = newCardData.currentMarketPrice;
      this.card.owners = newCardData.owners;
      this.update();
    }

    /**
     * 売り注文(ask)を発行
     *
     * @param {number} quantity 数量
     * @param {number} wei 一枚あたりの価格(wei)
     * @returns {Promise}
     */
    ask(quantity, wei){
      const gas = 135603;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        // パスワード入力
        try {
          await this.inputUnlock();
          try {
            const tx = this.web3c.ask(quantity, wei, address, etherAccount, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
            resolve();
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject('err transaction faild');
          }
        } catch (e) {
          // キャンセル
          reject('canceled');
        }
      });
    }

    requestAsk(){

    }

    /**
     * 選択した売り注文を購入
     * @param {number} price 選択した売り注文の金額(wei)
     * @param {number} quantity 数量
     * @returns {Promise}
     */
    acceptAsk(price, quantity){
      const gas = 208055;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          await this.inputUnlock();
          try {
            const tx = this.web3c.acceptAsk(etherAccount, address, price, quantity, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject('err transaction faild');
          }
        } catch (e) {
          // キャンセル
          reject('canceled');
        }
      });
    }

    /**
     * 売り注文を取り消し
     * @param {number} askId 売り注文のリスト番号（画面上のindex）
     * @returns {Promise}
     */
    cancelAsk(askId){
      const selectedAsk = this.card.askInfo[askId];
      const gas = 1523823;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try{
          await this.inputUnlock();
          try{
            const tx = this.web3c.cancelAsk(etherAccount, address, selectedAsk.id, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
            this.card.askInfo.splice(askId, 1);
            resolve();
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject('err transaction faild');
          }
        }catch(e){
          reject('canceled');
        }
      });
    }

    /**
     * 買い注文(bid)を発行
     * @param {number} quantity 数量
     * @param {number} wei 1枚あたりの価格(wei)
     * @returns {Promise}
     */
    bid(quantity, wei){
      const gas = 500000;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          await this.inputUnlock();
          try{
            const tx = this.web3c.bid(etherAccount, address, quantity, wei, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
            resolve();
          }catch(e){
            console.log(e);
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject();
          }
        }catch(e){
          reject();
        }
      });
    }

    /**
     * 買い注文に対して売却
     * @param {number} price 金額(wei)
     * @param {number} quantity 数量
     * @returns {Promise}
     */
    acceptBid(price, quantity){
      const gas = 1523823;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try{
          await this.inputUnlock();
          try{
            const tx = this.web3c.acceptBid(
              etherAccount, address, price, quantity, gas
            );
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject('err transaction faild');
          }
        }catch(e){
          reject();
        }
      });
    }

    /**
     * 買い注文を取り消し
     *
     * @param {number} bidId 買い注文のリスト番号（画面上のindex）
     * @returns {Promise}
     */
    cancelBid(bidId){
      const selectedBid = this.card.bidInfo[bidId];
      const gas = 1523823;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try{
          await this.inputUnlock();
          try{
            const tx = this.web3c.cancelBid(etherAccount, address, selectedBid.id, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
            this.card.bidInfo.splice(bidId, 1);
            resolve();
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject('err transaction faild');
          }
        }catch(e){
          reject();
        }
      });
    }

    /**
     * パスワード入力モーダルを表示
     * @returns {Promise}
     */
    inputUnlock(){
      return new Promise(async (resolve, reject) => {
        // アンロックダイアログを表示
        const res = await this.unlockAccount();
        if(res){
          // アンロック処理後
          console.log('unlocked!');
          this.showPasswordModal = false;
          this.update();
          resolve();
        }else{
          this.showPasswordModal = false;
          this.update();
          reject(Error('err'));
        }
      });
    }

    unlockAccount(){
      // モーダルを表示し、処理を待つ
      this.deferred = new Deferred();
      this.showPasswordModal = true;
      this.update();
      return this.deferred.promise;
    }

    /**
     * カードを配布
     * @param {number} quantity 数量
     * @param {string} receiver 受信者のアドレス
     */
    deal(quantity, receiver){
      const gas = 200000;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          await this.inputUnlock();
          try{
            const tx = this.web3c.deal(etherAccount, address, quantity, receiver, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
            resolve();
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject();
          }
        }catch(e){
          reject();
        }
      });
    }

    /**
     * アクティビティのテキスト生成
     * @param {object} activityData アクティビティのデータ
     */
    createActivitiesText(activityData){
      const { inputMethod, inputArgs, receipt, card } = activityData;
      const { from } = receipt;

      // カード発行
      if(inputMethod === 'addCard'){
        return `カードが ${inputArgs[1]}枚 発行されました`
      }
      // 売り注文を発行
      if(inputMethod === 'ask'){
        const eth = this.web3c.weiToEth(inputArgs[1]);
        return `${eth}ETH で ${inputArgs[0]}枚 の売り注文を作成されました`
      }
      // 売り注文から買う
      if(inputMethod === 'acceptAsk'){
        const [ wei, num ] = inputArgs;
        const _price = this.web3c.weiToEth(wei);
        return `${_price}ETH で ${num}枚 販売されました`
      }
      // 買い注文から買う
      if(inputMethod === 'bid'){
        return `${inputArgs[1]}ETH で ${inputArgs[0]}枚 の買い注文が作成されました`
      }
      // 買い注文から売る
      if(inputMethod === 'acceptBid'){
        const index = inputArgs[0];
        const buyOrder = this.web3c.getBidInfo(card.address, index);
        const price = this.web3c.weiToEth(buyOrder.price().toNumber());
        return `${price}ETH で ${inputArgs[1]}枚 売却されました`
      }
      // 送付
      if(inputMethod === 'deal'){
        return `${inputArgs[1]}枚 配布しました`
      }

      return `${inputMethod} しました`
    }

    /**
     * 取引かどうか
     * @param {string} inputMethod 処理名
     * @returns {boolean} 取引の場合true
     */
    isDeal(inputMethod){
      return /^(acceptBid|acceptAsk|deal)$/.test(inputMethod);
    }
