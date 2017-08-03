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
  $('#new-message-modal').modal();

  $("#edit_message_send_at_date").datepicker();
  $("#edit_message_send_at_date").datepicker("option", "showAnim", "");

  $("#new_message_send_at_date").datepicker();
  $("#new_message_send_at_date").datepicker("option", "showAnim", "");
});
