detail
  .container.page.page-detail
    .columns
      .column.col-xs-12.col-sm-12.col-md-12.col-lg-4.col-xl-3
        .columns
          .column.col-12.col-xs-12.col-sm-6.col-md-5
            card-detail(card="{opts.card}")
          .column.col-12.col-xs-12.col-sm-6.col-md-7
            card-owners(card="{opts.card}")

      .column.col-xs-12.col-sm-12.col-md-12.col-lg-8.col-xl-9
        .columns
          .column.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-4
            .panel
              .panel-header
                .panel-title Sell Order
              .panel-body
                form
                  .form-group
                    label.form-label(for="input-quantity") quantity
                    input#input-quantity.form-input.input-sm(type="number" placeholder="" ref="quantity")
                    label.form-label(for="input-price") price(eth)
                    .input-group
                      input#input-price.form-input.input-sm(type="text" placeholder="" oninput="{changePrice}" ref="price")
                      span.input-group-addon.addon-sm Ether
                    label.form-label
                    .input-group
                      input.form-input.input-sm(type="text" disabled ref="wei" value="{new Intl.NumberFormat().format(wei)}")
                      span.input-group-addon.addon-sm Wei
              .panel-footer
                button.btn.btn-primary.btn-sm(onclick="{sell}") Sell
          .column.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-8
            h5.inline-block.text-normal Sell Info
            button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshSellInfo}")
              i.icon.icon-refresh
            table.table.table-striped.table-hover
              tr
                th
                th id
                th from
                th quantity
                th price
                th total price
              tr(each="{o, i in opts.card.sellInfo}" onclick="{selectRow}")
                td
                  input(
                    type="radio"
                    name="sell"
                    value="{i}"
                    checked="{o.selected}"
                    onchange="{parent.opts.selectSell}"
                    if="{o.from !== parent.opts.user.etherAccount.toLowerCase()}"
                  )
                td {o.id}
                td
                  .tile.tile-centered
                    .tile-icon
                      img.avatar.avatar-sm(src="{ firebase.addressToPhotoUrl[o.from] }")
                    .tile-content.inline-block.text-ellipsis.addr {o.from}
                td {o.quantity}
                td
                  | {o.priceEth} Ether
                  br
                  | ({o.price} Wei)
                td {o.totalPriceEth} Ether
            .column.col-12(if="{opts.card.sellInfo.length > 0}")
              button.btn.btn-sm.btn-primary(onclick="{opts.buy}") Buy
        .columns
          .column.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-4
            .panel
              .panel-header
                .panel-title Buy Order(このカードを買う）
              .panel-body
                form
                  .form-group
                    label.form-label(for="input-buy-quantity") quantity
                    input#input-buy-quantity.form-input.input-sm(
                      type="number" placeholder="" ref="buyQuantity"
                    )
                    label.form-label(for="input-buy-price") price(eth)
                    .input-group
                      input#input-buy-price.form-input.input-sm(type="text" placeholder="" oninput="{changePriceBuy}" ref="buyPrice")
                      span.input-group-addon.addon-sm Ether
                    label.form-label
                    .input-group
                      input.form-input.input-sm(
                        type="text" disabled ref="buyWei" value="{new Intl.NumberFormat().format(buyWei)}"
                      )
                      span.input-group-addon.addon-sm Wei
              .panel-footer
                button.btn.btn-primary.btn-sm(onclick="{buyOrder}") BuyOrder
          .column.col-xs-12.col-sm-12.col-md-12.col-lg-12.col-xl-8
            h5.inline-block.text-normal BuyOrder Info
            button.btn.btn-primary.btn-action.btn-sm.float-right(onclick="{opts.refreshBuyorderInfo}")
              i.icon.icon-refresh
            table.table.table-striped.table-hover
              tr
                th
                th id
                th buyer
                th quantity
                th price
                th total price
              tr(each="{o, i in opts.card.buyOrderInfo}" onclick="{selectBuyOrderRow}")
                td
                  input(
                    type="radio"
                    name="sell"
                    value="{i}"
                    checked="{o.selected}"
                    onchange="{parent.opts.selectSell}"
                    if="{o.buyer !== parent.opts.user.etherAccount.toLowerCase()}"
                  )
                td {i}
                td
                  .tile.tile-centered
                    .tile-icon
                      img.avatar.avatar-sm(src="{ firebase.addressToPhotoUrl[o.buyer] }")
                    .tile-content.inline-block.text-ellipsis.addr {o.buyer}
                td {o.quantity}
                td
                  | {o.priceEth} Ether
                  br
                  | ({o.price} Wei)
                td {o.totalPriceEth} Ether
            .columns(if="{opts.card.buyOrderInfo.length > 0}")
              .column.col-11
                label.form-label(for="input-buyorder-quantity") quantity
                input#input-buyorder-quantity.form-input.input-sm(
                  type="number" placeholder="" ref="buyOrderQuantity"
                )
              .column.col-1
                label.form-label &nbsp;
                button.btn.btn-sm.btn-primary(onclick="{acceptBid}") Sell
  script.
    changePrice(e){
      this.wei = this.web3c.web3.toWei(e.target.value, 'ether')
    }

    changePriceBuy(e){
      this.buyEther = e.target.value;
      this.buyWei = this.web3c.web3.toWei(e.target.value, 'ether')
    }

    sell(e){
      e.preventDefault();
      const {quantity} = this.refs;
      this.opts.sell(quantity.value, this.wei);
    }

    selectRow(e){
      this.opts.card.sellInfo.map((s, i) => s.selected = i === e.item.i);
      this.opts.selectSell(e);
      this.update();
    }

    selectBuyOrderRow(e){
      this.opts.card.buyOrderInfo.map((s, i) => s.selected = i === e.item.i);
      this.opts.selectBuyorder(e);
      this.update();
    }

    buyOrder(){
      const { buyQuantity } = this.refs;
      if(buyQuantity.value && this.buyEther && this.buyEther > 0){
        // console.log(buyQuantity.value, this.buyEther);
        this.opts.buyOrder(buyQuantity.value, this.buyEther);
      }
    }

    acceptBid(){
      const { buyOrderQuantity } = this.refs;
      if(buyOrderQuantity.value){
        this.opts.acceptBid(buyOrderQuantity.value);
      }
    }
