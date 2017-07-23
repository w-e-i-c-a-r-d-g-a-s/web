home
  .page.container
    .columns
      .column.col-12(if="{cards.length > 0}")
        card(each="{card in cards}" card="{card}" go-detail="{opts.goDetail}")
      .column.col-12(if="{cards.length === 0}")
        .empty
          .empty-icon
            i.icon.icon-photo(style="font-size: 3rem;")
          h4.empty-title カードがありません
  script.
    this.cards = [];
    this.on('mount', () => {
      this.cards = this.web3c.getCards();
      this.update();
      this.cards.forEach(async (c) => {
        const cardData = await this.firebase.getCard(c.imageHash);
        c.imageUrl = cardData.url;
        this.update();
      });
    });
