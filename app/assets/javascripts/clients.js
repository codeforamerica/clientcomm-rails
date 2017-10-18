$(document).ready(function() {

  $("#transfer-button").click(function() {
    console.log('hello')
    Intercom('showNewMessage', 'Hi, I would like to request a transfer of ' + $(this).data('client-name') + '.');
  });
});
