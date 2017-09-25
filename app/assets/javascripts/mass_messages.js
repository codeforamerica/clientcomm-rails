$(document).ready(function() {
  $('.template--mass-messages').find(':checkbox').each(function(index, checkbox) {
    $(checkbox).change(function(event) {
      $(checkbox).closest('tr').toggleClass('row--warning');
    });

    $(checkbox).closest('tr').click(function(event) {
      if ($(event.target).is(':checkbox, label')) {
        return;
      }

      $(checkbox).prop('checked', function(index, oldProp) {
        return !oldProp;
      }).change();
    });
  });

  characterCount($('.template--mass-messages #mass_message_message'));
});
