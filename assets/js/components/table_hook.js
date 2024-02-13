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
      this.createOrUpdateTable(payload.rows, payload.columns, payload.attributes);
    }
  }

  this.createOrUpdateTable = function(rows, columns, attributes) {
    if (this.table === null) {
      this.table = new Tabulator(this.id, {
        placeholder: "No data available",
        minHeight: 50,
        pagination: true,
        paginationSize: attributes.page_size,
        data: rows,
        columns: columns,
        layout: "fitColumns"
      });
    } else {
      this.table.setColumns(columns);
      this.table.replaceData(rows);
    }
  }

  // download the table's data as CSV
  this.downloadCSV = function () {
    return (event) => {
      // determine column labels
      let fields = this.table.getColumnDefinitions().map((coldef) => coldef.field);
      let titles = this.table.getColumnDefinitions().map((coldef) => coldef.title);
      // form CSV header
      let csvRows  = ['sep=,', titles.map((title) => '\"' + title + '\"').join(',')]

      // let's create all the csv rows
      let data = this.table.getData();
      for (let i=0; i<data.length; i++) {
        csvRows.push(fields.map((field) => data[i][field]).join(','));
      };
      // create and send file
      let csv = csvRows.join('\r\n');
      var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      var url = URL.createObjectURL(blob);
      sendFileToClient(url, this.el.id + ".csv")
    }
  }
}

export default TableHook
