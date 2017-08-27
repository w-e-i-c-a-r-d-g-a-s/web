card-prices
  .panel
    .panel-header
      .panel-title.h5 Card Prices
    .panel-body
      span.h6 {opts.card.currentMarketPrice} eth
      #chart(style="width: 100%; height: 200px")
    .panel-footer

  script.
    this.on('mount', () => {
      window.addEventListener('resize', () => {
        this.drawChart();
      });
    });

    this.on('update', () => {
      // 最新のデータ
      this.firebase._firebase.database().ref(`cardPrice/${this.opts.card.address}`)
        .orderByKey().limitToLast(15)
        .on('value', (ss) => {
          const data = [
            ['transactionCount', 'marketPrice', 'diff']
          ];
          if(ss.exists()){
            ss.forEach((sss, i) => {
              const { transactionCount, diff, isNegative, marketPrice } = sss.val();
              // 最初のdiffは0にする
              const _diff = transactionCount === 1 ? 0 : isNegative ? -1 * diff : diff;
              data.push([
                transactionCount,
                this.web3c.weiToEth(marketPrice),
                this.web3c.weiToEth(_diff)
              ]);
            });
          }else{
            data.push([0, 0, 0]);
          }
          this.chartData = data;
          this._drawChart();
        });
    });

    _drawChart(){
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(this.drawChart);
    }

    drawChart(){
      const options = {
        legend: { position: 'bottom' },
        hAxis: { textPosition: 'none' },
        vAxis: { title: 'Ether' },
        chartArea:{
          top: 10,
          bottom: 30,
          left:40,
          right: 10,
          width:"100%",
          height:"100%"
        }
      };
      const data = google.visualization.arrayToDataTable(this.chartData);
      this.chart = new google.visualization.LineChart(document.getElementById('chart'));
      this.chart.draw(data, options);
    }


