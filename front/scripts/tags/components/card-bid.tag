card-bid
  .panel.mt-2
    .panel-header
      .panel-title
        | カードを買う
        button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshBidInfo}")
          i.icon.icon-refresh
    .panel-body
      .columns
        .column.col-12
          h5.inline-block.text-normal 出品中のカード
          .empty(if="{opts.bidInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在買い注文はありません
          table.table.table-striped.table-hover(if="{opts.bidInfo.length > 0}")
            tr
              th
              th
              th 販売価格
              th 販売枚数
            tr(each="{o, i in opts.bidInfo}" onclick="{selectBuyOrderRow}")
              td
                small.bg-success.text-light.p-1.rounded(show="{i === 0}") 最安値!
              td
                input(
                  type="radio"
                  name="sell"
                  value="{i}"
                  checked="{o.selected}"
                  onchange="{parent.opts.selectSell}"
                  if="{o.buyer !== parent.user.etherAccount.toLowerCase()}"
                )
              td {o.quantity}
              td.tooltip(data-tooltip="{o.price} Wei") {o.priceEth} Ether

          .columns(if="{opts.bidInfo.length > 0}")
            .column.col-1
              .form-group
                label.form-label.label-sm(for="input-buyorder-quantity") 枚数
            .column.col-10
              .form-group
                input#input-buyorder-quantity.form-input.input-sm(
                  type="number" placeholder="" ref="buyOrderQuantity"
                )
            .column.col-1
              .form-group
                button.btn.btn-sm.btn-primary(
                  onclick="{acceptBid}"
                  disabled="{!_.isNumber(opts.bidId)}"
                ) 購入する

    .panel-footer
  card-bid-form(
    change-bid-quantity="{changeBidQuantity}"
    quantity-error="{quantityError}"
    quantity-error-msg="{quantityErrorMsg}"
    change-bid-price="{changeBidPrice}"
    jpy="{jpy}"
    bid="{bid}"
    enable-bid="{enableBid}"
  )

  script.
    this.bidQuantity = 0;
    this.wei = null;
    this.jpy = null;
    this.enableBid = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';

    /**
     * 枚数を変更
     */
    changeBidQuantity(e){
      this.bidQuantity = e.target.value;
      this.checkBidForm();
    }

    /**
     * 価格を変更
     */
    changeBidPrice(e){
      const _eth = _.toNumber(e.target.value);
      if(_.isNumber(_eth) && !_.isNaN(_eth) && _eth > 0){
        const eth = this.web3c.web3.toBigNumber(_eth);
        this.wei = this.web3c.web3.toWei(eth, 'ether');
        this.jpy = (this.opts.etherJpy * eth.toNumber()).toFixed(2);
      } else {
        this.wei = null;
        this.jpy = null;
      }
      this.checkBidForm();
    }

    /**
     * 入力値チェック
     */
    checkBidForm(){
      if(this.bidQuantity === ''){
        this.quantityError = false;
        this.quantityErrorMsg = ''
        this.enableBid = false;
        return;
      }
      const qt = _.toNumber(this.bidQuantity);
      const isValidQt = _.isNumber(qt) && _.isInteger(qt) && qt > 0;
      if(!isValidQt || qt === 0){
        this.quantityError = true;
        this.quantityErrorMsg = '正しい数値を入力してください'
        this.enableBid = false;
        return;
      }
      if(this.opts.totalSupply < qt){
        this.quantityError = true;
        this.quantityErrorMsg = '発行枚数を超えています'
        this.enableBid = false;
        return;
      }
      this.quantityError = false;
      this.quantityErrorMsg = ''
      this.enableBid = isValidQt && this.wei;
    }

    /**
     * 買い注文を選択
     */
    selectBuyOrderRow(e){
      if(e.item.o.buyer === this.user.etherAccount.toLowerCase()){
        return;
      }
      this.opts.bidInfo.map((s, i) => s.selected = i === e.item.i);
      this.update();
    }

    async bid(){
      const { bidQuantity, bidPrice, bidWei } = this.refs;
      if(bidQuantity.value && this.wei){
        try {
          await this.opts.bid(bidQuantity.value, this.wei.toNumber());
          bidQuantity.value = bidPrice.value = bidWei.value = '';
          this.wei = null;
          this.checkBidForm();
          this.update();
        } catch(e) {
          return;
        }
      }
    }

    async acceptBid(){
      const { buyOrderQuantity } = this.refs;
      if(buyOrderQuantity.value){
        try {
          await this.opts.acceptBid(buyOrderQuantity.value);
          // チェック、入力をリセット
          buyOrderQuantity.value = '';
          this.opts.bidInfo.map((s, i) => s.selected = false);
          this.update();
        } catch(e) {
          return;
        }
      }
    }

    async cancelBid(e){
      try {
        await this.opts.cancelBid(e.item.i);
        this.update();
      } catch(e) {
        console.error(e, 'fail: cancelBid');
      }
    }
