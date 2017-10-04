activity
  .container.page
    .columns.mt-2
      .column.col-7
        h5 カード売り買い一覧
        my-act-card(
          each="{card in myCards}"
          card="{card}"
          cancel-ask="{parent.cancelAsk}"
          cancel-bid="{parent.cancelBid}"
        )

      .column.col-5
        h5 アクティビティ
        .loading(if="{isLoading}")
        div(if="{!isLoading}")
          div(if="{dispActivities.length === 0}")
            p Activityはありません
          .timeline(if="{dispActivities.length > 0}")
            .timeline-item(each="{act in dispActivities}")
              .timeline-left
                .timeline-icon(if="{act.activities[0].receipt.from !== user.etherAccount}")
                .timeline-icon.icon-lg(if="{act.activities[0].receipt.from === user.etherAccount}")
                  i.icon.icon-time
              .timeline-content
                .tile
                  .tile-content
                    p.tile-subtitle {(new Date(+act.timestamp * 1000)).toLocaleString("ja")}
                    p.tile-title(each="{ acts in act.activities }")
                      span.label.label-primary.mx-1(if="{acts.inputMethod === 'addCard'}") カード発行
                      span.label.label-success.mx-1(if="{acts.inputMethod !== 'addCard'}") カード売買
                      span.label.label-error.mx-1(if="{!acts.isSuccess}") 失敗
                      a(href="#/cards/{acts.card.address}") {acts.card.name}
                      span : {getActivityText(acts)}
          button.btn.mt-2(if="{isShowNext}" onclick="{getNext}" class="{loading: isNextLoading}") next
    password-modal(
      show="{showPasswordModal}"
      deferred="{deferred}"
      obs="{opts.obs}"
    )
  script.
    import Deferred from 'es6-deferred';
    import _ from 'lodash';
    this.isLoading = true;
    this.isNextLoading = false;
    this.isShowNext = false;
    this.activities = [];
    this.dispActivities = [];
    this.latestSK = null;

    this.etherJPY = null;
    this.myCards = [];
    this.showPasswordModal = false;

    opts.obs.on('updateEthPrice', (({ etherJPY }) => {
      this.etherJPY = etherJPY;
      this.update();
    }));

    this.on('mount', () => {
      this.myCards = this.web3c.getCards(this.user.etherAccount);
      this.myCards.forEach(async (c) => {
        const cardData = await this.firebase.getCard(c.imageHash);
        if(cardData){
          c.imageUrl = cardData.url;
        }
        this.update();
      });

      // this.firebase.updateUserTransactionsRef(this.user.etherAccount);
      const utRef = this.firebase.getUserTransactionsRef(this.user.etherAccount);
      utRef.once('value', (snapshots) => {
        // データが最後の場合ボタンを非表示
        if(snapshots.numChildren() === 5){
          this.isShowNext = true
        }
        this.isLoading = false;
        this.update();
      });

      utRef.on('child_added', (ss, prevChildKey) => {
        const v = ss.val();
        v.key = ss.key;
        v.receipt = this.web3c.web3.eth.getTransactionReceipt(v.key);
        if(v.inputMethod === 'addCard'){
          v.card = this.web3c.getCard(this.web3c.getCardByImageHash(v.inputArgs[2]).address);
        } else {
          v.card = this.web3c.getCard(v.receipt.to);
        }
        // 初回にまとめて取ってくるとき以外は prevChildKeyがnullになる
        if(prevChildKey){
          // 前のデータがあるときは後ろに
          this.activities.push(v);
        }else{
          // 前のデータがないときは先頭に
          this.activities.unshift(v);
        }
        this.updateDispActivities();
        this.update();
        this.latestSK = _.last(this.activities).sortKey;
      });
    });

    this.on('unmount', () => {
      const utRef = this.firebase.getUserTransactionsRef(this.user.etherAccount);
      utRef.off('child_added');
    });

    updateDispActivities(){
      this.dispActivities = [];
      const groupByTimestamp = _.groupBy(this.activities, 'timestamp');
      for(const ts in groupByTimestamp){
        const v = groupByTimestamp[ts];
        this.dispActivities.push({timestamp: ts, activities: v});
      }
      this.dispActivities = _.orderBy(this.dispActivities, ['timestamp'], ['desc']);
    }

    getNext(){
      const utRef = this.firebase.getUserTransactionsRef(this.user.etherAccount, this.latestSK);
      this.isNextLoading = true;
      this.update();
      utRef.once('value', (snapshots) => {
        snapshots.forEach((ss) => {
          const v = ss.val();
          v.key = ss.key;
          v.receipt = this.web3c.web3.eth.getTransactionReceipt(v.key);
          if(v.inputMethod === 'addCard'){
            v.card = this.web3c.getCard(this.web3c.getCardByImageHash(v.inputArgs[2]).address);
          } else {
            v.card = this.web3c.getCard(v.receipt.to);
          }
          this.activities.push(v);
        });

        // データが最後の場合ボタンを非表示
        if(snapshots.numChildren() < 5){
          // TODO 件数が残り5件だった場合、もう一回押すことになる
          this.isShowNext = false
          this.update();
        }

        this.updateDispActivities();
        this.isNextLoading = false;
        this.update();
        this.latestSK = _.last(this.activities).sortKey;
      });
    }

    /**
     * 売り注文を取り消し
     * @param {number} price 売り注文の金額(wei)
     * @returns {Promise}
     */
    cancelAsk(price){
      /*
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
      */
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

    /**
     * 買い注文を取り消し
     *
     * @param {string} address アドレス
     * @param {number} price 買い注文の金額
     * @returns {Promise}
     */
    cancelBid(address, price){
      const gas = 1523823;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try{
          await this.inputUnlock();
          try{
            const tx = this.web3c.cancelBid(etherAccount, address, price, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
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

    unlockAccount(){
      // モーダルを表示し、処理を待つ
      this.deferred = new Deferred();
      this.showPasswordModal = true;
      this.update();
      return this.deferred.promise;
    }

    /**
     * アクティビティのテキストを生成
     * @param {object} activity アクティビティデータ
     * @returns {string} テキスト
     */
    getActivityText(activity) {
      const { inputMethod, inputArgs } = activity;
      let res = '';
      switch (inputMethod) {
        case 'ask':
          res = this.genAskText(inputArgs);
          break;
        case 'bid':
          res = this.genBidText(inputArgs);
          break;
        case 'acceptBid':
          res = this.genAcceptBidText(inputArgs, activity.card.address);
          break;
        case 'deal':
          res = this.genDealText(inputArgs);
          break;
        case 'acceptAsk':
          res = this.genAcceptAskText(inputArgs);
          break;
        case 'addCard':
          res = `${inputArgs[1]}枚 発行しました`
          break;
        default:
          res = `${inputMethod} しました`
      }

      return res;
    },

    genDealText(inputArgs){
      return `${inputArgs[1]}枚 配布されました`
    },

    genAskText(inputArgs){
      const [ qt, price ] = inputArgs;
      const _price = this.web3c.web3.fromWei(price, 'ether');
      return `${_price}ETH で ${qt}枚 の売り注文を作成されました`
    },

    genBidText(inputArgs){
      const [ qt, price ] = inputArgs;
      const _price = this.web3c.web3.fromWei(price, 'ether');
      return `${_price}ETH で ${qt}枚 の買い注文が作成されました`
    },

    genAcceptAskText(inputArgs){
      const [ price, qt ] = inputArgs;
      const _price = this.web3c.web3.fromWei(price, 'ether');
      return `${_price}ETH で ${inputArgs[1]}枚 購入されました`
    },

    genAcceptBidText(inputArgs){
      const [ price, qt ] = inputArgs;
      const _price = this.web3c.web3.fromWei(price, 'ether');
      return `${_price}ETH で ${qt}枚 売却されました`
    }
