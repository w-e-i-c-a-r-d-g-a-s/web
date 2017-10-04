card-sm
  .card.d-inline-block.td-card.-sm(onclick="{goDetail}" class="{'-single': opts.single}")
    .card-image
      img.img-fit-cover.image(if="{opts.card.imageUrl}" src="{opts.card.imageUrl}")
      .image.loading(if="{!opts.card.imageUrl}")
    .card-header
      .card-title.h6 {opts.card.name}
      .card-subtitle.text-ellipsis.text-gray {opts.card.address}
    .card-body

  script.
    goDetail(){
      if(this.opts.single){
        return;
      }
      location.href = '#/cards/' + this.opts.card.address;
    }
