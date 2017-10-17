home
  .page.container
    .columns.mt-2
      h4 直近取引されたカード
      .column.col-12.loading(if="{isLoading}")
      .column.col-12(if="{cards.length > 0}")
        .my-cards(each="{card in cards}")
          card(card="{card}")
          .detail.text-break(style="width: 300px")
            .columns
              .column.col-12
                | {card.time}に
                price(val="{(+card.latestTradePrice)}" unit="wei")
                | で取引されました

      .column.col-12(if="{!isLoading && cards.length === 0}")
        .empty
          .empty-icon
            i.icon.icon-photo(style="font-size: 3rem;")
          h4.empty-title カードがありません
  script.
    this.isLoading = true;
    this.cards = [];

    const formatTime = (d) => {
      const _date = `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()}`;
      const _time = `${d.getHours()}:${d.getMinutes()}`;
      return `${_date} ${_time}`;
    };

    this.on('mount', async () => {
      // 直近取引されたカード
      const latestTradeCards = await this.firebase.getLatestTradeCards();
      if(!latestTradeCards){
        this.isLoading = false;
        this.update();
        return;
      }
      const cardAddresses = Object.keys(latestTradeCards);
      const promises = cardAddresses.map((c) => {
        return new Promise(async (resolve, reject) => {
          const card = this.web3c.getCard(c);
          const {marketPrice, time} = latestTradeCards[c];
          card.latestTradePrice = marketPrice;
          card.time = formatTime(new Date(time));
          const cardData = await this.firebase.getCard(card.imageHash);
          if(cardData){
            card.imageUrl = cardData.url;
          }
          resolve(card);
        });
      });

      Promise.all(promises).then((cards) => {
        this.cards = cards;
        this.isLoading = false;
        this.update();
      });
    });
