var express = require('express');
var router = express.Router();
var User = require('../models/User');

/* GET home page. */
router.get('/', function(req, res, next) {
  if(req.isAuthenticated && req.isAuthenticated()){
    // Etherアカウント作成
    User.hasEtherAccount(req.user.id).then((hasEthAccount) => {
      console.log(hasEthAccount);
      if(hasEthAccount){
        res.render('mypage', { user: req.user });
      } else {
        res.render('input');
      }
    });
  }else{
    res.render('login');
  };
});

module.exports = router;

