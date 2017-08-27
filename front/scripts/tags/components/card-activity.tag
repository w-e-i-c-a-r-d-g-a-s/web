card-activity
  .panel.mt-2
    .panel-header
      .panel-title
        | Card Activity
      .panel-body
        table.table.table-striped.table-hover
          thead
            tr
              th 時刻
              th イベント
          tbody
            tr(each="{act in opts.activities}")
              td {(new Date(+act.timestamp * 1000)).toLocaleString("ja")}
              td
                span.label.label-success.mx-1(if="{act.isDeal}") 売買
                span.label.mx-1(if="{!act.isDeal}") 発行
                | {act.text}
      .panel-footer
