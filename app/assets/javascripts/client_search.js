list = {};

$(document).ready(function(){
  clientListInit();
});

function clientListInit() {
  var clientSearchOptions = {
    valueNames: [
      { attr: 'data-category-order', name: 'category-order' },
      { attr: 'data-fullname', name: 'fullname' },
      { attr: 'data-lastname', name: 'lastname' },
      { attr: 'data-timestamp', name: 'timestamp' },
      { attr: 'data-client-status', name: 'client-status' },
      { attr: 'data-next-court-date-at', name: 'next-court-date-at' },
      { attr: 'data-scheduled-message-count', name: 'scheduled-message-count' }
    ]
  };

  var list = new List('client-list', clientSearchOptions);

  $('.sort').click(function(e) {
    order = $(this).hasClass('asc') ? 'ascending' : 'descending'

    $.post({
      url: '/tracking_events',
      data: {
        label: 'clients_sort',
        data: {
          sort_by: $(this).data('sort'),
          order: order
        }
      }
    })
  });

  list.on('updated', function(list){
    if(list.matchingItems.length === 0){
      $('#no-search-results').show();
    } else {
      $('#no-search-results').hide();
    }
  });

  $('#clear_search').click(function(){
    $('.search').val('');
    list.search();
  });

  $("td.category-order").each(function(i, column) {
    column = $(column);
    row = column.closest('tr');
    var rr_id = row.data('reporting-relationship-id');

    var updateReportingRelationship = _.debounce(function(name) {
      $.ajax({
        type: 'PUT',
        url: '/conversations/' + rr_id,
        data: {
          reporting_relationship: {
            category: name
          }
      }});
    }, 1500, { trailing: true });

    column.click(function() {
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
      updateReportingRelationship(next['name']);
    });
  });

  return list;
}
