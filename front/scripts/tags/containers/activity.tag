activity
  .container.page
    .columns
      .column.col-3
      .column.col-6
        h5 Activity
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
                      span.label.label-primary.mr-10(if="{acts.inputMethod === 'addCard'}") カード発行
                      span.label.label-success.mr-10(if="{acts.inputMethod !== 'addCard'}") カード売買
                      a(href="#/cards/{acts.card.address}") {acts.card.name}
                      span : {getActivityText(acts)}
          .btn.mt-10(if="{isShowNext}" onclick="{getNext}" class="{loading: isNextLoading}") next
      .column.col-3
  script.
    import _ from 'lodash';
    this.isLoading = true;
    this.isNextLoading = false;
    this.isShowNext = false;
    this.activities = [];
    this.dispActivities = [];
    this.latestSK = null;

    this.etherJPY = null;
    opts.obs.on('updateEthPrice', (({ etherJPY }) => {
      this.etherJPY = etherJPY;
      this.update();
    }));

    this.on('mount', () => {
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
     * アクティビティのテキストを生成
     * @param {object} activity アクティビティデータ
     * @returns {string} テキスト
     */
    getActivityText(activity) {
      const { inputMethod, inputArgs, receipt } = activity;
      let res = '';
      const {from} = receipt;
      const _from = isMine ? '' : `${from.slice(0,8)}... が`;
      const isMine = from === this.user.etherAccount;
      switch (inputMethod) {
        case 'sellOrder':
          res = `${_from}${this.web3c.web3.fromWei(inputArgs[1], 'ether')}ETH で ${inputArgs[0]}枚 の売り注文を作成しました`
          break;
        case 'createBuyOrder':
          res = `${_from}${inputArgs[1]}ETH で ${inputArgs[0]}枚 の買い注文を作成しました`
          break;
        case 'sell':
          const index = inputArgs[0];
          const buyOrder = this.web3c.getAsk(activity.card.address, index);
          const price = this.web3c.web3.fromWei(buyOrder.price().toNumber(), 'ether');
          res = `${_from}${buyOrder.buyer().slice(0,8)}... へ ${price}ETH で ${inputArgs[1]}枚 売却しました`
          break;
        case 'send':
          res = `${_from}${inputArgs[0].slice(0,8)}... へ ${inputArgs[1]}枚 配布しました`
          break;
        case 'buy':
          const bid = this.web3c.getBid(activity.card.address, inputArgs[0]);
          const _price = this.web3c.web3.fromWei(bid[2].toNumber(), 'ether');
          res = `${_from}${bid[0].slice(0, 8)}...から${_price}ETHで${bid[1].toNumber()}枚 購入しました`
          break;
        case 'addCard':
          res = `${inputArgs[0]} を ${inputArgs[1]}枚 発行しました`
          break;
        default:
          res = `${inputMethod} しました`
      }

      return res;
    }
