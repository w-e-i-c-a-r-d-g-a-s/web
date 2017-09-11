card-ask
  .panel.mt-2
    .panel-header
      .panel-title
        | カードを売りたい
        // button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshAskInfo}")
          // i.icon.icon-refresh
    .panel-body
      .columns
        .column.col-9
          h5.inline-block.text-normal 売り注文一覧
          .empty(if="{opts.askInfo && opts.askInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在売り注文はありません
          table.table.table-striped.table-hover(if="{opts.askInfo.length > 0}")
            tr
              th
              th 販売価格
              th 枚数
            tr(each="{o, i in opts.askInfo}")
              td
                small.bg-success.text-light.p-1.rounded(show="{i === 0}") 最安値!
              td.tooltip(data-tooltip="{o.price} Wei")
                price(val="{o.price}" unit="wei")
              td {o.quantity}
          card-accept-ask(
            accept-ask="{acceptAsk}"
            ask-info="{opts.askInfo}"
            ether-jpy="{opts.etherJpy}"
            check-accept-ask="{checkAcceptAsk}"
            enable-accept-ask="{enableAcceptAsk}"
            error-msg="{errorMsg}"
          )
    .panel-footer

  card-ask-form(
    number-of-card="{opts.numberOfCard}"
    change-quantity="{changeQuantity}"
    quantity-error="{quantityError}"
    quantity-error-msg="{quantityErrorMsg}"
    change-price="{changePrice}"
    jpy="{jpy}"
    ask="{ask}"
    enable-ask="{enableAsk}"
    ask-quantity="{askQuantity}"
    ask-price="{askPrice}"
  )

  script.
    this.askQuantity = '';
    this.askPrice = '';
    this.wei = null;
    this.jpy = null;
    this.enableAsk = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';
    this.errorMsg = '';

    /**
     * 枚数を変更
     */
    changeQuantity(e){
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

    checkAcceptAsk(inputPrice, inputQt){
      for(let i = 0, len = opts.askInfo.length; i < len; i++){
        const ask = opts.askInfo[i];
        // 同一の金額があるかどうか
        if(ask.priceEth === inputPrice){
          if(inputQt > 0){
            if(inputQt <= ask.quantity){
              this.errorMsg = '';
              this.enableAcceptAsk = true;
              this.selectedAsk = ask;
              return;
            }else{
              this.errorMsg = '枚数が販売枚数より多いです';
              this.enableAcceptAsk = false;
              this.selectedAsk = null;
            }
          }
          break;
        }
      }
      this.enableAcceptAsk = false;
      this.selectedAsk = null;
    }

    async acceptAsk(quantity){
      try {
        await this.opts.acceptAsk(this.selectedAsk, quantity);
        this.update();
      } catch (e) {
        // noop
      }
    }

    async cancelAsk(e){
      try {
        await this.opts.cancelAsk(e.item.i);
        this.update();
      } catch (e) {
        // noop
      }
    }


