card-bid-form
  .panel.mt-2
    .panel-header
      .panel-title カードを売却する
    .panel-body
      form(autocomplete="off" role="presentation")
        .columns
          .column.col-2
            .form-group
              label.form-label(for="input-bid-quantity") 枚数
              input#input-bid-quantity.form-input.input-sm(
                type="number"
                ref="bidQuantity"
                oninput="{changeBidQuantity}"
                class="{'is-error': quantityError}"
              )
              p.form-input-hint {quantityErrorMsg}
          .column.col-4
            .form-group
              label.form-label(for="input-bid-price") 一枚あたりの価格
              .input-group
                input#input-bid-price.form-input.input-sm(
                  type="text"
                  ref="bidPrice"
                  oninput="{changeBidPrice}"
                )
                span.input-group-addon.addon-sm Ether
              p.form-input-hint (現状整数のみ入力可)
          .column.col-4
            .form-group
              label.form-label &nbsp;
              .input-group
                span.input-group-addon.addon-sm 約
                input.form-input.input-sm.text-right(
                  type="text"
                  disabled
                  ref="bidWei"
                  value="{jpy}"
                )
                span.input-group-addon.addon-sm 円
          .column.col-1
            label.form-label &nbsp;
            button.btn.btn-primary.btn-sm(onclick="{bid}" disabled="{!enableBid}") 購入する
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

    async bid(e){
      e.preventDefault();
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

