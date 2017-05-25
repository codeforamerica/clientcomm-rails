//= require cable
//= require_self
//= require_tree .


const match = window.location.pathname.match(/\/clients\/(\d)+\/messages/);
const clientId = match && match[1];

if (clientId) {
  App.messages = App.cable.subscriptions.create({ channel: 'MessagesChannel', client_id: clientId }, {
    received: function(data) {
      return this.renderMessage(data.message);
    },

    renderMessage: function(message) {
      $.ajax(`/messages/${message.id}`)
        .done(function (data) {
          $('#message-list').append(data);
        });
    }
  });
}
