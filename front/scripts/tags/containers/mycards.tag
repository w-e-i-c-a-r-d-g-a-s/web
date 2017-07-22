mycards
  .page.container
    .columns
      .column.col-xs-12.col-sm-6.col-md-6.col-lg-4.col-xl-3(each="{card in myCards}")
        card(card="{card}" go-detail="{opts.goDetail}")
  script.
    this.myCards = [];
    this.on('mount', () => {
      this.myCards = this.web3c.getCards(this.opts.user.etherAccount);
      this.update();
    });
