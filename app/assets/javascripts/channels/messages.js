//= require cable
//= require_self
//= require_tree .

var Messages = {
  init: function() {
    this.msgs = $('#message-list');
  },
  appendMessage: function(message_html) {
    // append the message to the bottom of the list
    this.msgs.append(message_html);
    this.messagesToBottom();

    replaceEmoji(message_html);
  },
  updateMessage: function(dom_id, message_id, message_html) {
    // update the message in place, if it's on the page
    var msgElement = $("#" + dom_id);
    if (msgElement.length) {
        msgElement.replaceWith(message_html);
    } else {
      Messages.markMessageRead(message_id);
      this.appendMessage(message_html);
    }
  },
  markMessageRead: function(id) {
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
  },
  messagesToBottom: function() {
    $(document).scrollTop(this.msgs.prop('scrollHeight'));
  }
};

$(document).ready(function() {
  Messages.init();
  var clientId = Messages.msgs.data('client-id');
  Messages.messagesToBottom();

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
