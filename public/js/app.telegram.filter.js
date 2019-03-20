"use strict";

var app = app || {};
app.telegram = app.telegram || {};
app.telegram.filter = app.telegram.filter || {};

app.telegram.filter = (function (NS) {

  $ = jQuery;

  $.fn.telegram_type_tree = function(param) {

    param = $.extend({
      uiLibrary: 'bootstrap',
      lazyLoading: true,
      paramNames: {
        parentId: 'path'
      },
      selectionType: 'single',
      primaryKey: 'path',
      iconsLibrary: 'fontawesome',
      icons: {
        expand: '<i class="fa fa-chevron-right"></i>',
        collapse: '<i class="fa fa-chevron-down"></i>'
      }
    }, param);

    return this.each(function(i, el) {
    
      var treeID = $(el).attr('id');
      var formID = $(el).attr('data-related-form');
      var tree = $(el).tree(param);
      
      tree.on('nodeDataBound', function (e, node, id, record) {
        node.prop('jsonpath', record.path);
        node.prop('fieldtype', record.type);
      });

      tree.on('select', function (e, node, id) {
        $('.js-btn-select[data-tree="'+treeID+'"]').remove();
        $('#select-operation').find('option').remove();
        $('.js-operation-negation[data-tree="'+treeID+'"]').prop({checked: false});
        $('.js-filter-operands[data-tree="'+treeID+'"]').html('');
        $('[data-id="'+id+'"] > [data-role="wrapper"] > [data-role="display"]').before(
          $('<button>')
            .addClass('btn btn-warning js-btn-select')
            .attr({"data-tree": treeID})
            .html('<i class="fa fa-check"></i>')
            .on('click', function() {
              $('.js-tree-path[data-tree="'+treeID+'"]').val(node.prop('jsonpath'));
              NS.load_operations({
                url: param.operationSource,
                path: node.prop('jsonpath'),
                select: $('#select-operation'),
                operands: $('.js-filter-operands[data-tree="'+treeID+'"]')
              });
              tree.collapseAll();
            })
        );
      });

      tree.on('unselect', function (e, node, id) {
        $('.js-btn-select[data-tree="'+treeID+'"]').remove();
        $('.js-filter-operands[data-tree="'+treeID+'"]').html('');
        $('#select-operation').find('option').remove();
        $('.js-operation-negation[data-tree="'+treeID+'"]').prop({checked: false});
      });

      $('.js-tree-path-clear[data-tree="'+treeID+'"]').on('click', function(){
        $('.js-tree-path[data-tree="'+treeID+'"]').val('');
        $('#select-operation').find('option').remove();
        $('.js-operation-negation[data-tree="'+treeID+'"]').prop({checked: false});
        $('.js-filter-operands[data-tree="'+treeID+'"]').html('');
      });

      $('#select-operation').on('change', function(){
		    var op = $('#'+this.id+' option:selected');
				if (typeof(op)!=="undefined") {
          $('.js-filter-operands[data-tree="'+treeID+'"]').html('');
          var optype = op.prop("data-type");
          if (optype=="text") {
            $('.js-filter-operands[data-tree="'+treeID+'"]').append(              // add to div class="operation-operands"
              $('<div>').addClass('form-group').append(   // div class="form-group"
                $('<label>').text(op.prop("data-label")), // with label
                $('<div id="fld-values">').append(        // and inputs
                  $('<input>').addClass('form-control').attr({"name": "value", "type": "text", "data-form": formID})
                )
              )
            );
            if (op.prop("data-multiple")) {
              $('.js-filter-operands[data-tree="'+treeID+'"]').append(              // add to div class="operation-operands"
                $('<div>').addClass('form-group').append(   // with button for adding inputs
                  $('<span>').attr({id: "fld-value-add"}).addClass("btn btn-default btn-outline btn-sm").append(
                    $('<i>').addClass("fa fa-plus")
                  ).on('click', function() {
                    $('#fld-values').append('<p>').append(
                      $('<input>').addClass('form-control').attr({"name": "value", "type": "text", "data-form": formID})
                    )
                  })
                )
              );
            }
          }
          else if (optype=="radio") {
            $('.js-filter-operands[data-tree="'+treeID+'"]').append(
              $('<div>').addClass('form-group').append(
                $('<label>').text(op.prop("data-label")),
                op.prop("data-options").map(function(el){
                  return $('<div>').addClass('radio').append(
                    $('<label>').append(
                      $('<input>').attr({"name": "value", "type": "radio", "data-form": formID}).val(el),
                      $('<span>').text(op.prop("data-tl")[el])
                    )
                  );
                })
              )
            );
          }
          else if (optype=="multiselect") {
            $('.js-filter-operands[data-tree="'+treeID+'"]').append(
              $('<div>').addClass('form-group').append(
                $('<label>').text(op.prop("data-label")),
                $('<select>').attr({"multiple":"", "name": "value", "data-form": formID}).addClass('form-control').append(
                  op.prop("data-options").map(function(el) {
                    return $('<option>').val(el).text(el);
                  })
                )
              )
            );
          }
        }
			});

    });

  };

  /*
   * USAGE:
   * app.telegram.filter.load_operations({
   *  url: "http://hostname/method_load_operations",
   *  path: "update.message.id",
   *  select: "element_id_of_operations_select",
   *  operands: "element_id_for_values_form_elements"
   * })
   *
   */
  NS.load_operations = function(param) {
    $.ajax({
      type: "GET",
      url: param.url,
      dataType: "json",
      data: {
        path: param.path
      },
      contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
      beforeSend: function(xhr, data) {
        param.select.closest('div.form-group').removeClass('has-success has-danger').addClass('has-warning');
      },
      success: function(data, status, xhr) {
        param.select.find('option').remove();
        param.select.append($('<option>'));
        $(data).each(function(index, el){
          param.select.append($('<option>').val(el.id).text(el.name).prop({
            "data-type": el.type,
            "data-options": el.options,
            "data-label": el.label,
            "data-tl": el.tl,
            "data-multiple": el.multiple
          }));
        });
        param.operands.html('');
        param.select.closest('div.form-group').removeClass('has-warning has-danger').addClass('has-success');
      },
      error: function(xhr, status, error) {
        param.select.closest('div.form-group').removeClass('has-success has-warning').addClass('has-danger');
      }
    });

  };

  return NS;

} (app.telegram.filter || {}));

