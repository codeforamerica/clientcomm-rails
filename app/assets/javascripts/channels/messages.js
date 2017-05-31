//= require cable
//= require_self
//= require_tree .

const Messages = {
  init: function(id_selector) {
    this.msgs = $('#message-list');
    this.clientId = this.msgs.data('client-id');
  },
  appendOrReplace: function(dom_id, message_html) {
    var msgElement = $("#" + dom_id);
    if (!msgElement.length) {
        this.msgs.append(message_html);
        this.messagesToBottom();
    } else {
        msgElement.replaceWith(message_html);
    }
  },
  messagesToBottom: function() {
    $(document).scrollTop(this.msgs.prop('scrollHeight'));
  }
};

$(document).ready(function() {
  Messages.init('#message-list');

  App.messages = App.cable.subscriptions.create(
    { channel: 'MessagesChannel', client_id: Messages.clientId },
    {
      received: function(data) {
        Messages.appendOrReplace(data.message_dom_id, data.message_html);
      }
    }
  );
});
