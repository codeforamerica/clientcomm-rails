//= require client_search
//= require clients/edit

var revealer = (function() {
  var rv = {
    init: function() {
      $('.reveal').each(function(index, revealer) {
        var self = revealer;
        $(self).addClass('is-hidden');
        $(self).find('.reveal__link').click(function(e) {
          e.preventDefault();
          $(self).toggleClass('is-hidden');
        });
      });
    }
  }
  return {
    init: rv.init
  }
})();

$(document).ready(function() {

  function initializeDatepicker(datepickerSelector) {
    var $datepicker = $(datepickerSelector);
    $datepicker.datepicker();
    $datepicker.datepicker("option", "showAnim", "");
  }

  initializeDatepicker("#client_next_court_date_at");

  $("#transfer-button").click(function() {
    Intercom('showNewMessage', 'Hi, I would like to request a transfer of ' + $(this).data('client-name') + '.');
  });

  revealer.init();
});
