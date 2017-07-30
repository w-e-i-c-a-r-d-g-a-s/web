toast-box
  .toasts.container
    .columns
      .column.col-5
      .column.col-7.col-sm-12
        .toast(each="{q in queue}"
          class="{'toast-success': q.type == 'success', 'toast-error': q.type=='error'}"
        )
          button.btn.btn-clear.float-right.close(onclick="{close}")
          span {q.text}

  script.
    const ttl = 10000;
    this.queue = [];

    // toast event [SUCCESS]
    opts.obs.on('notifySuccess', ({ text }) => {
      this.notify({
        type: 'success',
        text
      });
    });

    // toast event [ERROR]
    opts.obs.on('notifyError', ({ text }) => {
      this.notify({
        type: 'error',
        text
      });
    });

    // toast event [GENERAL]
    opts.obs.on('notify', ({ text }) => {
      this.notify({
        text
      });
    });


    notify(obj){
      this.queue.push(obj);
      this.update();
      this.queue.forEach((q, i) => {
        if(!q.fade){
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
    }

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
      _.remove(this.queue, q);
      this.update();
    }
