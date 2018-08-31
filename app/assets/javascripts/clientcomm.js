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
$(window).on('focuschange', function setAnyWindowHasFocus() {
  window.localStorage.setItem('any_window_has_focus', window.hasFocus);
});


$(window).on('user-event', function toggleFaviconReadState(e, user) {
  favicon = $($('link[rel="shortcut icon"]')[0]);
  new_favicon_href = user.has_unread_messages ? favicon.data('unread-href') : favicon.data('read-href');
  favicon.attr('href', new_favicon_href);
});

$(window).on('message-event', function incomingMessageNotification(e, message) {
  has_focus = window.localStorage.getItem('any_window_has_focus') == 'true'
  favicon = $('link[rel="shortcut icon"]')[0];
  if (message.inbound && !has_focus) {
    Push.create('Message from ' + message.reporting_relationship.client.first_name + ' ' + message.reporting_relationship.client.last_name, {
      body: message.body,
      icon: favicon.href,
      timeout: 40000,
      tag: window.location.hostname + '_' + message.id,
      onClick: function () {
        conversation_url = '/conversations/' + message.reporting_relationship.id;
        conversation_window_name = 'https://' + document.domain + '/conversations/' + message.reporting_relationship.id;
        // Open new tab unless already on same page
        window.open(conversation_url, conversation_window_name);
        window.open('javascript:window.focus()', conversation_window_name, '');
      }
    });
  }
});

jQuery.fn.shuffle = function () {
  phrases = this.map(function(i, elem) {
    return $(elem).text();
  });

  shuffleArray(phrases);

  this.each(function(i, elem) {
    $(elem).text(phrases[i]);
  });

  return this;
};

function shuffleArray(array) {
  for (i = array.length - 1; i > 0; i--) {
    j = Math.floor(Math.random() * (i + 1));
    swap = array[i]
    array[i] = array[j]
    array[j] = swap
  }
}

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
    counter = $('<span class="character-count pull-right hidden"></span>'),
    imageInput = $('#message_attachments_0_media');

  var modalVisible = label.length > 0;
  setCounter(counter, element, modalVisible);

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

  imageInput.on('change', function(e) {
    setTimeout(function(){
      setCounter(counter, element, modalVisible);
    });
  });

  element.on('keydown keyup focus paste input', function(e){
    setTimeout(function(){
      setCounter(counter, element, modalVisible);
    });
  });
}

function setCounter(counter, textField, modalVisible) {
  var length = $(textField).val().length;
  var fileEmpty = [undefined, ''].includes($('#message_attachments_0_media').val());
  isBlank = (length == 0) && (fileEmpty);
  var tooLongForSingleText = length > 160;
  var tooLongToSend = length >= 1600;
  var cantSend = tooLongToSend || isBlank;

  counter.toggleClass('text--error', tooLongForSingleText);
  counter.toggleClass('hidden', !tooLongForSingleText);
  $('#send_message').prop('disabled', cantSend);
  $('#send_message').toggleClass('button--disabled', cantSend);

  $('#send_icon').prop('disabled', cantSend);
  $('#send_icon').toggleClass('button--disabled', cantSend);

  $('#schedule_messages').prop('disabled', cantSend);
  $('#schedule_messages').toggleClass('button--disabled', cantSend);
  $('#schedule_message').prop('disabled', cantSend);
  $('#schedule_message').toggleClass('button--disabled', cantSend);

  $('#send_later').prop('disabled', tooLongToSend || !fileEmpty);
  $('#send_later').toggleClass('button--disabled', tooLongToSend || !fileEmpty);

  if (!modalVisible) {
    $('#sendbar-buttons').toggleClass('warning-visible', tooLongForSingleText);
  }

  if (tooLongToSend) {
    counter.html("This message is more than 1600 characters and is too long to send.");
  } else if (tooLongForSingleText) {
    counter.html("Because of its length, this message may be sent as " + Math.ceil(length/160) + " texts.");
  }
}
