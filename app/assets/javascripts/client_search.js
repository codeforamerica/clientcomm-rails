$(document).ready(function(){
  var clientSeachOptions = {
    valueNames: [ 'full-name', 'last-contact' ]
  };

  var clientList = new List('client-list', clientSeachOptions);

  $('#clear_search').click(function(){
    $('.search').val('');
    clientList.search();
  });
});
