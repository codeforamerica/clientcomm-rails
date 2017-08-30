$(document).ready(function(){
  $(document).on('submit', '#new_message', function(e) {
    // clear the message body text field
    $('#message_body').val('');
  });

  $('#send_later').click(function(){
    var sendLaterMessage = $('textarea#message_body.main-message-input').val();
    $('textarea#scheduled_message_body.send-later-input').val(sendLaterMessage);
  });

  function initializeModal(modalSelector) {
    $(modalSelector).modal();
    $(modalSelector).on('shown.bs.modal', function () {
      $('textarea#scheduled_message_body.send-later-input.textarea').focus();
    });
  }

  initializeModal('#new-message-modal');
  initializeModal('#edit-message-modal');

  function initializeDatepicker(datepickerSelector) {
    $(datepickerSelector).datepicker();
    $(datepickerSelector).datepicker("option", "showAnim", "");
  };

  initializeDatepicker("#edit_message_send_at_date");
  initializeDatepicker("#new_message_send_at_date");

  var sendInput = $('textarea.autosize');

  autosize(sendInput);

  $('form#new_message').on('ajax:success', function(e) {
      autosize.update(sendInput);
  });
});
