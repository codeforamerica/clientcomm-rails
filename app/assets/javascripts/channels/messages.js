//= require withinviewport
//= require jquery.withinviewport

function markMessageRead(id) {
  // tell the server to mark this message read
  $.ajax({
    type: "POST",
    url: "/messages/" + id.toString() + "/read",
    id: id,
    data: {
      message: {
        read: true
      }
    }
  });
}

markAsRead = _.throttle(function() {
  if(window.hasFocus && (typeof document.visibilityState == 'undefined' || document.visibilityState == 'visible')) {
    $('div.message--inbound.unread p.message--label').withinviewport({ top: 100, bottom: -100 }).each(function(i, el) {
      console.log(el);
      el = $(el);
      message_el = el.parent();
      markMessageRead(message_el.attr('id').replace('message_',''));
      message_el.removeClass('unread').addClass('read');
    });
  }
}, 300);

messagesToBottom = function() {
  window.scrollTo(0,document.body.scrollHeight);
}

var Messages = {
  init: function() {
    this.msgs = $('#message-list');
  },
  appendMessage: function(message_html) {
    // append the message to the bottom of the list
    $('#messages-empty-dialog').hide();
    this.msgs.append(message_html);

    last_msg = this.msgs.children().last();
    if (last_msg.hasClass('message--inbound')) {
      generateLikeBindings(null, last_msg);
    };

    messagesToBottom();

    replaceEmoji(message_html);
  },
  updateMessage: function(dom_id, message_id, message_html) {
    // update the message in place, if it's on the page
    var msgElement = $("#" + dom_id);
    if (msgElement.length) {
        msgElement.replaceWith(message_html);
    } else {
      this.appendMessage(message_html);
    }
    markAsRead();
  },
};

function postLikeExpandEvent(msg_id, client_id) {
  mixpanelTrack(
    "positive_template_expand", {
      like_message_id: msg_id,
      client_id: client_id
    }
  );
}

function generateLikeBindings(i, msg) {
  msg = $(msg);
  client_id = $('div#message-list').data('client-id');
  message_id = msg.attr('id').slice(8);
  msg.find('.show-like-options').click(function(e) {
    elm = $(this);
    elm.toggleClass('icon-close');
    elm.toggleClass('icon-add');
    options_div = elm.next('div.like-options');
    options_div.toggleClass('hidden');
    postLikeExpandEvent(message_id, client_id);
  });

  msg.find('div.like-options div').click(function(e) {
    elm  = $(this);
    text = elm.text();
    $('form#new_message textarea.main-message-input').val(text);
    $('form#new_message input.like-message-id').val(message_id);
    $('form#new_message').submit();
    $('form#new_message input.like-message-id').val('');
    elm.parent().toggleClass('hidden');
    button = elm.parent().siblings('.show-like-options');
    button.toggleClass('icon-close');
    button.toggleClass('icon-add');
  });
};

$(document).ready(function() {
  $(window).on('resize scroll visibilitychange focuschange', markAsRead);
  markAsRead();
  Messages.init();
  var clientId = Messages.msgs.data('client-id');
  messagesToBottom();

  $('.message--inbound').each(generateLikeBindings);

  // only subscribe if we're on a message page
  if (!clientId) {
    return;
  }
  App.messages = App.cable.subscriptions.create(
    { channel: 'MessagesChannel', client_id: clientId },
    {
      received: function(data) {
        Messages.updateMessage(data.message_dom_id, data.message_id, data.message_html);
      }
    }
  );
});
