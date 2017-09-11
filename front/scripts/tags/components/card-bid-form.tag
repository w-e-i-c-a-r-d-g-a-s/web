card-bid-form
  .panel.mt-2
    .panel-header
      .panel-title カードを売却する
    .panel-body
      form(autocomplete="off" role="presentation")
        .columns
          .column.col-2
            .form-group
              label.form-label(for="input-bid-quantity") 枚数
              input#input-bid-quantity.form-input.input-sm.text-right(
                type="number"
                ref="bidQuantity"
                oninput="{opts.changeBidQuantity}"
                class="{'is-error': opts.quantityError}"
              )
              p.form-input-hint {opts.quantityErrorMsg}
          .column.col-4
            .form-group
              label.form-label(for="input-bid-price") 一枚あたりの価格
              .input-group
                input#input-bid-price.form-input.input-sm.text-right(
                  type="text"
                  ref="bidPrice"
                  oninput="{opts.changeBidPrice}"
                )
                span.input-group-addon.addon-sm Ether
              p.form-input-hint (現状整数のみ入力可)
          .column.col-4
            .form-group
              label.form-label &nbsp;
              .input-group
                span.input-group-addon.addon-sm 約
                input.form-input.input-sm.text-right(
                  type="text"
                  disabled
                  ref="bidWei"
                  value="{opts.jpy}"
                )
                span.input-group-addon.addon-sm 円
          .column.col-1
            label.form-label &nbsp;
            button.btn.btn-primary.btn-sm(onclick="{opts.bid}" disabled="{!opts.enableBid}") 売却する
