//= require client_search

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
  initializeDatepicker("#client_next_court_date_at");

  $("#transfer-button").click(function() {
    Intercom('showNewMessage', 'Hi, I would like to request a transfer of ' + $(this).data('client-name') + '.');
  });

  revealer.init();
});
