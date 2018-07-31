EVENT_TYPES = {
  user: function(user) {
    favicon = $($('link[rel="shortcut icon"]')[0]);
    new_favicon_href = user.has_unread_messages ? favicon.data('unread-href') : favicon.data('read-href');
    favicon.attr('href', new_favicon_href);
  },
  message: function (message) {
    has_focus = window.localStorage.getItem('any_window_has_focus') == 'true'
    favicon = $('link[rel="shortcut icon"]')[0];
    if (message.inbound && window.location.pathname == '/conversations/' + message.reporting_relationship.id) {
      $('like-options').removeClass('hidden');
      $('like-options like-option').shuffle();
    }
    if (message.inbound && !has_focus) {
      Push.create('Message from ' + message.reporting_relationship.client.first_name + ' ' + message.reporting_relationship.client.last_name, {
        body: message.body,
        icon: favicon.href,
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

jQuery.fn.shuffle = function () {
  phrases = this.map(function(i, elem) {
    return $(elem).text();
  });

  shuffleArray(phrases);

  this.each(function(i, elem) {
    $(elem).text(phrases[i]);
  });

  return this;
};

function shuffleArray(array) {
  for (i = array.length - 1; i > 0; i--) {
    j = Math.floor(Math.random() * (i + 1));
    swap = array[i]
    array[i] = array[j]
    array[j] = swap
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
