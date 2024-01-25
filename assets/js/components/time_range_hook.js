import flatpickr from "flatpickr"
import { DateTime } from 'luxon'

function TimeRangeHook() {
  this.mounted = function () {
    this.setupFlatpickr()
    // we subscribe to messages coming from the dashboard LV
    // and from any chart in the page (zoom functionality)
    // we reject all messages from other components
    // we expect a `time_range` object to be part of the payload
    // or two dates (from, to)
    this.handleEvent(this.el.id + "::refresh-data", (payload) => {
      let time_range = [payload.time_range.from, payload.time_range.to]
      this.flatpickr.setDate(time_range, false, null)
    })

    document.getElementById(this.el.id).addEventListener('zoomCompleted', (e) => {
      this.sendNotification({ from: e.detail.from, to: e.detail.to })
    })
  }

  this.reconnected = function () {
    // initialize the flatpckr calendar
    this.setupFlatpickr()
  }

  // send a notification to the live view that the state has changed
  this.sendNotification = function (payload) {
    this.pushEventTo("#" + this.el.id, "lmn_time_range_change", payload)
  }

  this.setupFlatpickr = function () {
    this.flatpickr = flatpickr("#" + this.el.id, {
      mode: "range",
      dateFormat: "Y-m-d",
      monthSelectorType: "static",
      locale: {
        firstDayOfWeek: 1
      },
      onChange: (selectedDates, dateStr, instance) => {
        // do not fire when the user selects the first date
        if (2 == selectedDates.length) {
          // Since the calendar contains dates, we want the end date to be inclusive,
          // that's why we're rounding to up to the nearest second to the next day
          let to = DateTime.fromJSDate(selectedDates[1])
            .plus({ days: 1 }).plus({ seconds: -1 })
            .toJSDate()
          this.sendNotification({ from: selectedDates[0], to: to })
        }
      }
    })
  }

}
export default TimeRangeHook;
