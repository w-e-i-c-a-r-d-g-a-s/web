const express = require('express');
const path = require('path');
const favicon = require('serve-favicon');
const logger = require('morgan');
const cookieParser = require('cookie-parser');
const bodyParser = require('body-parser');
const session = require('express-session');
const admin = require("firebase-admin");
const index = require('./routes/index');
const login = require('./routes/login');
const newWallet = require('./routes/newWallet');
const User = require('./models/User');

const etherSetting = require('./etherSetting.json');
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://td-demo-5c73d.firebaseio.com"
});

const app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// session setting
app.use(session({ secret: 'starrain', resave: true, saveUninitialized: true }));

// ログインしていない場合の処理
const isLoggedIn = (req, res, next) => {
  // accessTokenをもらう
  const idToken = req.query.idToken;
  admin.auth().verifyIdToken(idToken).then(() => {
    // token verified
    next();
  }).catch(function(error) {
    console.log(error);
    res.status = 401;
    res.send('auth error');
  });
};

app.use('/', index);
app.use('/login', login);
// etherパスワードを登録
app.use('/newWallet', newWallet);


// ログアウト
app.get('/logout', function(req, res){
  req.logout();
  res.redirect('/');
});

// ダウンロード
app.get('/downloadKS', isLoggedIn, (req, res, err) => {
  res.download(`${etherSetting.etherPath}/keystore/${req.query.etherKeyStoreFile}`);
});

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  const err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status = err.status || 500;
  res.render('error');
});

module.exports = app;
