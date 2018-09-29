$(document).ready(function() {
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

    $('#merge').show();
  });

  $('#merge').click(function() {
    setMergeSubmitButtonEnabled(getMergeFormFilled());
  });
});
