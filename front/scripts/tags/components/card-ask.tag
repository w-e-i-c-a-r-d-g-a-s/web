card-ask
  .panel
    .panel-header
      .panel-title
        | カードを買いたい
        button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshAskInfo}")
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
                  label.form-label(for="input-ask-quantity") 枚数
                  input#input-ask-quantity.form-input.input-sm(
                    type="number"
                    ref="askQuantity"
                    oninput="{changeAskQuantity}"
                  )
                  label.form-label(for="input-ask-price") 一枚あたりの価格
                  .input-group
                    input#input-ask-price.form-input.input-sm(
                      type="text"
                      ref="askPrice"
                      oninput="{changeAskPrice}"
                    )
                    span.input-group-addon.addon-sm Ether
                  label.form-label
                  .input-group
                    input.form-input.input-sm(
                      type="text"
                      disabled
                      ref="askWei"
                      value="{wei && wei.toFormat()}"
                    )
                    span.input-group-addon.addon-sm Wei
            .panel-footer
              button.btn.btn-primary.btn-sm(
                onclick="{ask}"
                disabled="{!enableAsk}"
              ) 買う

        .column.col-9.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-8
          h5.inline-block.text-normal 買い注文一覧
          .empty(if="{opts.askInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在買い注文はありません
          table.table.table-striped.table-hover(if="{opts.askInfo.length > 0}")
            tr
              th
              th 購入者
              th 枚数
              th 一枚あたりの価格
              th 総価格
            tr(each="{o, i in opts.askInfo}" onclick="{selectBuyOrderRow}")
              td
                input(
                  type="radio"
                  name="sell"
                  value="{i}"
                  checked="{o.selected}"
                  onchange="{parent.opts.selectSell}"
                  if="{o.buyer !== parent.opts.user.etherAccount.toLowerCase()}"
                )
              td
                .tile.tile-centered
                  .tile-icon
                    img.avatar.avatar-sm(src="{ firebase.addressToPhotoUrl[o.buyer] }")
                  .tile-content.inline-block.text-ellipsis.addr {o.buyer}
              td {o.quantity}
              td.tooltip(data-tooltip="{o.price} Wei") {o.priceEth} Ether
              td.tooltip(data-tooltip="{o.totalPrice} Wei") {o.totalPriceEth} Ether
          .columns.col-gapless(if="{opts.askInfo.length > 0}")
            .column.col-12
              .form-group
                label.form-label(for="input-buyorder-quantity") 枚数
                input#input-buyorder-quantity.form-input.input-sm(
                  type="number" placeholder="" ref="buyOrderQuantity"
                )
              .form-group
                button.btn.btn-sm.btn-primary(
                  onclick="{acceptAsk}"
                  disabled="{!_.isNumber(opts.askId)}"
                ) 選択した価格で売却
    .panel-footer

  script.
    this.wei = null;
    this.enableAsk = false;

    /**
     * 枚数を変更
     */
    changeAskQuantity(){
      this.checkAskForm();
    }

    /**
     * 価格を変更
     */
    changeAskPrice(e){
      const _eth = _.toNumber(e.target.value);
      if(_.isNumber(_eth) && !_.isNaN(_eth)){
        const eth = this.web3c.web3.toBigNumber(_eth);
        this.wei = this.web3c.web3.toWei(eth, 'ether');
      } else {
        this.wei = null;
      }
      this.checkAskForm();
    }

    /**
     * 入力値チェック
     */
    checkAskForm(){
      const qt = _.toNumber(this.refs.askQuantity.value);
      const isValidQt = _.isNumber(qt) && _.isInteger(qt) && qt > 0;
      this.enableAsk = isValidQt && this.wei;
    }

    /**
     * 買い注文を選択
     */
    selectBuyOrderRow(e){
      if(e.item.o.buyer === this.opts.user.etherAccount.toLowerCase()){
        return;
      }
      this.opts.askInfo.map((s, i) => s.selected = i === e.item.i);
      this.opts.selectAsk(e);
      this.update();
    }

    ask(){
      const { askQuantity, askPrice } = this.refs;
      if(askQuantity.value && this.wei){
        this.opts.ask(askQuantity.value, this.wei.toNumber());
        askQuantity.value = '';
        askPrice.value = '';
        this.wei = null;
        this.checkAskForm();
      }
    }

    acceptAsk(){
      const { buyOrderQuantity } = this.refs;
      if(buyOrderQuantity.value){
        this.opts.acceptAsk(buyOrderQuantity.value);
        // チェック、入力をリセット
        buyOrderQuantity.value = '';
        this.opts.askInfo.map((s, i) => s.selected = false);
        this.opts.selectAsk(null);
        this.update();
      }
    }
