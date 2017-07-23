detail
  .container.page.page-detail
    .columns
      .column.col-2.col-xs-12.col-sm-12.col-md-12.col-lg-4.col-xl-3
        .columns
          .column.col-12.col-xs-12.col-sm-6.col-md-5.col-lg-12.col-xl-12
            card(card="{opts.card}" single="{true}")
          .column.col-12.col-xs-12.col-sm-6.col-md-7.col-lg-12.col-xl-12
            card-owners(card="{opts.card}")

      .column.col-10.col-xs-12.col-sm-12.col-md-12.col-lg-8.col-xl-9
        card-bid(
          accept-bid="{opts.acceptBid}"
          bid="{opts.bid}"
          refresh-bid-info="{opts.refreshBidInfo}"
          bid-info="{opts.card.bidInfo}"
          select-bid="{opts.selectBid}"
          bid-id="{opts.bidId}"
          user="{opts.user}"
        )
        card-ask(
          ask="{opts.ask}"
          refresh-ask-info="{opts.refreshAskInfo}"
          ask-info="{opts.card.askInfo}"
          select-ask="{opts.selectAsk}"
          ask-id="{opts.askId}"
          accept-ask="{opts.acceptAsk}"
          user="{opts.user}"
        )
  script.
    this.on('mount', async () => {
      const cardData = await this.firebase.getCard(this.opts.card.imageHash);
      this.opts.card.imageUrl = cardData.url;
      this.update();
    });
