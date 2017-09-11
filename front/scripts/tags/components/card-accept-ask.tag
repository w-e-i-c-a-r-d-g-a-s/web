card-accept-ask
  .columns.mt-2(if="{opts.askInfo.length > 0}")
    .column.col-1
      .form-group
        label.form-label.label-sm.text-right(for="input-ask-price") 金額
    .column.col-3
      .form-group
        .input-group
          input#input-ask-quantity.form-input.input-sm.text-right(
            type="text"
            ref="askPrice"
            oninput="{changeAcceptAskPrice}"
          )
          span.input-group-addon.addon-sm Ether
    .column.col-3
      .form-group
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
      .form-group
        label.form-label.label-sm.text-right(for="input-ask-quantity") 枚数
    .column.col-2
      .form-group(class="{'has-error': opts.errorMsg }")
        input#input-ask-quantity.form-input.input-sm(
          type="number"
          ref="askQuantity"
          oninput="{checkAcceptAsk}"
        )
        p.form-input-hint {opts.errorMsg}
    .column.col-2
      .form-group
        button.btn.btn-sm.btn-primary.btn-block(onclick="{acceptAsk}" disabled="{!opts.enableAcceptAsk}") 購入する

  script.
    this.jpy = 0;
    this.enableAcceptAsk = false;
    changeAcceptAskPrice(e){
      this.askPrice = _.toNumber(e.target.value) || 0;
      if(this.askPrice > 0){
        const _eth = this.web3c.web3.toBigNumber(this.askPrice);
        this.jpy = (this.opts.etherJpy * _eth.toNumber()).toFixed(2);
      } else {
        this.jpy = null;
      }

      this.checkAcceptAsk();
    }

    checkAcceptAsk(){
      this.quantity = _.toNumber(this.refs.askQuantity.value) || 0;
      this.opts.checkAcceptAsk(this.askPrice, this.quantity);
    }

    acceptAsk(){
      this.opts.acceptAsk(this.quantity);
    }
