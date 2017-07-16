detail
  .container.page.page-detail
    .columns
      .column.col-3.text-center
        card-detail(card="{opts.card}")
        p.text-break.text-ellipsis.addr author: {opts.card.author}
      .column.col-9
        .columns
          .column.col-4
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
                      input#input-price.form-input.input-sm(type="text" disabled ref="wei" value="{new Intl.NumberFormat().format(wei)}")
                      span.input-group-addon.addon-sm Wei
              .panel-footer
                button.btn.btn-primary.btn-sm(onclick="{sell}") Sell
          .column.col-8
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
                  )
                td {i}
                td
                  span.inline-block.text-ellipsis.addr {o.from}
                td {o.quantity}
                td
                  | {o.priceEth} Ether
                  br
                  | ({o.price} Wei)
                td {o.totalPriceEth} Ether
            .column.col-12
              button.btn.btn-sm.btn-primary(onclick="{opts.buy}") Buy

  script.
    changePrice(e){
      this.wei = this.web3c.web3.toWei(e.target.value, 'ether')
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
