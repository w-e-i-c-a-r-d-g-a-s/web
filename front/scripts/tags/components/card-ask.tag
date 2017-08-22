card-ask
  .panel.mt-2
    .panel-header
      .panel-title
        | カードを売りたい
        button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshAskInfo}")
          i.icon.icon-refresh
    .panel-body
      .columns
        .column.col-3.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-4
          .panel
            .panel-header
              .panel-title 売り注文
            .panel-body(if="{opts.numberOfCard > 0}")
              form(autocomplete="off" role="presentation")
                .form-group
                  label.form-label(for="input-quantity") 枚数
                  input#input-quantity.form-input.input-sm(
                    type="number"
                    ref="quantity"
                    oninput="{changeQuantity}"
                    class="{'is-error': quantityError}"
                  )
                  p.form-input-hint {quantityErrorMsg}
                  label.form-label(for="input-price") 1枚あたりの価格
                  .input-group
                    input#input-price.form-input.input-sm(
                      type="text"
                      ref="price"
                      oninput="{changePrice}"
                    )
                    span.input-group-addon.addon-sm Ether
                  label.form-label
                  .input-group
                    input.form-input.input-sm(
                      type="text"
                      disabled
                      ref="wei"
                      value="{wei && wei.toFormat()}"
                    )
                    span.input-group-addon.addon-sm Wei
            .panel-footer(if="{opts.numberOfCard > 0}")
              button.btn.btn-primary.btn-sm(onclick="{ask}" disabled="{!enableAsk}") 売る
            .panel-body(if="{opts.numberOfCard === 0}")
              .empty
                .empty-icon
                  i.icon.icon-message(style="font-size: 3rem")
                h4.empty-title カードを所有していません
            .panel-footer(if="{opts.numberOfCard === 0}")
        .column.col-9.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-8
          h5.inline-block.text-normal 売り注文一覧
          .empty(if="{opts.askInfo && opts.askInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在売り注文はありません
          table.table.table-striped.table-hover(if="{opts.askInfo.length > 0}")
            tr
              th
              th 売却者
              th 枚数
              th 一枚あたりの価格
              th 総価格
            tr(each="{o, i in opts.askInfo}" onclick="{selectRow}")
              td
                input(
                  type="radio"
                  name="askrow"
                  value="{i}"
                  checked="{o.selected}"
                  onchange="{parent.opts.selectAsk}"
                  if="{o.from !== parent.user.etherAccount.toLowerCase()}"
                )
              td
                .tile.tile-centered
                  .tile-content.inline-block.text-ellipsis.addr {o.from}
              td {o.quantity}
              td.tooltip(data-tooltip="{o.price} Wei") {o.priceEth} Ether
              td.tooltip(data-tooltip="{o.totalPrice} Wei") {o.totalPriceEth} Ether
          .columns.col-gapless
            .column.col-12(if="{opts.askInfo.length > 0}")
              button.btn.btn-sm.btn-primary(
                onclick="{acceptAsk}"
                disabled="{!_.isNumber(opts.askId)}"
              ) 選択したものを購入
    .panel-footer

  script.
    this.wei = null;
    this.enableAsk = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';

    /**
     * 枚数を変更
     */
    changeQuantity(){
      this.checkAskForm();
    }

    /**
     * 価格を変更
     */
    changePrice(e){
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
      const qt = _.toNumber(this.refs.quantity.value);
      if(qt === 0){
        this.quantityError = false;
        this.quantityErrorMsg = ''
        this.enableAsk = false;
        return;
      }
      const isValidQt = _.isNumber(qt) && _.isInteger(qt) && qt > 0;
      if(!isValidQt){
        this.quantityError = true;
        this.quantityErrorMsg = '正しい数値を入力してください'
        this.enableAsk = false;
        return;
      }
      if(this.opts.numberOfCard < qt){
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
      const {quantity, price, wei} = this.refs;
      if(quantity.value && this.wei){
        try {
          await this.opts.ask(+quantity.value, this.wei.toNumber());
          quantity.value = price.value =  wei.value = '';
          this.wei = null;
          this.checkAskForm();
          this.update();
        } catch (e) {
          return;
        }
      }
    }

    /**
     * 行を選択
     */
    selectRow(e){
      if(e.item.o.from === this.user.etherAccount.toLowerCase()){
        return;
      }
      this.opts.askInfo.map((s, i) => s.selected = i === e.item.i);
      this.opts.selectAsk(e);
      this.update();
    }

    async acceptAsk(){
      try {
        await this.opts.acceptAsk();
        // チェックをリセット
        this.opts.askInfo.map((s, i) => s.selected = false);
        this.opts.selectAsk(null);
        this.update();
      } catch (e) {
        // noop
      }
    }
