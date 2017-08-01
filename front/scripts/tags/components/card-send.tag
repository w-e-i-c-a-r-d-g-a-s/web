card-send
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
                  label.form-label(for="input-send-quantity") 枚数
                  input#input-send-quantity.form-input.input-sm(
                    type="number"
                    ref="sendQuantity"
                    oninput="{changeSendQuantity}"
                    class="{'is-error': quantityError}"
                  )
                  p.form-input-hint {quantityErrorMsg}
                .form-group
                  label.form-label(for="input-send-address") 送信先アドレス
                  input#input-send-address.form-input.input-sm(
                    type="text"
                    placeholder="0x..."
                    ref="sendAddress"
                  )
                .form-group
                  button.btn.btn-primary.btn-sm(onclick="{send}" disabled="{!enableSend}") 配布
        .panel-footer

  script.
    this.enableSend = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';

    /**
     * 枚数を変更
     */
    changeSendQuantity(){
      this.checkSendForm();
    }

    /**
     * 入力値チェック
     */
    checkSendForm(){
      if(this.refs.sendQuantity.value === ''){
        this.quantityError = false;
        this.quantityErrorMsg = ''
        this.enableSend = false;
        return;
      }
      const qt = _.toNumber(this.refs.sendQuantity.value);
      const isValidQt = _.isNumber(qt) && _.isInteger(qt) && qt > 0;
      if(!isValidQt || qt === 0){
        this.quantityError = true;
        this.quantityErrorMsg = '正しい数値を入力してください'
        this.enableSend = false;
        return;
      }
      if(this.opts.issued < qt){
        this.quantityError = true;
        this.quantityErrorMsg = '発行枚数を超えています'
        this.enableSend = false;
        return;
      }
      this.quantityError = false;
      this.quantityErrorMsg = ''
      this.enableSend = isValidQt;
    }

    async send(){
      const { sendQuantity, sendAddress } = this.refs;
      console.log(sendQuantity, sendAddress);
      if(sendQuantity.value && sendAddress.value){
        try {
          await this.opts.send(sendQuantity.value, sendAddress.value);
          sendQuantity.value = sendAddress.value = '';
          this.checkSendForm();
          this.update();
        } catch(e) {
          return;
        }
      }
    }

