mycards
  .page.container
    .columns
      .column.col-12
        card(each="{card in myCards}" card="{card}" go-detail="{opts.goDetail}")
  script.
    this.myCards = [];
    this.on('mount', () => {
      this.myCards = this.web3c.getCards(this.opts.user.etherAccount);
      this.update();
    });
