card-bid
  .panel.mb-10
    .panel-header
      .panel-title
        | カードを売りたい
        button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshBidInfo}")
          i.icon.icon-refresh
    .panel-body
      .empty(if="{opts.numberOfCard === 0}")
        .empty-icon
          i.icon.icon-message(style="font-size: 3rem")
        h4.empty-title カードを所有していません
      .columns(if="{opts.numberOfCard > 0}")
        .column.col-3.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-4
          .panel
            .panel-header
              .panel-title 売り注文
            .panel-body
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
            .panel-footer
              button.btn.btn-primary.btn-sm(onclick="{bid}" disabled="{!enableBid}") 売る
        .column.col-9.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-8
          h5.inline-block.text-normal 売り注文一覧
          .empty(if="{opts.bidInfo && opts.bidInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在売り注文はありません
          table.table.table-striped.table-hover(if="{opts.bidInfo.length > 0}")
            tr
              th
              th 売却者
              th 枚数
              th 一枚あたりの価格
              th 総価格
            tr(each="{o, i in opts.bidInfo}" onclick="{selectRow}")
              td
                input(
                  type="radio"
                  name="bidrow"
                  value="{i}"
                  checked="{o.selected}"
                  onchange="{parent.opts.selectBid}"
                  if="{o.from !== parent.user.etherAccount.toLowerCase()}"
                )
              td
                .tile.tile-centered
                  .tile-icon
                    img.avatar.avatar-sm(src="{ firebase.addressToPhotoUrl[o.from] }")
                  .tile-content.inline-block.text-ellipsis.addr {o.from}
              td {o.quantity}
              td.tooltip(data-tooltip="{o.price} Wei") {o.priceEth} Ether
              td.tooltip(data-tooltip="{o.totalPrice} Wei") {o.totalPriceEth} Ether
          .columns.col-gapless
            .column.col-12(if="{opts.bidInfo.length > 0}")
              button.btn.btn-sm.btn-primary(
                onclick="{acceptBid}"
                disabled="{!_.isNumber(opts.bidId)}"
              ) 選択したものを購入
    .panel-footer

  script.
    this.wei = null;
    this.enableBid = false;
    this.quantityError = false;
    this.quantityErrorMsg = '';

    /**
     * 枚数を変更
     */
    changeQuantity(){
      this.checkBidForm();
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
      this.checkBidForm();
    }

    /**
     * 入力値チェック
     */
    checkBidForm(){
      const qt = _.toNumber(this.refs.quantity.value);
      if(qt === 0){
        this.quantityError = false;
        this.quantityErrorMsg = ''
        this.enableBid = false;
        return;
      }
      const isValidQt = _.isNumber(qt) && _.isInteger(qt) && qt > 0;
      if(!isValidQt){
        this.quantityError = true;
        this.quantityErrorMsg = '正しい数値を入力してください'
        this.enableBid = false;
        return;
      }
      if(this.opts.numberOfCard < qt){
        this.quantityError = true;
        this.quantityErrorMsg = '所有枚数を超えています'
        this.enableBid = false;
        return;
      }
      this.quantityError = false;
      this.quantityErrorMsg = ''
      this.enableBid = isValidQt && this.wei;
    }

    /**
     * 売り注文(bid)を発行
     */
    async bid(e){
      e.preventDefault();
      const {quantity, price, wei} = this.refs;
      if(quantity.value && this.wei){
        try {
          await this.opts.bid(+quantity.value, this.wei.toNumber());
          quantity.value = price.value =  wei.value = '';
          this.wei = null;
          this.checkBidForm();
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
      this.opts.bidInfo.map((s, i) => s.selected = i === e.item.i);
      this.opts.selectBid(e);
      this.update();
    }

    async acceptBid(){
      try {
        await this.opts.acceptBid();
        // チェックをリセット
        this.opts.bidInfo.map((s, i) => s.selected = false);
        this.opts.selectBid(null);
        this.update();
      } catch (e) {
        // noop
      }
    }
