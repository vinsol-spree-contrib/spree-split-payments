SplitPayments = {
  initialize: function() {
    this.non_partial_payment_methods = $("[name='order[payments_attributes][0][payment_method_id]']");
    this.handleFormSubmission();
    this.handleClickOnNonPartialPaymentMethod();
    this.handlePartialPayments();
    this.hidePaymentDetails();
    if(typeof(order_balance) != 'undefined') {
      order_balance = order_balance.toFixed(4);
    }
  },

  handlePartialPayments: function() {
    $('.partial_payment_method').click(function() {
      var $payment_amount = $('#payment_method_' + $(this).val() + '_amount');
      if(this.checked) {
        $payment_amount.attr('name', $payment_amount.data('name'));
      } else {
        $payment_amount.attr('name', '');
      }
    })
  },

  showPaymentDetails: function(pm_id) {
    $('#payment_method_' + pm_id).show();
  },

  handleClickOnNonPartialPaymentMethod: function() {
    var self = this;
    $("[type='checkbox'][name*='payment_method_id']").click(function() {
      if(this.checked) {
        self.showPaymentDetails($(this).val());
      } else {
        self.hidePaymentDetails([$(this).val()]);
      }
    });
    $("[type='radio'][name*='payment_method_id']").click(function() {
      var non_partial_payment_method_ids = self.non_partial_payment_methods.map(function(index, pm) { return $(pm).val(); })
      self.hidePaymentDetails(non_partial_payment_method_ids);
      self.showPaymentDetails($(this).val());
    })
  },

  hidePaymentDetails: function(pm_ids) {
    pm_ids = pm_ids || [""]
    $.each(pm_ids, function(index, pm_id) {
      $('#payment-methods li[id^="payment_method_' + pm_id + '"]').hide()
    })
  },

  uncheckNonPartialPaymentMethod: function() {
    this.non_partial_payment_methods.prop('checked', false)
    this.hidePaymentDetails();
  },

  amount: function() {
    var sum = 0
    $("input[type='checkbox'][name*='payment_method_id']:checked").each(function() {
      sum += +($("[name='order[payments_attributes][" + $(this).val() + "][amount]']").val())
    });
    return sum.toFixed(4);
  },

  checkOrderTotal: function() {
    var amount = this.amount();
    if(amount > order_balance) {
      alert('exceeding order total');
    } else if(amount == order_balance) {
      this.uncheckNonPartialPaymentMethod();
      return true;
    } else {
       if(!this.non_partial_payment_methods.filter(':checked').length) {
        alert('Please select a payment method with appropriate amount to proceed further');
      } else {
        return true;
      }
    }
  },

  handleFormSubmission: function() {
    var self = this, amount = this.amount();
    $('#checkout_form_payment input[type="submit"]').click(function(event) {
      if(!self.checkOrderTotal()) {
        event.preventDefault();
        return false;
      }
    });
  }
}

$(document).ready(function() {
  SplitPayments.initialize();
});

