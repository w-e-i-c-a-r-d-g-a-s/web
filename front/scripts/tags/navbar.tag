navbar
  header.navbar
    section.navbar-section
      a.btn.btn-link(onclick="{() => opts.go('home')}") Home
      a.btn.btn-link(onclick="{() => opts.go('mypage')}") MyPage
      a.btn.btn-link(onclick="{() => opts.go('upload')}") Upload
    section.navbar-center
      figure.avatar.avatar-l
        img(src="{opts.user.photoURL}")
    section.navbar-section
      a.btn.btn-link(onclick="{() => opts.go('setting')}") Setting
      a.btn.btn-link(onclick="{opts.logout}") Logout
