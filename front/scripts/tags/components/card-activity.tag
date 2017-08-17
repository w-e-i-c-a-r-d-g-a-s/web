card-activity
  .panel.mb-10
    .panel-header
      .panel-title
        | Card Activity
      .panel-body
        table.table.table-striped.table-hover
          thead
            tr
              th 時刻
              th イベント
              // th release date
              // th from
          tbody
            tr(each="{act in activities}")
              td {(new Date(+act.timestamp * 1000)).toLocaleString("ja")}
              td
                span.label.label-success.mr-10(if="{act.isDeal}") 売買
                span.label.mr-10(if="{!act.isDeal}") 発行
                | {act.text}
      .panel-footer

  script.
    import _ from 'lodash';
    this.isShowNext = false;
    this.activities = [];
    this.dispActivities = [];
    this.latestSK = null;
    this.on('mount', () => {
      // 履歴
      const utRef = this.firebase.getCardTransactions(this.opts.cardAddress);
      // 5件以上あるかどうか
      utRef.once('value', (snapshots) => {
        // データが最後の場合ボタンを非表示
        if(snapshots.numChildren() === 5){
          this.isShowNext = true
          this.update();
        }
      });

      utRef.on('child_added', (ss, prevChildKey) => {
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
        // this.updateDispActivities();
        // console.table(this.activities);
        this.update();
        this.latestSK = _.last(this.activities).sortKey;
      });
    });

    this.on('unmount', () => {
      this.firebase.getCardTransactions(this.opts.cardAddress).off('child_added');
    });

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
        const bid = this.web3c.getAsk(card.address, inputArgs[0]);
        const _price = this.web3c.weiToEth(bid[2].toNumber());
        return `${_price}ETHで${bid[1].toNumber()}枚 販売されました`
      }
      // 買い注文から買う
      if(inputMethod === 'bid'){
        return `${inputArgs[1]}ETH で ${inputArgs[0]}枚 の買い注文が作成されました`
      }
      // 買い注文から売る
      if(inputMethod === 'acceptBid'){
        const index = inputArgs[0];
        const buyOrder = this.web3c.getBid(card.address, index);
        const price = this.web3c.weiToEth(buyOrder.price().toNumber());
        return `${price}ETH で ${inputArgs[1]}枚 売却しました`
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

