var express = require('express');
var router = express.Router();

/* GET home page. */
router.get(['/', '/mycards'], function(req, res, next) {
  res.render('index');
});

router.get('/home', function(req, res, next) {
  res.render('index');
});

module.exports = router;
