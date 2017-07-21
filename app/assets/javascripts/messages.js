$(document).ready(function(){
  $(document).on('submit', '#new_message', function(e) {
    // clear the message body text field
    $('#message_body').val('');
  });

  $('#send_later').click(function(){
    var sendLaterMessage = $('input#message_body.main-message-input').val();
    $('textarea#message_body.send-later-input').val(sendLaterMessage);
  });

  $('#schedule-message').click(function(){
    $('#send-later-modal').modal('hide');
  })

  $('#edit-message-modal').modal();

  $('#edit-message-modal').on('hidden.bs.modal', function() {
    window.location = ''
  });
})
