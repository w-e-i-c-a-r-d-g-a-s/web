card-owners
  .panel
    .panel-header
      .panel-title Card Owners
    .panel-body
      span.block author:
      span.text-break.inline-block.text-ellipsis.addr {opts.card.author}
      table.table.table-striped.table-hover
        tr
          th account
          th num
        tr(each="{o in opts.card.owners}")
          td
            .tile.tile-centered
              .tile-icon
                img.avatar.avatar-sm(src="{ firebase.addressToPhotoUrl[o.address] }")
              .tile-content.inline-block.text-ellipsis.addr {o.address}
          td {o.num}
    .panel-footer
