
## install

### Ethereum RPCの起動

#### RPCをgethで実行する場合

```
$ geth --port 30001 --networkid "3981" \
  --rpc --rpcaddr localhost --rpcport 8545 --rpccorsdomain "*" --rpcapi eth,web3,personal \
  --datadir . console
```

のようなコマンドで、gethを起動する

#### RPCをtestrpcで実行する場合

<!--
[eth-testrpc](https://github.com/pipermerriam/eth-testrpc) をpipでインストール
(pythonは2, 3どっちでも良さそう)

```sh
$ pip install eth-testrpc
```

うまくいかない場合はこっちを試す

```sh
sudo -H pip install eth-testrpc
```



`command not found: testrpc`といわれる場合は
-->

[ethereumjs-testrpc](https://github.com/ethereumjs/testrpc)をインストールします。

```
$ npm uninstall -g ethereumjs-testrpc
$ npm install -g ethereumjs-testrpc
```

インストールができたら`testrpc`で起動する。

```sh
$ testrpc
```

（一度接続した後の止め方が分からない・・・）

---

### パッケージをインストール

`yarn`,`nodemon`が入ってない場合はインストール

```
npm install -g nodemon yarn
```

インストールを実行

```
$ yarn install
```

## Development

フロント側のビルドシステムを起動

```
$ npm run front
```

サーバ側のビルドシステムを起動

```
$ DEBUG=td:* nodemon bin/www
```

`localhost:3000`にアクセスします。
