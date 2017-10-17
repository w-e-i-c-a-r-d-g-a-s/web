// Ether/Wei/JPYの価格を表示
// 画面上は基本 ehterかJPYとなる
// toを指定している場合強制的にその単位になる
price
  span
    | {etherPrice}&nbsp;{displayUnit}&nbsp;
    br(if="{opts.linebreak}")
    | (約&yen;{jpy})

  script.
    import { EVENT } from '../../constants';
    this.etherPrice = 0;
    this.displayUnit = '';
    this.jpy = '-';

    this.obs.on(EVENT.UPDATE_ETH_PRICE, (({ etherJPY }) => {
      this.etherJPY = etherJPY;
      this.updateJPY();
      this.update();
    }));

    this.on('mount', () => {
      this.setVal();
      this.update();
    });

    setVal(){
      const { unit, val } = this.opts;
      switch(unit){
        case 'wei':
          this.etherPrice = this.web3c.web3.fromWei(val, 'ether');
          this.displayUnit = 'Ether';
          break;
        case 'ether':
          this.etherPrice = val;
          this.displayUnit = 'Ether';
          break;
        default:
          this.etherPrice = val;
      }
    }

    updateJPY(){
      if(this.etherJPY){
        const jpy = (this.etherPrice * this.etherJPY).toFixed(0);
        this.jpy = String(jpy).replace( /(\d)(?=(\d\d\d)+(?!\d))/g, '$1,');
      }
    }
