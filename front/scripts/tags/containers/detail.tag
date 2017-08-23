detail
  .container.page.page-detail
    .columns
      .column.col-3.col-xs-12.col-sm-12.col-md-12.col-lg-4.col-xl-3
        .columns
          .column.col-12.col-xs-12.col-sm-6.col-md-5.col-lg-12.col-xl-12.my-2
            card(card="{card}" single="{true}")
          .column.col-12.col-xs-12.col-sm-6.col-md-7.col-lg-12.col-xl-12
            card-prices(card="{card}")
            card-tags(card="{card}")
            card-owners(card="{card}")

      .column.col-9.col-xs-12.col-sm-12.col-md-12.col-lg-8.col-xl-9
        card-activity(card-address="{opts.cardAddress}")
        card-bid(
          bid="{bid}"
          refresh-bid-info="{refreshBidInfo}"
          bid-info="{card.bidInfo}"
          select-bid="{selectBid}"
          bid-id="{bidId}"
          accept-bid="{acceptBid}"
          cancel-bid="{cancelBid}"
          total-supply="{card.totalSupply}"
        )
        card-ask(
          accept-ask="{acceptAsk}"
          ask="{ask}"
          refresh-ask-info="{refreshAskInfo}"
          ask-info="{card.askInfo}"
          select-ask="{selectAsk}"
          cancel-ask="{cancelAsk}"
          ask-id="{askId}"
          number-of-card="{numberOfCard}"
        )
        card-deal(
          deal="{deal}"
          total-supply="{card.totalSupply}"
          number-of-card="{numberOfCard}"
        )
    password-modal(
      unlock="{unlock}"
      show="{showPasswordModal}"
      deferred="{deferred}"
      obs="{opts.obs}"
    )
  script.
    import Deferred from 'es6-deferred';
    import { assign } from 'lodash';
    this.bidId = null;
    this.askId = null;
    this.card = {
      bidInfo: [],
      askInfo: []
    };

    this.showPasswordModal = false;
    // 自身の保有枚数
    this.numberOfCard = 0;

    this.on('mount', async () => {
      this.card = this.web3c.getCard(this.opts.cardAddress);
      const cardData = await this.firebase.getCard(this.card.imageHash);
      this.card.imageUrl = cardData.url;
      this.card.tags = cardData.tags;

      // 自身の保有枚数導出
      const owned = this.card.owners.find((own) => {
        return own.address === this.user.etherAccount
      })
      this.numberOfCard = owned ? owned.num : 0;
      this.update();
    });

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

    /**
     * 選択した売り注文を購入
     * @param {number} quantity 数量
     * @param {number} wei 1枚あたりの価格(wei)
     * @returns {Promise}
     */
    acceptAsk(){
      const selectedAsk = this.card.askInfo[this.askId];
      const gas = 208055;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          await this.inputUnlock();
          try {
            const { id, totalPriceEth } = selectedAsk;
            const tx = this.web3c.acceptAsk(etherAccount, address, id, gas, totalPriceEth);
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
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject('err transaction faild');
          }
        }catch(e){
          reject('canceled');
        }
      });
    }

    selectBid(e){
      this.bidId = e ? e.item.i : null;
      this.update();
    }

    selectAsk(e){
      this.askId =  e ? e.item.i : null;
      this.update();
    }

    refreshAskInfo(){
      this.card = assign({}, this.card, {
        askInfo: this.web3c.refreshAskInfo(this.card.address)
      });
      this.update();
    }

    refreshBidInfo(){
      this.card = assign({}, this.card, {
        bidInfo: this.web3c.refreshBidInfo(this.card.address)
      });
      this.update();
    }

    /**
     * 買い注文(bid)を発行
     * @param {number} quantity 数量
     * @param {number} wei 1枚あたりの価格(wei)
     * @returns {Promise}
     */
    bid(quantity, wei){
      // TODO ここで単位をetherに変換
      const price = this.web3c.web3.fromWei(wei, 'ether');
      const gas = 800000;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          await this.inputUnlock();
          try{
            const tx = this.web3c.bid(etherAccount, address, quantity, price, gas);
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

    acceptBid(quantity){
      const selectedBid = this.card.bidInfo[this.bidId];
      const gas = 1523823;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try{
          await this.inputUnlock();
          try{
            const tx = this.web3c.acceptBid(etherAccount, address, selectedBid.id, quantity, gas);
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
