import HighCharts from 'highcharts';
import MapChart from 'highcharts/modules/map.js';

function MapHook() {
  this.mounted = function () {
    // the `dataset` property carries all `data-*` attributes of the corresponding html element
    const element_data = this.el.dataset
    // initialize the library
    MapChart(HighCharts);
    // Create the chart
    this.map = HighCharts.mapChart(element_data.mapId, {
      chart: {
        map: JSON.parse(this.el.dataset.json),
        backgroundColor: 'rgba(0,0,0,0)', // transparent background
        height: '100%'
      },

      title: { text: '' },
      credits: { enabled: false },

      mapNavigation: {
        enabled: true,
      },

      colorAxis: { min: 0 },

      series: [{
        name: this.el.dataset.country,
        borderColor: '#A0A0A0',
        nullColor: 'rgba(200, 200, 200, 0.3)',
        states: {
          hover: {
            color: '#BADA55'
          }
        },
        tooltip: {
          headerFormat: '',
          pointFormat: '{point.description}',
        },
        dataLabels: {
          enabled: false,
        }
      }, {
        type: 'mappoint',
        tooltip: {
          headerFormat: '',
          pointFormat: '{point.description}',
        },
        events: {
          click: function (e) {
            const url = e.target.point.url;
            window.open(url);
          }
        },
        color: "#030303"
      }]
    });

    // setup the event handler
    this.handleEvent("panel-" + element_data.componentId + "::refresh-data", this.setMapData())
  };

  this.setMapData = function () {
    return (payload) => {
      this.map.series[0].setData(payload.Areas)
      this.map.series[1].setData(payload.Pins)
    }
  };

};

export default MapHook;