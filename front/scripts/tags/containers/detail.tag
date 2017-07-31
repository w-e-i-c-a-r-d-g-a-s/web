detail
  .container.page.page-detail
    .columns
      .column.col-3.col-xs-12.col-sm-12.col-md-12.col-lg-4.col-xl-3
        .columns
          .column.col-12.col-xs-12.col-sm-6.col-md-5.col-lg-12.col-xl-12
            card(card="{card}" single="{true}")
          .column.col-12.col-xs-12.col-sm-6.col-md-7.col-lg-12.col-xl-12
            card-owners(card="{card}")

      .column.col-9.col-xs-12.col-sm-12.col-md-12.col-lg-8.col-xl-9
        card-bid(
          accept-bid="{acceptBid}"
          bid="{bid}"
          refresh-bid-info="{refreshBidInfo}"
          bid-info="{card.bidInfo}"
          select-bid="{selectBid}"
          bid-id="{bidId}"
        )
        card-ask(
          ask="{ask}"
          refresh-ask-info="{refreshAskInfo}"
          ask-info="{card.askInfo}"
          select-ask="{selectAsk}"
          ask-id="{askId}"
          accept-ask="{acceptAsk}"
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

    this.on('mount', async () => {
      this.card = this.web3c.getCard(this.opts.cardAddress);
      const cardData = await this.firebase.getCard(this.card.imageHash);
      this.card.imageUrl = cardData.url;
      this.update();
    });

    /**
     * 売り注文(bid)を発行
     *
     * @param {number} quantity 数量
     * @param {number} wei 一枚あたりの価格(wei)
     * @returns {Promise}
     */
    bid(quantity, wei){
      const gas = 200000;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          // パスワード入力
          try {
            await this.inputUnlock();
            const tx = this.web3c.bid(quantity, wei, address, etherAccount, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
            resolve();
          } catch (e) {
            // キャンセル
            reject('canceled');
          }
        }catch(e){
          this.opts.obs.trigger('notifyError', { text: e.message });
          reject('err transaction faild');
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

    refreshBidInfo(){
      this.card = assign({}, this.card, {
        bidInfo: this.web3c.refreshBidInfo(this.card.address)
      });
      this.update();
    }

    refreshAskInfo(){
      this.card = assign({}, this.card, {
        askInfo: this.web3c.refreshAskInfo(this.card.address)
      });
      this.update();
    }

    acceptBid(){
      const selectedBid = this.card.bidInfo[this.bidId];
      const gas = 208055;
      try {
        const tx = this.web3c.acceptBid(
          this.user.etherAccount,
          this.card.address,
          selectedBid.id,
          gas,
          selectedBid.totalPriceEth
        );
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.notify(e.message, 'error');
      }
    }

    /**
     * 買い注文を発行
     *
     * @param {number} quantity 数量
     * @param {number} wei 1枚あたりの価格(wei)
     * @returns {Promise}
     */
    ask(quantity, wei){
      // TODO ここで単位をetherに変換
      const price = this.web3c.web3.fromWei(wei, 'ether');
      const gas = 800000;
      const { address } = this.card;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          await this.inputUnlock();
          try{
            const tx = this.web3c.ask(etherAccount, address, quantity, price, gas);
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

    acceptAsk(quantity){
      const selectedAsk = this.card.askInfo[this.askId];
      const gas = 1523823;
      try{
        const tx = this.web3c.acceptAsk(
          this.user.etherAccount,
          this.card.address,
          selectedAsk.id,
          quantity,
          gas
        );
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.opts.obs.trigger('notifyError', { text: e.message });
      }
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
