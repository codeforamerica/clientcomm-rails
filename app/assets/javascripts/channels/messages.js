//= require cable
//= require_self
//= require_tree .

const Messages = {
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
          Messages.appendMessage(data.message_html);
        }
      }
    }
  );
});
