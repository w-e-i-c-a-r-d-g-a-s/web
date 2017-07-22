card-bid
  .panel
    .panel-header
      .panel-title
        | カードを売りたい
        button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshBidInfo}")
          i.icon.icon-refresh
    .panel-body
      .columns
        .column.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-4
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
                  )
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
        .column.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-8
          h5.inline-block.text-normal 売り注文一覧
          table.table.table-striped.table-hover
            tr
              th
              th 売り手
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
                  if="{o.from !== parent.opts.user.etherAccount.toLowerCase()}"
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
      this.enableBid = this.refs.quantity.value && this.refs.quantity.value > 0 && this.wei;
    }

    /**
     * 売り注文(bid)を発行
     */
    bid(e){
      e.preventDefault();
      const {quantity, price} = this.refs;
      if(quantity.value && this.wei){
        this.opts.bid(+quantity.value, this.wei.toNumber());
        quantity.value = '';
        price.value = '';
        this.wei = null;
        this.checkBidForm();
      }
    }

    /**
     * 行を選択
     */
    selectRow(e){
      if(e.item.o.from === this.opts.user.etherAccount.toLowerCase()){
        return;
      }
      this.opts.bidInfo.map((s, i) => s.selected = i === e.item.i);
      this.opts.selectBid(e);
      this.update();
    }

    acceptBid(){
      this.opts.acceptBid();
      // チェックをリセット
      this.opts.bidInfo.map((s, i) => s.selected = false);
      this.opts.selectBid(null);
      this.update();
    }
