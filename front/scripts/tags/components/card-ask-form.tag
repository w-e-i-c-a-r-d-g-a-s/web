card-ask-form
  .panel.mt-2
    .panel-header
      .panel-title カードを出品する
    .panel-body(if="{opts.numberOfCard > 0}")
      form(autocomplete="off" role="presentation")
        .columns
          .column.col-2
            .form-group
              label.form-label(for="input-quantity") 枚数
              input#input-quantity.form-input.input-sm(
                type="number"
                oninput="{opts.changeQuantity}"
                class="{'is-error': opts.quantityError}"
                value="{opts.askQuantity}"
              )
              p.form-input-hint {opts.quantityErrorMsg}
          .column.col-4
            .form-group
              label.form-label(for="input-price") 1枚あたりの価格
              .input-group
                input#input-price.form-input.input-sm(
                  type="text"
                  oninput="{opts.changePrice}"
                  value="{opts.askPrice}"
                )
                span.input-group-addon.addon-sm Ether
          .column.col-4
            .form-group
              label.form-label &nbsp;
              .input-group
                span.input-group-addon.addon-sm 約
                input.form-input.input-sm(
                  type="text"
                  disabled
                  value="{opts.jpy}"
                )
                span.input-group-addon.addon-sm 円
          .column.col-2
            .form-group
              label.form-label &nbsp;
              button.btn.btn-primary.btn-sm(
                onclick="{opts.ask}"
                disabled="{!opts.enableAsk}"
              ) 出品する
    .panel-footer(if="{opts.numberOfCard > 0}")

    .panel-body(if="{opts.numberOfCard === 0}")
      .empty
        .empty-icon
          i.icon.icon-message(style="font-size: 3rem")
        h4.empty-title カードを所有していません
    .panel-footer(if="{opts.numberOfCard === 0}")
