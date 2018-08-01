window.name = window.location.href;
window.hasFocus = true;

$(window).on('focus', function() {
  window.hasFocus = true;
  $(window).trigger('focuschange');
});
$(window).on('blur', function() {
  window.hasFocus = false;
  $(window).trigger('focuschange');
});

function mixpanelTrack(event, params) {
  $.post({
    url: '/tracking_events',
    data: { label: event, data: params }
  });
}

function characterCount(element) {
  if(element.length === 0) { return; }

  var
    label = $("label[for='" + element.attr('id') + "']"),
    counter = $('<span class="character-count pull-right hidden"></span>');

  var modalVisible = label.length > 0;

  if (label.length > 0) {
    counter.addClass('pull-bottom');
    label.wrap('<div class="relative-container"></div>').after(counter);
  } else {
    element.before(counter);
  }

  var form = element.prop('form');

  $(form).on('ajax:complete', function () {
    setCounter(counter, element);
  });

  element.on('keydown keyup focus paste', function(e){
    setTimeout(function(){
      setCounter(counter, element, modalVisible);
    });
  });
}

function setCounter(counter, textField, modalVisible) {
  var length = $(textField).val().length;
  var tooLongForSingleText = length > 160;
  var tooLongToSend = length >= 1600;
  counter.toggleClass('text--error', tooLongForSingleText);
  counter.toggleClass('hidden', !tooLongForSingleText);

  $('#send_message').prop('disabled', tooLongToSend);
  $('#send_message').toggleClass('button--disabled', tooLongToSend);

  $('#send_later').prop('disabled', tooLongToSend);
  $('#send_later').toggleClass('button--disabled', tooLongToSend);

  $('#schedule_message').prop('disabled', tooLongToSend);
  $('#schedule_message').toggleClass('button--disabled', tooLongToSend);

  $('#schedule_messages').prop('disabled', tooLongToSend);
  $('#schedule_messages').toggleClass('button--disabled', tooLongToSend);

  if (!modalVisible) {
    $('#sendbar-buttons').toggleClass('warning-visible', tooLongForSingleText);
    $('#template-button').toggleClass('warning-visible', tooLongForSingleText);
  }

  if (tooLongToSend) {
    counter.html("This message is more than 1600 characters and is too long to send.");
  } else if (tooLongForSingleText) {
    counter.html("Because of its length, this message may be sent as " + Math.ceil(length/160) + " texts.");
  }
}
