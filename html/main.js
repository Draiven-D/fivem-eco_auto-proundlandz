$(document).ready(function () {
    $("section").hide();
    $("#routine").hide();
});
window.addEventListener('message', (event)=> {
    var data_type = event.data.type;
    var data_value = event.data.data;
    switch (data_type) {
        case "Open":
            $("section").fadeIn(300);
            $('#status').css("background-color", "#6bff6d");
            updateui(data_value);
            break;
        case "Exit":
            $("section").hide();
            break;
        case "Full":
            $('#status').css("background-color", "#ff0000");
            updateui(data_value);
            break;
        case "Update": 
            $('#status').css("background-color", "#6bff6d");
            updateui(data_value);
            break;
        case "ShowEvent":
            updateevent(data_value);
            $("#routine").fadeIn(300);
            break;
        case "CloseEvent":
            $("#routine").html('');
            $("#routine").hide();
            break;
        default:
            break;
    }
});
function updateui(list) {
    var app = '<img src="nui://esx_inventoryhud/html/img/items/'+ list.Item +'.png" alt="">';
    $('.imglist').html(app);
    var app2 = '<span class="percentage">' + list.Count;
    if (list.Max > 0) {
        $('#myweight').css("width", ((list.Count / list.Max) * 100) + "%");
        app2 = app2 + ' / ' + list.Max;
    } else {
        $('#myweight').css("width", "0%");
    }
    $('#myweight').html(app2 + '</span>');
    if (list.VehPlate) {
        $('#vehweight').css("width", ((list.VehCWeight / list.VehMWeight) * 100) + "%");
        $('#vehweight').html('<span class="textlist"> Vehicle Plate : ' + list.VehPlate + ' </span> <span class="percentage">' + (list.VehCWeight/1000) + ' / ' + (list.VehMWeight/1000) + ' kg</span>');
    } else {
        $('#vehweight').css("width", "0%");
        $('#vehweight').html('<span class="textlist"> Vehicle Plate : NONE </span> <span class="percentage">0 / 0 kg</span>');
    }
}

function updateevent(list) {
    $("#routine").html('');
    var html = ""
    $.each(list, function(index, value) {
        html += '<div class="event"><div class="event-name"><img src="nui://esx_inventoryhud/html/img/items/'+value.item+'.png" alt=""><div class="event-text">'+value.time+'</div></div></div>';
    });
    $("#routine").append(html);
}