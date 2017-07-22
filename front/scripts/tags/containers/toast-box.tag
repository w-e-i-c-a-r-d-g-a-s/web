toast-box
  .toasts.container
    .columns
      .column.col-5
      .column.col-7.col-sm-12
        .toast(each="{q in opts.queue}"
          class="{'toast-success': q.type == 'success', 'toast-error': q.type=='error'}"
        )
          button.btn.btn-clear.float-right(onclick="{close}")
          span {q.text}

  script.
    const ttl = 10000;
    this._queue = [];

    this.on('updated', () => {
      // 自動でトースターを消滅する
      if(this.opts.queue.length > this._queue.length){
        this.opts.queue.forEach((q, i) => {
          if(!q.fade && !q.fadeOut){
            q.fade = (n) => {
              ((_q) => {
                setTimeout(() => {
                  this.deleteQueue(_q);
                }, ttl);
              })(q);
            };
            q.fade(i);
          }
        });
        this._queue = this.opts.queue.slice(0);
      }
    });

    /**
     * 閉じるボタンを押下
     * @param {event} e イベント
     */
    close(e){
      this.deleteQueue(e.item.q);
    }

    /**
     * 指定のキューを削除
     * @param {object} q キューデータ
     */
    deleteQueue(q){
      _.remove(this.opts.queue, q);
      this._queue = this.opts.queue.slice(0);
      this.update();
    }
