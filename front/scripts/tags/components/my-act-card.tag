my-act-card
  .columns.mt-2(if="{askInfo.length > 0 || bidInfo.length > 0}")
    .column.col-4
      .my-cards
        card-sm(card="{opts.card}")
    .column.col-8
      div(if="{askInfo.length > 0}")
        h6 出品中のカード
        table.table.table-striped.table-hover.mt-2
          tr
            th 販売価格
            th.text-right 枚数
            th
          tr(each="{o, i in askInfo}")
            td.tooltip(data-tooltip="{o.price} Wei")
              price(val="{o.price}" unit="wei")
            td.text-right {o.quantity}
            td
              button.btn.btn-sm(onclick="{cancelAsk}") 取消
      div(if="{bidInfo.length > 0}")
        h6 買い注文中のカード
        table.table.table-striped.table-hover.mt-2
          tr
            th 販売価格
            th.text-right 枚数
            th
          tr(each="{o, i in bidInfo}")
            td.tooltip(data-tooltip="{o.price} Wei")
              price(val="{o.price}" unit="wei")
            td.text-right {o.quantity}
            td
              button.btn.btn-sm(onclick="{cancelBid}") 取消
  script.
    this.askInfo = [];
    this.bidInfo = [];

    this.on('mount', () => {
      const cardAddress = opts.card.address;
      const userAccount = this.user.etherAccount;
      this.askInfo = this.web3c.getOwnAskInfos(cardAddress, userAccount);
      this.bidInfo = this.web3c.getOwnBidInfos(cardAddress, userAccount);
      this.update();
    });

    cancelAsk(e){
      console.log(e.item.o);
    }

    cancelBid(e){
      const { price } = e.item.o;
      this.opts.cancelBid(this.opts.card.address, price);
    }
