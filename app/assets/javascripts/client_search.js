list = {};

$(document).ready(function(){
  list = clientListInit();

  $("td.category-order").click(function() {
    elm = $(this);
    icon = $(this).children('i.category-symbol');
    name = icon.data('category-name');
    next = CATEGORIES_LINKED_LIST[name];

    elm.data('category-order', next['order']);
    list.items[elm.closest('tr').index()].values({'category-order': next['order']});
    icon.data('category-name', next['name']);
    icon.removeClass('icon-' + CATEGORIES_OBJECT[name]['icon']);
    icon.addClass('icon-' + next['icon']);
    row = elm.closest('tr');
    rr_id = row.data('reporting-relationship-id');
    updateReportingRelationship(rr_id, next['name']);
  });
});


var updateReportingRelationship = _.throttle(function(rr_id, name) {
  list.reIndex();
  $.ajax({
    type: 'PUT',
    url: '/reporting_relationships/' + rr_id,
    data: {
      reporting_relationship: {
        category: name
      }
  }});
  console.log('fire');
}, 1500, { trailing: true });

function clientListInit() {
  var clientSearchOptions = {
    valueNames: [
      { attr: 'data-category-order', name: 'category-order' },
      { attr: 'data-fullname', name: 'fullname' },
      { attr: 'data-lastname', name: 'lastname' },
      { attr: 'data-timestamp', name: 'timestamp' },
      { attr: 'data-client-status', name: 'client-status' }
    ]
  };

  var clientList = new List('client-list', clientSearchOptions);

  clientList.on('updated', function(list){
    if(list.matchingItems.length === 0){
      $('#no-search-results').show();
    } else {
      $('#no-search-results').hide();
    }
  });

  $('#clear_search').click(function(){
    $('.search').val('');
    clientList.search();
  });

  return clientList;
}
