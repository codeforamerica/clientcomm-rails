$(window).on('focuschange', function() {
  window.localStorage.setItem('any_window_has_focus', window.hasFocus);
});

EVENT_TYPES = {
  message: function (message) {
    has_focus = window.localStorage.getItem('any_window_has_focus') == 'true'
    if (message.inbound && !has_focus) {
      Push.create('Message from ' + message.reporting_relationship.client.first_name + ' ' + message.reporting_relationship.client.last_name, {
        body: message.body,
        icon: $('link[rel="shortcut icon"]')[0].href,
        timeout: 40000,
        tag: window.location.hostname + '_' + message.id,
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
}


$(document).ready(function() {
  App.events = App.cable.subscriptions.create(
    { channel: 'EventsChannel' },
    {
      received: function(event) {
        EVENT_TYPES[event.type](event.data);
      }
    }
  );
  Push.Permission.request(function() {}, function() {});
});
