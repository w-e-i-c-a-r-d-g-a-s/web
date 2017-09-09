card-bid
  .panel.mt-2
    .panel-header
      .panel-title
        | カードを買う
        button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshBidInfo}")
          i.icon.icon-refresh
    .panel-body
      .columns
        .column.col-3.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-4
          .panel
            .panel-header
              .panel-title 買い注文
            .panel-body
              form(autocomplete="off" role="presentation")
                .form-group
                  label.form-label(for="input-bid-quantity") 枚数
                  input#input-bid-quantity.form-input.input-sm(
                    type="number"
                    ref="bidQuantity"
                    oninput="{changeBidQuantity}"
                    class="{'is-error': quantityError}"
                  )
                  p.form-input-hint {quantityErrorMsg}
                .form-group
                  label.form-label(for="input-bid-price") 一枚あたりの価格
                  .input-group
                    input#input-bid-price.form-input.input-sm(
                      type="text"
                      ref="bidPrice"
                      oninput="{changeBidPrice}"
                    )
                    span.input-group-addon.addon-sm Ether
                  p.form-input-hint 現状整数のみ入力可
                  label.form-label
                  .input-group
                    input.form-input.input-sm(
                      type="text"
                      disabled
                      ref="bidWei"
                      value="{wei && wei.toFormat()}"
                    )
                    span.input-group-addon.addon-sm Wei
            .panel-footer
              button.btn.btn-primary.btn-sm(onclick="{bid}" disabled="{!enableBid}") 買う

        .column.col-9.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-8
          h5.inline-block.text-normal 出品中のカード
          .empty(if="{opts.bidInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在買い注文はありません
          table.table.table-striped.table-hover(if="{opts.bidInfo.length > 0}")
            tr
              th
              th
              th 枚数
              th 一枚あたりの価格
            tr(each="{o, i in opts.bidInfo}" onclick="{selectBuyOrderRow}")
              td
                small.bg-success.text-light.p-1.rounded(show="{i === 0}") 最高値!
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

          .columns.col-gapless(if="{opts.bidInfo.length > 0}")
            .column.col-12
              .form-group
                label.form-label(for="input-buyorder-quantity") 枚数
                input#input-buyorder-quantity.form-input.input-sm(
                  type="number" placeholder="" ref="buyOrderQuantity"
                )
              .form-group
                button.btn.btn-sm.btn-primary(
                  onclick="{acceptBid}"
                  disabled="{!_.isNumber(opts.bidId)}"
                ) 選択した価格で売却
    .panel-footer

  script.
    this.wei = null;
    this.enableBid = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';

    /**
     * 枚数を変更
     */
    changeBidQuantity(){
      this.checkBidForm();
    }

    /**
     * 価格を変更
     */
    changeBidPrice(e){
      const _eth = _.toNumber(e.target.value);
      if(_.isNumber(_eth) && !_.isNaN(_eth)){
        const eth = this.web3c.web3.toBigNumber(_eth);
        this.wei = this.web3c.web3.toWei(eth, 'ether');
      } else {
        this.wei = null;
      }
      this.checkBidForm();
    }

    /**
     * 入力値チェック
     */
    checkBidForm(){
      if(this.refs.bidQuantity.value === ''){
        this.quantityError = false;
        this.quantityErrorMsg = ''
        this.enableBid = false;
        return;
      }
      const qt = _.toNumber(this.refs.bidQuantity.value);
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
      this.opts.selectBid(e);
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
          this.opts.selectBid(null);
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
