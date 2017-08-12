tagpage
  .page.container
    p
      strong {opts.tag}
      | を含むカード
    .columns
      .column.col-12(if="{cards.length > 0}")
        card(each="{card in cards}" card="{card}")
      .column.col-12(if="{cards.length === 0}")
        .empty
          .empty-icon
            i.icon.icon-photo(style="font-size: 3rem;")
          h4.empty-title カードがありません

  script.
    this.cards = [];
    this.on('mount', () => {
      const databaseRef = this.firebase._firebase.database().ref(`tags/${this.opts.tag}`);
      databaseRef.once('value', (sss) => {
        sss.forEach((ss) => {
          this.firebase._firebase.database().ref(`cards/${ss.val()}`)
            .once('value', (s) => {
              // ブロックチェーンからカードデータを取得
              const card = this.web3c.getCardByImageHash(s.key);
              card.imageUrl = s.val().url;
              this.cards.push(card);
              this.update();
            })
        });
      });
    });
