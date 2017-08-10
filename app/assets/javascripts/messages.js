$(document).ready(function(){
  $(document).on('submit', '#new_message', function(e) {
    // clear the message body text field
    $('#message_body').val('');
  });

  $('#send_later').click(function(){
    var sendLaterMessage = $('input#message_body.main-message-input').val();
    $('textarea#scheduled_message_body.send-later-input').val(sendLaterMessage);
  });

  $('#edit-message-modal').modal();
  $('#edit-message-modal').on('shown.bs.modal', function () {
    $('textarea#scheduled_message_body.send-later-input.textarea').focus();
  });
  $('#edit-message-modal').on('hidden.bs.modal', function(e) {
    e.preventDefault();
    window.location = $('.close').attr('href');
  });

  $('#new-message-modal').modal();
  $('#new-message-modal').on('shown.bs.modal', function () {
    $('textarea#scheduled_message_body.send-later-input.textarea').focus();
  });
  $('#new-message-modal').on('hidden.bs.modal', function(e) {
    e.preventDefault();
    window.location = $('.close').attr('href');
  });

  $("#edit_message_send_at_date").datepicker();
  $("#edit_message_send_at_date").datepicker("option", "showAnim", "");

  $("#new_message_send_at_date").datepicker();
  $("#new_message_send_at_date").datepicker("option", "showAnim", "");

  var sendInput = $('textarea.autosize');

  autosize(sendInput);

  $('form#new_message').on('ajax:success', function(e) {
      autosize.update(sendInput);
  });
});
