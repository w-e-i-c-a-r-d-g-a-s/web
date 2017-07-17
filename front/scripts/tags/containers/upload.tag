upload
  .page.container
    h4 Upload
    .columns
      .column.col-4
        .input-group
          input.form-input.input-sm(type="text" ref="cardName" placeholder="cardname")
          input.form-input.input-sm(type="number" ref="totalSupply" placeholder="10")
          button.btn.btn-sm(onclick="{addCard}") Publish Card
  script.
    addCard(){
      const { cardName, totalSupply } = this.refs;
      if(cardName.value && totalSupply.value){
        this.opts.addCard(cardName.value, totalSupply.value);
      }
    }
