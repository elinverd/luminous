import {TabulatorFull as Tabulator} from 'tabulator-tables';
import {sendFileToClient} from './utils'

function TableHook() {
  this.mounted = function() {
    this.id = document.getElementById(this.el.id)
    // we can not initialize the table with no data
    // because when we use table.replaceData no data is shown
    this.table = null;
    // setup the data refresh event handler (LV)
    this.handleEvent(this.el.id + "::refresh-data", this.handler())
    // setup the download CSV event handler
    this.el.addEventListener("panel:" + this.el.id + ":download:csv", this.downloadCSV())
  }

  this.handler = function() {
    return (payload) => {
      this.createOrUpdateTable(payload.rows, payload.columns);
    }
  }

  this.createOrUpdateTable = function(rows, columns) {
    if (this.table === null) {
      this.table = new Tabulator(this.id, {
        placeholder: "No data available",
        minHeight: 50,
        pagination: true,
        paginationSize: 10,
        data: rows,
        columns: columns,
        layout: "fitColumns"
      });
    } else {
      this.table.replaceData(rows);
    };
  }

  // download the table's data as CSV
  this.downloadCSV = function() {
    return (event) => {
      // determine column labels
      let fields = this.table.getColumnDefinitions().map((coldef) => coldef.field);
      let titles = this.table.getColumnDefinitions().map((coldef) => coldef.title);
      // form CSV header
      let csvRows = ['sep=,', titles.map((title) => '\"' + title + '\"').join(',')]

      // let's create all the csv rows
      let data = this.table.getData();
      for (let i=0; i<data.length; i++) {
        csvRows.push(fields.map((field) => data[i][field]).join(','));
      };
      // create and send file
      let csv = csvRows.join('\r\n');

      // Add UTF-8 BOM character
      csv = "\ufeff" + csv

      var blob = new Blob([this.convertToUTF16(csv)], { type: 'text/csv', encoding: "UTF-16LE" });
      var url = URL.createObjectURL(blob);
      sendFileToClient(url, this.el.id + ".csv")
    }
  }

  this.convertToUTF16 = function(data) {

    var byteArray = new Uint8Array(data.length * 2);
    for (var i = 0; i < data.length; i++) {
      byteArray[i * 2] = data.charCodeAt(i)
      byteArray[i * 2 + 1] = data.charCodeAt(i) >> 8
    }

    return byteArray
  }
}

export default TableHook
