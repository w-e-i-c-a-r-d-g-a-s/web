card-tags
  .panel.mt-2
    .panel-header
      .panel-title.h5 Card Tags
    .panel-body
      a.chip(href="#/tags/{tag}" each="{tag in card.tags}") {tag}
    .panel-footer

