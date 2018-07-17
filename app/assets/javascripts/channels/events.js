window.name = window.location.href; // set name of page

EVENT_TYPES = {
  message: function (message) {
    Push.create('Message from ' + message.reporting_relationship.client.first_name + ' ' + message.reporting_relationship.client.last_name, {
      body: message.body,
      icon: $('link[rel="shortcut icon"]')[0].href,
      timeout: 40000,
      onClick: function () {
        conversation_url = '/conversations/' + message.reporting_relationship.id;
        conversation_window_name = 'https://' + document.domain + '/conversations/' + message.reporting_relationship.id;
        // Open new tab unless already on same page
        window.open(conversation_url, conversation_window_name);
        window.open('javascript:window.focus()', conversation_window_name, '');
      }
    });
  }
}

$(document).ready(function() {
  Push.Permission.request(); //Ask for permission ahead of time.
  App.events = App.cable.subscriptions.create(
    { channel: 'EventsChannel' },
    {
      received: function(event) {
        EVENT_TYPES[event.type](event.data);
      }
    }
  );
});
