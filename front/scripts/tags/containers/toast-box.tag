toast-box
  .toasts
    .toast(each="{q in opts.queue}"
      class="{'toast-success': q.type == 'success', 'toast-error': q.type=='error'}"
    )
      button.btn.btn-clear.float-right
      | {q.text}

  script.
    this._queue = [];

    this.on('updated', () => {
      if(this.opts.queue.length > this._queue.length){
        this.opts.queue.forEach((q, i) => {
          if(!q.fade && !q.fadeOut){
            q.fade = (n) => {
              ((_q) => {
                setTimeout(() => {
                  this.opts.queue.shift();
                  this._queue = this.opts.queue.slice(0);
                  this.update();
                }, 5000);
              })(q);
            };
            q.fade(i);
          }
        });
        this._queue = this.opts.queue.slice(0);
      }
    });
