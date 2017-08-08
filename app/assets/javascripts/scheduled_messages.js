$(document).ready(function(){
  $('#scheduled-list-modal').modal();

  $('#scheduled-list-modal').on('hidden.bs.modal', function(e) {
    e.preventDefault();
    window.location = $('.close').attr('href');
  });
})
