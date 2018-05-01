$(document).ready(function() {
  function toggleMassMessage() {
    $('#schedule-later-form').toggle();
    $('#schedule-later-buttons').toggle();
    $('#send-now-buttons').toggle();
    $('#cancel-mass-message').toggleClass('scheduled');
  }

  $('#new_mass_message #send_later').click(function(e) {
    e.preventDefault();
    toggleMassMessage();
  });

  if ($('div#schedule-later-form p.text--error').length > 0) {
    toggleMassMessage();
  }

  $('.template--mass-messages').find('tbody :checkbox').each(function(index, checkbox) {
    $(checkbox).change(function(event) {
      $(checkbox).closest('tr').toggleClass('row--warning');

      if (!this.checked) {
        $('#select_all')[0].checked = false;
      }
    });
  });

  characterCount($('.template--mass-messages #mass_message_message'));

  $('.template--mass-messages #select_all').change(function () {
    var selected = this.checked;

    $('#new_mass_message').find('tbody :checkbox').each(function () {
      if (this.checked !== selected) {
        this.click();
      }
    });
  });

  var formState = {
    scheduleFormVisible: false,
  };

  function initializeDatepicker(datepickerSelector) {
    var $datepicker = $(datepickerSelector);
    $datepicker.datepicker();
    $datepicker.datepicker("option", "showAnim", "");
  }

  initializeDatepicker("#mass_message_send_at_date");

  $('#cancel-mass-message').click(function(e) {
    if ($(this).hasClass('scheduled')) {
      e.preventDefault();
      $('#schedule-later-form').toggle();
      $('#schedule-later-buttons').toggle();
      $('#send-now-buttons').toggle();
      $('#cancel-mass-message').toggleClass('scheduled');
    };
  });

  $('#schedule-later-form').click(function() {
    checked = ($(this).find(":checkbox:checked").length > 0);
    $('#send_later').prop('disabled', !checked);
    $('#send_later').toggleClass('button--disabled', !checked);
  });
});
