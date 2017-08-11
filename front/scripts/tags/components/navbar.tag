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
        a.btn.btn-link(href="#/" class="{'active': menu === MENUS.HOME}") Home
        a.btn.btn-link(href="#/mycards" class="{'active': menu === MENUS.MYCARDS}") My Cards
        a.btn.btn-link(href="#/activity" class="{'active': menu === MENUS.ACTIVITY}") Activity
    section.navbar-center
      figure.avatar.avatar-l
        a(href="{user.link}" target="_blank")
          img(src="{user.photoURL}")
      span.info.hide-xs
        span.text-lowercase {user.etherAccount}
        br
        span {user.eth} Ether
    section.navbar-section
      .hide-md
        span 1ETH = &yen;{etherJPY}
        a.btn.btn-link(href="#/upload" class="{'active': menu === MENUS.UPLOAD}") Upload
        a.btn.btn-link(href="#/admin" class="{'active': menu === MENUS.ADMIN}") Admin
        a.btn.btn-link(href="#/setting" class="{'active': menu === MENUS.SETTING}") Setting
        button.btn.btn-link(onclick="{logout}") Logout
  script.
    import { EVENT, MENUS } from '../../constants'
    this.MENUS = MENUS;
    this.etherJPY = null;

    opts.obs.on('updateEthPrice', (({ etherJPY }) => {
      this.etherJPY = etherJPY;
      this.update();
    }));

    opts.obs.on(EVENT.UPDATE_MENU, (({ selectedMenu }) => {
      this.menu = selectedMenu;
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
