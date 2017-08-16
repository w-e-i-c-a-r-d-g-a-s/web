card-deal
  .columns
    .column.col-6.col-xs-12.col-sm-12.col-md-12
      .panel.mb-10
        .panel-header
          .panel-title
            | カードを配布
            // button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{}")
              i.icon.icon-refresh
        .panel-body
          .empty(if="{opts.numberOfCard === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title カードを所有していません
          .columns(if="{opts.numberOfCard > 0}")
            .column.col-12
              form(autocomplete="off" role="presentation")
                .form-group
                  label.form-label(for="input-deal-quantity") 枚数
                  input#input-deal-quantity.form-input.input-sm(
                    type="number"
                    ref="dealQuantity"
                    oninput="{changeDealQuantity}"
                    class="{'is-error': quantityError}"
                  )
                  p.form-input-hint {quantityErrorMsg}
                .form-group
                  label.form-label(for="input-deal-address") 送信先アドレス
                  input#input-deal-address.form-input.input-sm(
                    type="text"
                    placeholder="0x..."
                    ref="sendAddress"
                  )
                .form-group
                  button.btn.btn-primary.btn-sm(onclick="{deal}" disabled="{!enableDeal}") 配布
        .panel-footer

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
      if(this.opts.totalSupply < qt){
        this.quantityError = true;
        this.quantityErrorMsg = '発行枚数を超えています'
        this.enableDeal = false;
        return;
      }
      this.quantityError = false;
      this.quantityErrorMsg = ''
      this.enableDeal = isValidQt;
    }

    async deal(){
      const { dealQuantity, sendAddress } = this.refs;
      // console.log(dealQuantity, sendAddress);
      if(dealQuantity.value && sendAddress.value){
        try {
          await this.opts.deal(dealQuantity.value, sendAddress.value);
          dealQuantity.value = sendAddress.value = '';
          this.checkDealForm();
          this.update();
        } catch(e) {
          return;
        }
      }
    }

