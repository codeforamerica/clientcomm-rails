//= require cable
//= require_self
//= require_tree .

var Messages = {
  init: function() {
    this.msgs = $('#message-list');
    this.clientId = this.msgs.data('client-id');
  },
  appendMessage: function(message_html) {
    // append the message to the bottom of the list
    this.msgs.append(message_html);
    this.messagesToBottom();
  },
  updateMessage: function(dom_id, message_html) {
    // update the message in place, if it's on the page
    var msgElement = $("#" + dom_id);
    if (msgElement.length) {
        msgElement.replaceWith(message_html);
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
  Messages.messagesToBottom();

  // only subscribe if we're on a message page
  if (!Messages.clientId) {
    return;
  }

  App.messages = App.cable.subscriptions.create(
    { channel: 'MessagesChannel', client_id: Messages.clientId },
    {
      received: function(data) {
        if (data.is_update) {
          Messages.updateMessage(data.message_dom_id, data.message_html);
        } else {
          Messages.markMessageRead(data.message_id);
          Messages.appendMessage(data.message_html);
        }
      }
    }
  );
});
