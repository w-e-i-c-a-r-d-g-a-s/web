card
  .card.inline-block.td-card(onclick="{goDetail}" class="{'-single': opts.single}")
    .card-image
      img.img-fit-cover.image(if="{opts.card.imageUrl}" src="{opts.card.imageUrl}")
      .image.loading(if="{!opts.card.imageUrl}")
    .card-header
      .card-title {opts.card.name}
      .card-subtitle.text-ellipsis {opts.card.address}
    .card-body
      .columns
        .column.col-4 発行枚数
        .column.col-8 {opts.card.totalSupply}
      .columns
        .column.col-4 作成者
        .column.col-8
          .tile.tile-centered
            .tile-icon
              img.avatar.avatar-sm(src="{ firebase.addressToPhotoUrl[opts.card.author] }")
            .tile-content.inline-block.text-ellipsis.addr {opts.card.author}
  script.
    goDetail(){
      if(this.opts.single){
        return;
      }
      location.href = '#/cards/' + this.opts.card.address;
    }
