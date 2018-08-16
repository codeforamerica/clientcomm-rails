$(document).ready(function() {
  if ($("meta[name='current-user']").length > 0) {
    App.events = App.cable.subscriptions.create(
      { channel: 'EventsChannel' },
      {
        received: function(event) {
          $(window).trigger(event.type + '-event', [event.data]);
        }
      }
    );
  }
  Push.Permission.request(function() {}, function() {});
});
