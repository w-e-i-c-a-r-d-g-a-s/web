mycards
  .page.container
    .columns.mt-2
      .column.col-12(if="{myCards.length > 0}")
        card(each="{card in myCards}" card="{card}" go-detail="{opts.goDetail}")
      .column.col-12(if="{myCards.length === 0}")
        .empty
          .empty-icon
            i.icon.icon-photo(style="font-size: 3rem;")
          h4.empty-title 所有しているカードはありません

  script.
    this.myCards = [];
    this.on('mount', () => {
      this.myCards = this.web3c.getCards(this.user.etherAccount);
      this.update();
      this.myCards.forEach(async (c) => {
        const cardData = await this.firebase.getCard(c.imageHash);
        if(cardData){
          c.imageUrl = cardData.url;
        }
        this.update();
      });
    });
