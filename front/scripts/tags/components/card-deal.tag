card-deal
  .empty(if="{opts.card.numberOfCard === 0}")
    .empty-icon
      i.icon.icon-message(style="font-size: 3rem")
    h4.empty-title カードを所有していません
  .columns(if="{opts.card.numberOfCard > 0}")
    .column.col-12
      form.form-horizontal(autocomplete="off" role="presentation")
        .form-group
          .col-3
            label.form-label(for="input-deal-quantity") 枚数
          .col-9
            input#input-deal-quantity.form-input.input-sm(
              type="number"
              ref="dealQuantity"
              oninput="{changeDealQuantity}"
              class="{'is-error': quantityError}"
            )
            p.form-input-hint {quantityErrorMsg}
        .form-group
          .col-3
            label.form-label(for="input-deal-address") 送信先アドレス
          .col-9
            input#input-deal-address.form-input.input-sm(
              type="text"
              placeholder="0x..."
              oninput="{changeDealQuantity}"
              ref="sendAddress"
            )
        .form-group
          .col-12
            button.btn.btn-primary.btn-sm.float-right(onclick="{deal}" disabled="{!enableDeal}") 配布

  script.
    this.enableDeal = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';

    /**
     * 枚数を変更
     */
    changeDealQuantity(){
      this.checkDealForm();
    }

    /**
     * 入力値チェック
     */
    checkDealForm(){
      if(this.refs.dealQuantity.value === ''){
        this.quantityError = false;
        this.quantityErrorMsg = ''
        this.enableDeal = false;
        return;
      }
      const qt = _.toNumber(this.refs.dealQuantity.value);
      const isValidQt = _.isNumber(qt) && _.isInteger(qt) && qt > 0;
      if(!isValidQt || qt === 0){
        this.quantityError = true;
        this.quantityErrorMsg = '正しい数値を入力してください'
        this.enableDeal = false;
        return;
      }
      if(this.opts.card.totalSupply < qt){
        this.quantityError = true;
        this.quantityErrorMsg = '発行枚数を超えています'
        this.enableDeal = false;
        return;
      }
      if(this.opts.card.numberOfCard < qt){
        this.quantityError = true;
        this.quantityErrorMsg = '所有枚数を超えています'
        this.enableDeal = false;
        return;
      }
      this.quantityError = false;
      this.quantityErrorMsg = ''
      const { sendAddress } = this.refs;
      this.enableDeal = isValidQt && sendAddress.value;
    }

    async deal(e){
      e.preventDefault();
      const { dealQuantity, sendAddress } = this.refs;
      try {
        await this.opts.deal(dealQuantity.value, sendAddress.value);
        dealQuantity.value = sendAddress.value = '';
        this.checkDealForm();
        this.update();
      } catch(e) {
        console.error(e);
        return;
      }
    }

