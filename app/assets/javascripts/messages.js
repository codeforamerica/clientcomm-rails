//= require channels/messages

$(window).on('message-event', function toggleLikeOptions(e, message) {
  if (message.inbound && window.location.pathname == '/conversations/' + message.reporting_relationship.id) {
    $('like-options').removeClass('hidden');
    $('like-options like-option').shuffle();
  }
});

$(document).ready(function(){
  function fillLikeOption(elm) {
    elm  = $(elm);
    text = elm.text();
    $('form#new_message textarea.main-message-input').val(text);
    $('form#new_message input.positive-template-type').val(text);
    elm.parent().toggleClass('hidden');
  }

  $('like-options like-option').click(function(e) {
    fillLikeOption(this);
  });

  $('like-options like-option').on('keyup', function(e) {
    if (e.keyCode == 13) {
      fillLikeOption(this);
    }
  });

  $('form#new_message textarea.main-message-input').on('input keydown keyup focus paste', function(e) {
    if ($(this).val() == '') {
      $('form#new_message input.positive-template-type').val('');
    }
  });

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
    $('like-options').addClass('hidden');
  });

  $('#send_later').click(function(){
    var sendLaterMessage = $('textarea#message_body.main-message-input').val();
    $('textarea#scheduled_message_body.send-later-input').val(sendLaterMessage);
    $('like-options').addClass('hidden');
  });

  function initializeModal(modalSelector) {
    var $modal = $(modalSelector);
    $modal.modal();
    $modal.on('shown.bs.modal', function () {
      $('textarea#scheduled_message_body.send-later-input.textarea').focus();
    });
    $modal.on('hidden.bs.modal', function () {
      element = $('.main-message-input');
      counter = $('<span class="character-count pull-right hidden"></span>');
      setCounter(counter, element);
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

