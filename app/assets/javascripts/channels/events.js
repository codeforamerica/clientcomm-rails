$(document).ready(function() {
  App.events = App.cable.subscriptions.create(
    { channel: 'EventsChannel' },
    {
      received: function(event) {
        $(window).trigger(event.type + '-event', [event.data]);
      }
    }
  );
  Push.Permission.request(function() {}, function() {});
});
