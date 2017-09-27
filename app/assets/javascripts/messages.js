$(document).ready(function(){
  // Enable the popover for templates
  $('[data-toggle="popover"]').popover({
    container: '.sendbar'
  });

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

  $('#show_note').click(function(){
    $('#truncated_note').hide();
    $('#full_note').show();
  });

  $('#hide_note').click(function(){
    $('#full_note').hide();
    $('#truncated_note').show();
  });

  characterCount($('.main-message-input'));
});

function characterCount(element) {

  var initialLength;
  if (element.length > 0) {
    initialLength = $(element).val().length
  } else {
    initialLength = 0;
  }

  var
    label = $("label[for='" + element.attr('id') + "']"),
    counter = $('<span class="character-count pull-right">' + initialLength + '</span>');

  if (label.length > 0) {
    counter.addClass('pull-bottom');
    label.wrap('<div class="relative-container"></div>').after(counter);
  } else {
    element.before(counter);
  }

  element.on('keydown keyup focus', function(){
    var length = $(this).val().length;
    counter.html(length);
    counter.toggleClass('text--error', length > 160);
  });
}
