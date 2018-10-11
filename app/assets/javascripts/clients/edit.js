$(document).ready(function() {

  /////////////////////
  // NEXT COURT DATE //
  /////////////////////

  initializeDatepicker("#client_next_court_date_at");

  ///////////////////////
  // DEACTIVATE CLIENT //
  ///////////////////////

  var formState = {
    surveyResponsesVisible: false,
  };

  $('#deactivate_client').click(function(e) {
    if (!formState.surveyResponsesVisible) {
      e.preventDefault();
      $(this).prop('disabled', true);
      $(this).addClass('button--cta button--disabled');
      $('#survey').show();
      formState.surveyResponsesVisible = true;
    }
  });

  $('#survey').click(function() {
    checked = ($(this).find(":checkbox:checked").length > 0);
    $('#deactivate_client').prop('disabled', !checked);
    $('#deactivate_client').toggleClass('button--disabled', !checked);
  });

  ///////////////////
  // MERGE CLIENTS //
  ///////////////////

  function uncheckMergeRadioButtons() {
    $('#new_merge_reporting_relationship input:radio').each(function() { $(this).prop('checked', false); })
  }

  function setMergeSubmitButtonEnabled(enabled) {
    $('#merge_client').prop('disabled', !enabled);
    $('#merge_client').toggleClass('button--disabled', !enabled);
  }

  function getMergeFormFilled() {
    var num_clicked = 0;
    $('#new_merge_reporting_relationship input:radio').each(function() {
      if ($(this).prop('checked')) {
        num_clicked++;
      }
    });
    return num_clicked === 2;
  }

  function clearNewestPhoneNumberLabel() {
    $('#merge span.label').remove()
  }

  function showNewestPhoneNumberLabel(merge_select) {
    var source_client_timestamp = parseInt($('#merge').data('reporting-relationship-timestamp'), 10);
    var selected_client_timestamp = parseInt(merge_select.data('timestamp'), 10);
    var new_label = '<span class="label label--teal">NEW</span>';

    clearNewestPhoneNumberLabel();

    if (selected_client_timestamp > source_client_timestamp) {
      $('#merge_phone_numbers label:nth-child(2) span').after(new_label);
    } else {
      $('#merge_phone_numbers label:nth-child(1) span').after(new_label);
    }
  }

  $('#merge_reporting_relationship_selected_client_id').change(function() {
    var merge_select = $('#merge_reporting_relationship_selected_client_id option:selected');
    var selected_client_id = merge_select.val();
    var selected_client_name = merge_select.text();
    var selected_client_phone_number = merge_select.data('phone-number');

    $('#merge_full_names label:nth-child(2) input').val(selected_client_id)
    $('#merge_full_names label:nth-child(2) span').text(selected_client_name)

    $('#merge_phone_numbers label:nth-child(2) input').val(selected_client_id)
    $('#merge_phone_numbers label:nth-child(2) span').text(selected_client_phone_number)

    uncheckMergeRadioButtons();
    setMergeSubmitButtonEnabled(false);
    showNewestPhoneNumberLabel(merge_select);

    $('#merge').show();

    mixpanelTrack(
      "client_merge_start", {
        client_id: Number($('#merge_reporting_relationship_client_id').attr('value')),
        selected_client_id: Number(selected_client_id)
      }
    );
  });

  $('#merge').click(function() {
    setMergeSubmitButtonEnabled(getMergeFormFilled());
  });
});
