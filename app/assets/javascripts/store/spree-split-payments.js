//= require store/spree_frontend
$(document).ready(function() {
  amountDivs = $("#split-payments-data div");
  if(amountDivs.length > 0) {
    for(i = 0; i < amountDivs.length; i++) {
      $("label.pm-amount[data-pm-id='"+ amountDivs[i].getAttribute('data-pm-id') +"']").html(amountDivs[i].getAttribute('data-pm-amount'));
    }
  }

  $("input[name='order[split_payments][][payment_method_id]']").click(function() {
    selected_partial_methods = $("input[name='order[split_payments][][payment_method_id]']:checked");
    partial_payment_total = 0;
    if(selected_partial_methods.length > 0) {
      for(i = 0; i < selected_partial_methods.length; i++) {
        partial_payment_total += parseInt($("#split-payments-data div[data-pm-id='"+ $(this).val() +"']")[0].getAttribute('data-pm-amount'));
      }
    }
    if(partial_payment_total >= order_balance ) {
      $("input[name='order[split_payments][][payment_method_id]']:unchecked").attr("disabled", "disabled");
    } else {
      $("input[name='order[split_payments][][payment_method_id]']").attr("disabled", false);
    }
  });
});