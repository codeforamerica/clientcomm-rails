//= require client_search
//= require clients/edit

$(document).ready(function() {

  $("#transfer-button").click(function() {
    Intercom('showNewMessage', 'Hi, I would like to request a transfer of ' + $(this).data('client-name') + '.');
  });
});
