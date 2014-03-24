//= require store/spree_frontend
Spree.fill_in_pm_amounts = function() {
// [TODO] Please extract the logic written below into a function with an appropriate name and call same function here.
  amountDivs = $("#split-payments-data div");
  if(amountDivs.length) {
    for(i = 0; i < amountDivs.length; i++) {
      $("label.pm-amount[data-pm-id='"+ amountDivs[i].getAttribute('data-pm-id') +"']").html(amountDivs[i].getAttribute('data-pm-amount'));
    }
  }
}

Spree.find_partial_payments_total = function(value) {
  partial_payment_total = 0
  selected_partial_methods = $("input[name='order[split_payments][][payment_method_id]']:checked");
  if(selected_partial_methods.length) {
    for(i = 0; i < selected_partial_methods.length; i++) {
      partial_payment_total += parseInt($("#split-payments-data div[data-pm-id='"+ value +"']")[0].getAttribute('data-pm-amount'));
    }
  }
  return partial_payment_total;
}

Spree.disable_unchecked_partial_methods = function() {
  $("input[name='order[split_payments][][payment_method_id]']:unchecked").attr("disabled", "disabled");
}

Spree.enable_all_partial_methods = function() {
  $("input[name='order[split_payments][][payment_method_id]']").attr("disabled", false);
}

$(document).ready(function() {

  Spree.fill_in_pm_amounts();
  
  $("input[name='order[split_payments][][payment_method_id]']").click(function() {
    // [TODO] Please extract the logic written below into a function with an appropriate name and call same function here.
    // Also break into multiple functions if needed/possible.
    partial_payment_total = Spree.find_partial_payments_total($(this).val());
    
    if(partial_payment_total >= order_balance ) {
      Spree.disable_unchecked_partial_methods();
    } else {
      Spree.enable_all_partial_methods();
    }
  });
});