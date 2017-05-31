//= require cable
//= require_self
//= require_tree .

const Messages = {
  init: function(id_selector) {
    this.msgs = $('#message-list');
    this.clientId = this.msgs.data('client-id');
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
        Messages.msgs.append(data.message_html);
        Messages.messagesToBottom();
      }
    }
  );
});
