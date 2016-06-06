# [TODO] 1..5 value in select code should not be hardcoded.
Deface::Override.new(
  virtual_path: 'spree/admin/payment_methods/_form',
  name: 'add partial payment form fields',
  insert_after: "[data-hook='active']",
  text: %q{
    <div data-hook="for_partial" class="form-group">
      <strong><%= Spree.t(:supports_partial_payment) %></strong>
      <div class="radio">
        <%= label_tag :payment_method_for_partial_true do %>
          <%= radio_button :payment_method, :for_partial, true %>
          <%= Spree.t(:say_yes) %>
        <% end %>
      </div>

      <div class="radio">
        <%= label_tag :payment_method_for_partial_false do %>
          <%= radio_button :payment_method, :for_partial, false %>
          <%= Spree.t(:say_no) %>
        <% end %>
      </div>
    </div>

    <div data-hook="partial_priority" class="form-group">
      <%= label_tag nil, Spree.t(:partial_priority) %>
      <%= select_tag "payment_method[partial_priority]",
          options_for_select(1..5, @object.partial_priority) %>
    </div>
  })
