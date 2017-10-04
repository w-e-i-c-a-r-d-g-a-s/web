card-accept
  .columns.mt-2
    .column.col-1
      .form-group
        label.form-label.text-right(for="input-ask-price") 金額
    .column.col-3
      .form-group
        .input-group
          input#input-ask-quantity.form-input.text-right(
            type="text"
            disabled
            ref="askPrice"
            value="{opts.price}"
          )
          span.input-group-addon Ether
    .column.col-3
      .form-group
        .input-group
          span.input-group-addon 約
          input.form-input.text-right(
            type="text"
            disabled
            ref="bidWei"
            value="{jpy}"
          )
          span.input-group-addon 円
    .column.col-1
      .form-group
        label.form-label.text-right(for="input-ask-quantity") 枚数
    .column.col-2
      .form-group(class="{'has-error': opts.errorMsg }")
        input#input-ask-quantity.form-input(
          type="number"
          min="0"
          ref="askQuantity"
          oninput="{opts.onInputNum}"
        )
        p.form-input-hint {opts.errorMsg}
    .column.col-2
      .form-group
        button.btn.btn-primary.btn-block(onclick="{opts.accept}" disabled="{!opts.enableAcceptAsk}") {opts.buttonText}

  script.
    this.jpy = 0;
    this.enableAcceptAsk = false;
    this.on('update', () => {
      this.jpy = (this.opts.etherJpy * opts.price).toFixed(2);
    });

    /**
     * 数量にfocusを入れる
     */
    focusQt(){
      this.refs.askQuantity.focus();
    }
