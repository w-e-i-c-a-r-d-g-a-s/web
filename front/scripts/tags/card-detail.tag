card-detail
  .card.inline-block.td-card.-no-hover
    .card-image
      img.img-responsive(src='http://kryptomoney.com/wp-content/uploads/2017/06/ethereum-logo.png')
      .card-header
        h4.card-title {opts.card.name}
        h6.card-subtitle 発行枚数： {opts.card.issued}
      .card-body
        span.desc {opts.card.address}

