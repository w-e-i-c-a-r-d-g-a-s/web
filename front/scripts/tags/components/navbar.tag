navbar
  header.navbar
    section.navbar-section
      .dropdown.show-md
        a.btn.btn-link.dropdown-toggle(tabindex='0')
          i.icon.icon-menu
        ul.menu
          li.menu-item
            a(href="#/") Home
          li.menu-item
            a(href="#/mycards") My Cards
          li.menu-item
            a(href="#/upload") Upload
          li.menu-item
            a(href="#/admin") Admin
          li.menu-item
            a(href="#/setting") Setting
          li.menu-item
            a(href="#" onclick="{logout}") Logout
      .hide-md
        a.btn.btn-link(href="#/") Home
        a.btn.btn-link(href="#/mycards") My Cards
        a.btn.btn-link(href="#/upload") Upload
    section.navbar-center
      figure.avatar.avatar-l
        a(href="#/mycards")
          img(src="{user.photoURL}")
      span.info.hide-xs
        span.text-lowercase {user.etherAccount}
        br
        span {user.eth} Ether
    section.navbar-section
      .hide-md
        span(style="position: relative")
          a.btn.btn-link.badge(data-badge="{badgeNum}" onclick="{toggleNotification}") Notifications
          .panel.notifications(ref="notifications" show="{isShowNotification}")
            .panel-header
              .panel-title Notifications
            .panel-body
              .divider(data-content="Card Master")
              .tile.centered(show="{infos.length === 0}")
                .loading
              .tile(each="{ info in infos }")
                .tile-icon
                  figure.avatar
                    img(src="{info.card.url}")
                .tile-content
                  .tile-title カード発行
                  .tile-subtitle
                    | {info.from.slice(0, 10)}...が「
                    a(href="#") {info.inputArgs[0]}
                    | 」を{ info.inputArgs[1] } 枚発行しました。
              .divider(data-content="Card")
              .tile.centered(show="{notifies.length === 0}")
                .loading
              .tile(each="{ notify in notifies}")
                .tile-icon
                  figure.avatar
                    img(src="{notify.card.url}")
                .tile-content
                  .tile-title カード取引
                  .tile-subtitle
                    | {notify.from.slice(0, 10)}...が「
                    a(href="#/cards/{notify.cardInfo.address}") {notify.cardInfo.name}
                    | 」を{ notify.methodName } しました。
            .panel-footer
        a.btn.btn-link(href="#/admin") Admin
        a.btn.btn-link(href="#/setting") Setting
        button.btn.btn-link(onclick="{logout}") Logout
  script.
    this.isShowNotification = false;
    this.infos = [];
    this.notifies = [];

    this.on('mount', () => {
      this.firebase.getNotificationCount().then((num) => {
        this.badgeNum = num;
        this.update();
      });
    });

    // お知らせ表示
    toggleNotification(){
      this.isShowNotification = !this.isShowNotification;
      if(this.isShowNotification){
        // お知らせ取得
        this.firebase.getHistories().then((data) => {
          Promise.all(data.map((d) => this.firebase.getCard(d.inputArgs[2])))
          .then((res) => {
            data.forEach((d, i) => {
              d.card = res[i];
            });
            this.infos = data;
            this.update();
          });
        });
        this.firebase.getNotifications().then((data) => {
          // アドレスからカード情報を取得
          data.forEach((d) => {
            d.cardInfo = this.web3c.getCard(d.to);
            d.methodName = d.inputMethod.match(/(.+)\(/)[1];
          });
          Promise.all(data.map((d) => this.firebase.getCard(d.cardInfo.imageHash)))
            .then((res) => {
              data.forEach((d, i) => {
                d.card = res[i];
              });
              console.log(data);
              this.notifies = data;
              this.update();
            });
        });
      } else {
        this.infos = [];
        this.notifies = [];
      }
    }

    /**
     * ログアウト処理
     */
    logout(e){
      e.preventDefault();
      this.firebase.logout().then(() => {
        location.reload();
      });
    }
