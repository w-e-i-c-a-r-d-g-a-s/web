card-accept-bid
  .columns.mt-2(if="{opts.bidInfo.length > 0}")
    .column.col-1
      .form-group
        label.form-label.label-sm(for="input-buyorder-quantity") 枚数
    .column.col-10
      .form-group
        input#input-buyorder-quantity.form-input.input-sm(
          type="number" placeholder="" ref="buyOrderQuantity"
        )
    .column.col-1
      .form-group
        button.btn.btn-sm.btn-primary(
          onclick="{acceptBid}"
          disabled="{!_.isNumber(opts.bidId)}"
        ) 売却する
