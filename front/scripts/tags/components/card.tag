card
  .card.inline-block.td-card(onclick="{goDetail}" class="{'-single': opts.single}")
    .card-header
      .card-title {opts.card.name}
      .card-subtitle.text-ellipsis {opts.card.address}
    .card-image
      img.img-responsive(src='https://cdn-images-1.medium.com/max/720/0*52_QQpw7YGDelBvo.')
    .card-body
      dl
        dt 発行枚数
        dd {opts.card.issued}
      dl
        dt 作成者
        dd
          .text-ellipsis
            .tile.tile-centered
              .tile-icon
                img.avatar.avatar-sm(src="{ firebase.addressToPhotoUrl[opts.card.author] }")
              .tile-content.inline-block.text-ellipsis.addr {opts.card.author}
    .card-footer

  script.
    goDetail(e){
      this.parent.opts.goDetail(e.item.card.address);
    }
