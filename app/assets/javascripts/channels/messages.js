//= require cable
//= require_self
//= require_tree .

this.App = {};

App.cable = ActionCable.createConsumer();

const match = window.location.pathname.match(/\/clients\/(\d)+\/messages/);
const clientId = match && match[1];

if (clientId) {
  App.messages = App.cable.subscriptions.create({ channel: 'MessagesChannel', client_id: clientId }, {
    received: function(data) {
      return $('#message-list').append(this.renderMessage(data.message));
    },

    renderMessage: function(message) {
      return `<div class='card'>
        <p>${message.body}</p>
      </div>`;
    }
  });
}
