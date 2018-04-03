$(document).ready(function(){
  var $templateButton = $('#template-button');

  var sendInput = $('textarea.autosize');
  // Enable the popover for templates
  $templateButton.popover({
    container: '.sendbar'
  });

  $templateButton.click(function(){
    mixpanelTrack(
      "template_popover_view", {
        templates_count: $(this).data('template-count'),
        client_id: $(this).data('client-id')
      }
    );
  });

  $templateButton.on('shown.bs.popover', function () {
    $templateButton.addClass('template-popover-active');

    $('.template-row').click(selectTemplate);
  });

  function selectTemplate() {
    mixpanelTrack(
      "template_insert", {
        client_id: $templateButton.data('client-id')
      }
    );

    populateTextarea(this);
  }

  function populateTextarea(context) {
    $('#message_body').val($(context).data('template-body'));
    autosize.update(sendInput);
  }

  $(document).on('submit', '#new_message', function(e) {
    // clear the message body text field
    $('#message_body').val('');
  });

  $('#send_later').click(function(){
    var sendLaterMessage = $('textarea#message_body.main-message-input').val();
    $('textarea#scheduled_message_body.send-later-input').val(sendLaterMessage);
  });

  function initializeModal(modalSelector) {
    var $modal = $(modalSelector);
    $modal.modal();
    $modal.on('shown.bs.modal', function () {
      $('textarea#scheduled_message_body.send-later-input.textarea').focus();
    });
  }

  initializeModal('#new-message-modal');
  initializeModal('#edit-message-modal');

  function initializeDatepicker(datepickerSelector) {
    var $datepicker = $(datepickerSelector);
    $datepicker.datepicker();
    $datepicker.datepicker("option", "showAnim", "");
  }

  initializeDatepicker("#edit_message_send_at_date");
  initializeDatepicker("#new_message_send_at_date");

  autosize(sendInput);

  $('form#new_message').on('ajax:success', function(e) {
    autosize.update(sendInput);
  });

  $('#show_note').click(function(){
    $('#full_note').show();
    $('#truncated_note').hide();
  });

  $('#hide_note').click(function(){
    $('#full_note').hide();
    $('#truncated_note').show();
  });

  characterCount($('.main-message-input'));
});

function characterCount(element) {
  if(element.length === 0) { return; }

  var
    label = $("label[for='" + element.attr('id') + "']"),
    counter = $('<span class="character-count pull-right hidden"></span>');

  var modalVisible = label.length > 0

  if (label.length > 0) {
    counter.addClass('pull-bottom');
    label.wrap('<div class="relative-container"></div>').after(counter);
  } else {
    element.before(counter);
  }

  var form = element.prop('form');

  $(form).on('ajax:complete', function () {
    setCounter(counter, element);
  });

  element.on('keydown keyup focus paste', function(e){
    setTimeout(function(){
      setCounter(counter, element, modalVisible);
    });
  });
}

function setCounter(counter, textField, modalVisible) {
  var length = $(textField).val().length;
  var tooLongForSingleText = length > 160;
  counter.toggleClass('text--error', tooLongForSingleText);
  counter.toggleClass('hidden', !tooLongForSingleText);

  if (!modalVisible) {
    $('#sendbar-buttons').toggleClass('warning-visible', tooLongForSingleText);
    $('#template-button').toggleClass('warning-visible', tooLongForSingleText);
  }

  if (tooLongForSingleText) {
    counter.html("Because of its length, this message may be sent as "+Math.ceil(length/160)+" texts.");
  }
}

function mixpanelTrack(event, params) {
  var meta_tags = {
    visitor_id: $('meta[name=visitor_id]').attr("content"),
    deploy: $('meta[name=deploy]').attr("content")
  };

  $.extend(params, meta_tags);
  mixpanel.track(event, params);
}
