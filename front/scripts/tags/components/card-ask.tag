card-ask
  .panel.mt-2
    .panel-header
      .panel-title
        | カードを買う
        // button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshAskInfo}")
          // i.icon.icon-refresh
    .panel-body
      .columns
        .column.col-9
          h5.inline-block.text-normal 出品中のカード
          .empty(if="{opts.askInfo && opts.askInfo.length === 0}")
            .empty-icon
              i.icon.icon-message(style="font-size: 3rem")
            h4.empty-title 現在売り注文はありません
          table.table.table-striped.table-hover(if="{opts.askInfo.length > 0}")
            tr
              th
              th
              th 販売価格
              th.text-right 枚数
            tr(each="{o, i in opts.askInfo}" onclick="{selectRow}")
              td
                input(
                  type="radio"
                  name="askrow"
                  value="{i}"
                  checked="{o.selected}"
                  onchange="{parent.opts.selectAsk}"
                )
              td
                small.bg-success.text-light.p-1.rounded(show="{i === 0}") 最安値!
              td.tooltip(data-tooltip="{o.price} Wei")
                price(val="{o.price}" unit="wei")
              td.text-right {o.quantity}
          card-accept-ask(
            if="{opts.askInfo.length > 0}"
            accept="{acceptAsk}"
            ether-jpy="{opts.etherJpy}"
            on-input-num="{checkAcceptAsk}"
            enable-accept-ask="{enableAcceptAsk}"
            error-msg="{errorMsg}"
            price="{this.selectedAskPriceEth}"
            button-text="購入する"
          )
    .panel-footer

  script.
    this.errorMsg = '';
    this.selectedAskPriceEth = 0;
    this.enableAcceptAsk = false;
    this.askQuantity = 0;

    /**
     * 行を選択
     */
    selectRow(e){
      this.opts.askInfo.map((s, i) => s.selected = i === e.item.i);
      const selectedAsk = opts.askInfo[e.item.i]
      this.selectedAskPriceEth = selectedAsk.priceEth;
      this.checkAcceptAsk(this.askQuantity);
      this.update();
    }

    checkAcceptAsk(inputQt = 0){
      if(!inputQt){
        return;
      }
      this.askQuantity = inputQt;
      for(let i = 0, len = opts.askInfo.length; i < len; i++){
        const ask = opts.askInfo[i];
        // 同一の金額があるかどうか
        if(ask.priceEth === this.selectedAskPriceEth){
          if(this.askQuantity > 0){
            if(this.askQuantity <= ask.quantity){
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

    async acceptAsk(){
      try {
        await this.opts.acceptAsk(this.selectedAsk, this.askQuantity);
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


