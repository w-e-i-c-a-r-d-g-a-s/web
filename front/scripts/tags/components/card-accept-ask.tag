card-accept-ask
  .columns.mt-2
    .column.col-1
      .form-group
        labelform-label.label-sm.text-right(for="input-ask-price") 金額
    .column.col-3
      .form-group
        .input-group
          input#input-ask-quantity.form-input.input-sm.text-right(
            type="text"
            disabled
            ref="askPrice"
            value="{opts.price}"
          )
          span.input-group-addon.addon-sm Ether
    .column.col-3
      .form-group
        .input-group
          span.input-group-addon.addon-sm 約
          input.form-input.input-sm.text-right(
            type="text"
            disabled
            ref="bidWei"
            value="{jpy}"
          )
          span.input-group-addon.addon-sm 円
    .column.col-1
      .form-group
        label.form-label.label-sm.text-right(for="input-ask-quantity") 枚数
    .column.col-2
      .form-group(class="{'has-error': opts.errorMsg }")
        input#input-ask-quantity.form-input.input-sm(
          type="number"
          min="0"
          ref="askQuantity"
          oninput="{opts.onInputNum}"
        )
        p.form-input-hint {opts.errorMsg}
    .column.col-2
      .form-group
        button.btn.btn-sm.btn-primary.btn-block(onclick="{opts.accept}" disabled="{!opts.enableAcceptAsk}") {opts.buttonText}

  script.
    this.jpy = 0;
    this.enableAcceptAsk = false;
    this.on('update', () => {
      this.jpy = (this.opts.etherJpy * opts.price).toFixed(2);
    });
