card-ask-form
  .panel
    .panel-header
      .panel-title カードを出品する
    .panel-body(if="{opts.numberOfCard > 0}")
      form.form-horizontal(autocomplete="off" role="presentation")
        .form-group
          .col-5
            label.form-label(for="input-quantity") 枚数
          .col-7
            input#input-quantity.form-input(
              type="number"
              oninput="{changeAskQuantity}"
              class="{'is-error': quantityError}"
              value="{askQuantity}"
            )
            p.form-input-hint(if="{quantityErrorMsg}") {quantityErrorMsg}
        .form-group
          .col-5
            label.form-label(for="input-price") 1枚あたりの価格
          .col-7
            .input-group
              input#input-price.form-input(
                type="text"
                oninput="{changePrice}"
                value="{askPrice}"
              )
              span.input-group-addon Ether
        .form-group
          .col-5
            label.form-label &nbsp;
          .col-7
            .input-group
              span.input-group-addon 約
              input.form-input(
                type="text"
                disabled
                value="{jpy}"
              )
              span.input-group-addon 円
        .form-group
          .col-5
          .col-7
            button.btn.btn-primary(
              onclick="{ask}"
              disabled="{!enableAsk}"
            ) 出品する
    .panel-footer(if="{opts.numberOfCard > 0}")

    .panel-body(if="{opts.numberOfCard === 0}")
      .empty
        .empty-icon
          i.icon.icon-message(style="font-size: 3rem")
        h4.empty-title カードを所有していません
    .panel-footer(if="{opts.numberOfCard === 0}")

  script.
    this.askPrice = '';
    this.askQuantity = 0;
    this.wei = null;
    this.jpy = null;
    this.enableAsk = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';

    /**
     * 「出品する」の枚数を変更
     */
    changeAskQuantity(e){
      this.askQuantity = _.toNumber(e.target.value);
      this.checkAskForm();
    }

    /**
     * 価格を変更
     */
    changePrice(e){
      this.askPrice = _.toNumber(e.target.value);
      if(this.askPrice > 0){
        const eth = this.web3c.web3.toBigNumber(this.askPrice);
        this.wei = this.web3c.web3.toWei(eth, 'ether');
        this.jpy = (this.opts.etherJpy * eth.toNumber()).toFixed(2);
      } else {
        this.wei = null;
        this.jpy = null;
      }
      this.checkAskForm();
    }

    /**
     * 入力値チェック
     */
    checkAskForm(){
      if(!this.askQuantity || this.askQuantity === 0){
        this.quantityError = false;
        this.quantityErrorMsg = ''
        this.enableAsk = false;
        return;
      }
      const isValidQt = _.isInteger(this.askQuantity) && this.askQuantity > 0;
      if(!isValidQt){
        this.quantityError = true;
        this.quantityErrorMsg = '正しい数値を入力してください'
        this.enableAsk = false;
        return;
      }
      if(this.opts.numberOfCard < this.askQuantity){
        this.quantityError = true;
        this.quantityErrorMsg = '所有枚数を超えています'
        this.enableAsk = false;
        return;
      }
      this.quantityError = false;
      this.quantityErrorMsg = ''
      this.enableAsk = isValidQt && this.wei;
    }

    /**
     * 売り注文(ask)を発行
     */
    async ask(e){
      e.preventDefault();
      if(this.askQuantity && this.jpy){
        try {
          await this.opts.ask(this.askQuantity, this.wei.toNumber());
          this.askQuantity = '';
          this.askPrice = '';
          this.wei = null;
          this.jpy = null;
          this.checkAskForm();
          this.update();
        } catch (e) {
          return;
        }
      }
    }
