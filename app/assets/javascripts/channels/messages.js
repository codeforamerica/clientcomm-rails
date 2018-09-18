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
      el = $(el);
      message_el = el.parent();
      markMessageRead(message_el.attr('id').replace('message_',''));
      message_el.removeClass('unread').addClass('read');
    });
  }
}, 300);

messagesToBottom = function() {
  window.scrollTo(0,document.body.scrollHeight);
};

var Messages = {
  init: function() {
    this.msgs = $('#message-list');
  },
  appendMessage: function(message_html) {
    // append the message to the bottom of the list
    $('#messages-empty-dialog').hide();
    this.msgs.append(message_html);

    last_msg = this.msgs.children().last();

    messagesToBottom();

    replaceEmoji(message_html);
  },
  updateMessage: function(dom_id, message_id, message_html, status_html, status) {
    // update the message in place, if it's on the page
    var msgElement = $("#" + dom_id);
    if (msgElement.length) {
      var statusElement = msgElement.find(".message--label");
      if (statusElement.length && status_html) {
        statusElement.replaceWith(status_html);
        msgElement.find(".message--content").attr("class", "message--content " + status);
      } else {
        msgElement.replaceWith(message_html);
      }
    } else {
      this.appendMessage(message_html);
    }
    markAsRead();
  },
};

$(document).ready(function() {
  $(window).on('resize scroll visibilitychange focuschange', markAsRead);
  markAsRead();
  Messages.init();
  var clientId = Messages.msgs.data('client-id');
  messagesToBottom();


  // only subscribe if we're on a message page
  if (!clientId) {
    return;
  }

  if ($("meta[name='current-user']").length > 0) {
    App.messages = App.cable.subscriptions.create(
      { channel: 'MessagesChannel', client_id: clientId },
      {
        received: function(data) {
          Messages.updateMessage(data.message_dom_id, data.message_id, data.message_html, data.message_status_html, data.message_status);
        }
      }
    );
  }
});
