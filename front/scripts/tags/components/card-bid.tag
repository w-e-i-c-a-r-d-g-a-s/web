card-bid
  .panel.mt-2
    .panel-header
      .panel-title
        | カード買い板
        // button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshBidInfo}")
          // i.icon.icon-refresh
    .panel-body
      .columns
        .column.col-12
          h5.inline-block.text-normal カード買い板
          .empty(if="{opts.bidInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在買い注文はありません
          table.table.table-striped.table-hover(if="{opts.bidInfo.length > 0}")
            tr
              th
              th
              th 販売価格
              th.text-right 枚数
            tr(each="{o, i in opts.bidInfo}" onclick="{selectRow}")
              td
                input(
                  type="radio"
                  name="sell"
                  value="{i}"
                  checked="{o.selected}"
                  onchange="{parent.opts.selectSell}"
                )
              td
                small.bg-success.text-light.p-1.rounded(show="{i === 0}") 最高値!
              td.tooltip(data-tooltip="{o.price} Wei")
                price(val="{o.price}" unit="wei")
              td.text-right {o.quantity}
          card-accept-ask(
            if="{opts.bidInfo.length > 0}"
            accept="{acceptBid}"
            ether-jpy="{opts.etherJpy}"
            on-input-num="{onChangeeAcceptBidQt}"
            enable-accept-ask="{enableAcceptBid}"
            error-msg="{errorMsg}"
            price="{this.selectedBidPriceEth}"
            button-text="売却する"
          )

    .panel-footer

  script.
    this.bidQuantity = 0;
    this.selectedBidPriceEth = 0;
    this.enableAcceptBid = false;
    this.errorMsg = '';

    /**
     * 買い注文を選択
     */
    selectRow(e){
      this.opts.bidInfo.map((s, i) => s.selected = i === e.item.i);
      const selectedBid = opts.bidInfo[e.item.i];
      this.selectedBidPrice = selectedBid.price;
      this.selectedBidPriceEth = selectedBid.priceEth;
      this.checkAcceptBid(this.bidQuantity);
      this.update();
    }

    onChangeeAcceptBidQt(e){
      const qt = _.toNumber(e.target.value);
      this.bidQuantity = qt;
      if(!qt){
        this.errorMsg = '';
        this.enableAcceptBid = false;
        return;
      }
      this.checkAcceptBid();
    }

    checkAcceptBid(){
      for(let i = 0, len = opts.bidInfo.length; i < len; i++){
        const bid = opts.bidInfo[i];
        // 同一の金額があるかどうか
        if(bid.priceEth === this.selectedBidPriceEth){
          if(this.bidQuantity > 0){
            if(this.bidQuantity <= bid.quantity){
              this.errorMsg = '';
              this.enableAcceptBid = true;
              this.selectedBid = bid;
              return;
            }else{
              this.errorMsg = '枚数が販売枚数より多いです';
              this.enableAcceptBid = false;
              this.selectedBid = null;
            }
          }
          break;
        }
        this.enableAcceptBid = false;
        this.selectedBid = null;
      }
    }

    async acceptBid(){
      try {
        await this.opts.acceptBid(this.selectedBidPrice, this.bidQuantity);
        // チェック、入力をリセット
        this.bidQuantity = '';
        this.opts.bidInfo.map((s, i) => s.selected = false);
        this.update();
      } catch(e) {
        return;
      }
    }

    async cancelBid(e){
      try {
        await this.opts.cancelBid(e.item.i);
        this.update();
      } catch(e) {
        console.error(e, 'fail: cancelBid');
      }
    }
