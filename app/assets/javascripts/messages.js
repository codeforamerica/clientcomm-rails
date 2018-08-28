//= require channels/messages
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

var file_types = [
  'image/jpeg',
  'image/gif',
  'image/png'
]

function validFileType(file) {
  return file_types.includes(file.type);
 }

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
    $('form#new_message textarea.main-message-input').trigger('input');
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

  $('#message_attachments_0_media').on('change', function() {
    if (this.files.length > 0) {
      fileName = this.files[0].name;
      $('#file-name-preview').removeClass('hidden');
      if (!validFileType(this.files[0])) {
        $('span.image-help-text').text('You can only send .gif, .png, and .jpg files');
        $('#file-name-preview').addClass('warning');
        $('#image-cancel i').removeClass('icon-close').addClass('icon-warning');
        $('#message_attachments_0_media').val('');
      } else {
        if(this.files[0].size > 5000000) {
          $('span.image-help-text').text('You can only send files <5MB in size');
          $('#file-name-preview').addClass('warning');
          $('#image-cancel i').removeClass('icon-close').addClass('icon-warning');
          $('#message_attachments_0_media').val('');
        } else {
          $('span.image-help-text').html('<span class="file-name">'+fileName+'</span><added></added>');
          $('#file-name-preview').removeClass('warning');
          $('#image-cancel i').removeClass('icon-warning').addClass('icon-close');
        }
      }

    } else {
      $('#file-name-preview').addClass('hidden');
    };
  });

  $('#image-cancel').click(function() {
    $('#image-cancel i').removeClass('icon-warning').addClass('icon-close');
    $('#message_attachments_0_media').trigger('change');
    $('span.image-help-text').text('');
    $('#file-name-preview').addClass('hidden');
    $('#message_attachments_0_media').val('');
  });

  var sendInput = $('textarea.autosize');

  $('#send_later').click(function(){
    var sendLaterMessage = $('textarea#message_body.main-message-input').val();
    $('textarea#scheduled_message_body.send-later-input').val(sendLaterMessage);
    $('like-options').addClass('hidden');
  });

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
    $('#message_body').val('');
    $('#file-name-preview').addClass('hidden');
    $('like-options').addClass('hidden');
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

