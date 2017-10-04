card-ask
  // h5.inline-block.text-normal 出品中のカード
  .empty(if="{opts.askInfo && opts.askInfo.length === 0}")
    .empty-icon
      i.icon.icon-message(style="font-size: 3rem")
    h4.empty-title 現在出品中のカードがありません
  table.table.table-striped.table-hover(if="{opts.askInfo.length > 0}")
    tr
      th
      th
      th 販売価格
      th.text-right 枚数
    tr(each="{o, i in opts.askInfo}" onclick="{onClickRow}")
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
  card-accept(
    if="{opts.askInfo.length > 0}"
    accept="{acceptAsk}"
    ether-jpy="{opts.etherJpy}"
    on-input-num="{onChangeeAcceptAskQt}"
    enable-accept-ask="{enableAcceptAsk}"
    error-msg="{errorMsg}"
    price="{this.selectedAskPriceEth}"
    button-text="購入する"
    ref="cardAcceptAsk"
  )

  script.
    this.errorMsg = '';
    this.selectedAskPriceEth = 0;
    this.enableAcceptAsk = false;
    this.askQuantity = 0;

    /**
     * 行をクリック
     */
    onClickRow(e){
      this.selectRow(e.item.i);
    }

    /**
     * 行を選択
     */
    selectRow(idx){
      this.opts.askInfo.map((s, i) => s.selected = i === idx);
      const selectedAsk = opts.askInfo[idx];
      this.selectedAskPrice = selectedAsk.price;
      this.selectedAskPriceEth = selectedAsk.priceEth;
      this.checkAcceptAsk();
      this.update();
    }

    /**
     * 数量にfocusを入れる
     */
    focusQt(){
      this.refs.cardAcceptAsk.focusQt();
    }

    onChangeeAcceptAskQt(e){
      const qt = _.toNumber(e.target.value);
      this.askQuantity = qt;
      if(!qt){
        this.errorMsg = '';
        this.enableAcceptAsk = false;
        return;
      }
      this.checkAcceptAsk();
    }

    checkAcceptAsk(){
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
        await this.opts.acceptAsk(this.selectedAskPrice, this.askQuantity);
        this.update();
      } catch (e) {
        // noop
      }
    }



