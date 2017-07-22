home
  .page.container
    .columns
      .column.col-12
        card(each="{card in opts.cards}" card="{card}" go-detail="{opts.goDetail}")
