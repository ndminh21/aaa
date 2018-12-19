/*
* @Author: halink0803
* @Date:   2017-04-15 14:03:56
* @Last Modified by:   ha.h
* @Last Modified time: 2017-05-23 17:02:12
*/

var l = $('.button-confirm').ladda();
$(".button-confirm").click(function(event){
    l.ladda('start');
    transport_id = $("a.order-number[aria-expanded=true]").attr("transport-id");
    console.log(transport_id)
    if( !transport_id ) {
        transport_id = $('.title').attr("transport-id")
    }
    switch($(this).attr('id')) {
         case 'confirm-accept':
            state = 'confirmed';
            break;
        case 'confirm-reject':
            state = 'rejected';
            break;
        case 'confirm-picked':
            state = 'shipping';
            break;
        case 'confirm-success':
            state = 'ok';
            break;
        case 'confirm-retry':
            state = 'retry';
            break;
        case 'confirm-failure':
            state = 'failed';
            break;
    }
    reason = ''
    switch(state) {
        case 'rejected':
            reason = $("input[name=reason]").val();
            break;
        case 'retry':
            reason = $("input[name='retry-reason']").val();
            break;
        case 'failed':
            reason = $("input[name='failed-reason']").val();
            break;
    }

	data = {
        'transport_id': transport_id,
        'state': state
	};
    if( reason ) {
        data.reason = reason;
    }
    $.ajax({
    	method: "POST",
    	url: "/m/index",
    	data: data,
    	success: function(result){
            l.ladda('stop');
            if(result.update) {
                $('.modal.in .modal-body').append('<p class="alert alert-success">Xác nhận thành công</p>');
                setTimeout(function(){
                    $('.modal.in').modal('hide');
                    location.reload()
                }, 500);
            } else {
                $('.modal.in ').append('<p class="alert alert-error">Xác nhận không thành công</p>');
            }
    	}
	});
});

var lab = $('#confirm-re-assign').ladda();
$("#confirm-re-assign").click(function(event){
    lab.ladda('start');
    transport_id = $("a.order-number[aria-expanded=true]").attr("transport-id");
    shipper_id = $('#shipper_id').val()
    if( !transport_id ) {
        transport_id = $('.title').attr("transport-id")
    }

    data = {
        'transport_id': transport_id,
        'shipper_id': shipper_id
    };

    $.ajax({
        method: "POST",
        url: "/m/re-assign",
        data: data,
        success: function(result){
            lab.ladda('stop');
            console.log(result)
            if(result.update) {
                $('.modal.in .modal-body').append('<p class="alert alert-success">Xác nhận thành công</p>');
                setTimeout(function(){
                    $('.modal.in').modal('hide');
                    location.reload()
                }, 500);
            } else {
                $('.modal.in ').append('<p class="alert alert-error">Xác nhận không thành công</p>');
            }
        }
    });
});

$('.transport_note').click(function(e) {
    console.log(e.target)
    transport = e.target.getAttribute('transport');
    target = $("a[transport-id="+ transport +"]");
    tab = target.closest('.tab-pane').attr('id');
    $("a[href=#"+ tab +"]").tab('show');
    $(target.attr('href')).collapse('show');
})

$('#mobile-search-form').submit(function(event) {
    $('#loading-effect').toggleClass('hidden');
});

$("#shipper_input").autocomplete({
    source:function(request, response) {
        console.log(request);
        console.log('1');
        $.getJSON("/autocomplete",{
            q: request.term, // in flask, "q" will be the argument to look for using request.args
        }, function(data) {
            response($.map(data.fullname_id_list, function(object){
                return {
                    label: object.fullname,
                    value: object.fullname,
                    id: object.id,
                    email: object.email,
                    phone: object.phone
                };
            }));

        });
    },
    minLength: 1,
    select: function(event, ui) {
        console.log(ui.item); // not in your question, but might help later
        $('#shipper_id').val(ui.item.id);
        $('.info-shipment-div').html(
            '<p> ' +
            '<b>Họ tên:</b> ' + ui.item.label +
            '</p> <p> ' +
            '<b>Điện thoại:</b> ' + ui.item.phone +
            '</p> <p> ' +
            '<b>Email:</b> ' + ui.item.email +
            '</p>'
        );
        $('.info-shipment').show();
    }
});

$("#mobile-search").autocomplete({
    source:function(request, response) {
        $('#loading-effect').toggleClass('hidden');
        $.getJSON("/m/search",{
            query: request.term, // in flask, "q" will be the argument to look for using request.args
        }, function(data) {
            $('#loading-effect').toggleClass('hidden');
            var transports_array = $.map(data.results, function(object) {
                return [object.id];
            })
            var transports = $('#accordion-0 .order-number');
            transports.each(function(index) {
                var transport_id = $(this).attr('transport-id');
                var panel = $(this).closest('.panel');
                if( $.inArray( parseInt(transport_id), transports_array) == -1 ) {
                    if( ! panel.hasClass('hidden') ) {
                        panel.addClass('hidden');
                    }
                } else {
                    if( panel.hasClass('hidden') ) {
                        panel.removeClass('hidden');
                    }
                }
            });
            response($.map(data.results, function(object){
                return {
                    label: "Đơn hàng: " + object.id,
                    value: object.id,
                    id: object.id,
                };
            }));
        });
    },
    minLength: 1,
    select: function(event, ui) {
        console.log(ui.item); // not in your question, but might help later
        target = $("a[transport-id="+ ui.item.id +"]");
        tab = target.closest('.tab-pane').attr('id');
        $("a[href=#"+ tab +"]").tab('show');
        $(target.attr('href')).collapse('show');
    }
});

$("#mobile-search").focus(function() {
    $('.menu-tabs').scrollLeft('0');
    $("a[href=#home-0]").tab("show");
});
$("#mobile-search").focusout(function() {
    var transports = $('#accordion-0 .order-number');
    transports.each(function(index) {
        var panel = $(this).closest('.panel');
        if( panel.hasClass('hidden') ) {
            panel.removeClass('hidden');
        }
    });
});
$(document).ready(function() {
    function getParameterByName(name, url) {
        if (!url) url = window.location.href;
        name = name.replace(/[\[\]]/g, "\\$&");
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }
    var transport = getParameterByName('transport');
    if(transport != '') {
        target = $("a[transport-id="+ transport +"]");
        tab = target.closest('.tab-pane').attr('id');
        $("a[href=#"+ tab +"]").tab('show');
        $(target.attr('href')).collapse('show');
    }
})
