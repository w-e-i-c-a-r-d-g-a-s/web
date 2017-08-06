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
            a(href="#/activity") Activity
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
        a.btn.btn-link(href="#/activity") Activity
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
        span 1ETH = &yen;{etherJPY}
        a.btn.btn-link(href="#/upload") Upload
        a.btn.btn-link(href="#/admin") Admin
        a.btn.btn-link(href="#/setting") Setting
        button.btn.btn-link(onclick="{logout}") Logout
  script.
    this.etherJPY = null;

    opts.obs.on('updateEthPrice', (({ etherJPY }) => {
      this.etherJPY = etherJPY;
      this.update();
    }));

    /**
     * ログアウト処理
     */
    logout(e){
      e.preventDefault();
      this.firebase.logout().then(() => {
        location.reload();
      });
    }
