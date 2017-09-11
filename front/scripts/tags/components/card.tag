card
  .card.d-inline-block.td-card(onclick="{goDetail}" class="{'-single': opts.single}")
    .card-image
      img.img-fit-cover.image(if="{opts.card.imageUrl}" src="{opts.card.imageUrl}")
      .image.loading(if="{!opts.card.imageUrl}")
    .card-header
      img.avatar.avatar-md.float-right(src="{ firebase.addressToPhotoUrl[opts.card.author] }")
      .card-title.h5 {opts.card.name}
      .card-subtitle.text-ellipsis.text-gray {opts.card.address}
    .card-body
      .columns
        .column.col-4 発行枚数
        .column.col-8 {opts.card.totalSupply}
      .columns
        .column.col-4 最安値
        .column.col-8
          price(val="{opts.card.currentMarketPrice}" unit="ether" linebreak="true")

  script.
    goDetail(){
      if(this.opts.single){
        return;
      }
      location.href = '#/cards/' + this.opts.card.address;
    }
