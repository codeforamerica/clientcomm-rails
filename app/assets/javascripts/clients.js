//= require client_search
//= require clients/edit

$(document).ready(function() {

  function initializeDatepicker(datepickerSelector) {
    var $datepicker = $(datepickerSelector);
    $datepicker.datepicker();
    $datepicker.datepicker("option", "showAnim", "");
  }

  initializeDatepicker("#next_court_date_at");

  $("#transfer-button").click(function() {
    Intercom('showNewMessage', 'Hi, I would like to request a transfer of ' + $(this).data('client-name') + '.');
  });
});
