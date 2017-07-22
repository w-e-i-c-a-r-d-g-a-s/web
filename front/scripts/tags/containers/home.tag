home
  .page.container
    .columns
      .column.col-xs-12.col-sm-6.col-md-6.col-lg-4.col-xl-3(each="{card in opts.cards}")
        card(card="{card}" go-detail="{opts.goDetail}")
