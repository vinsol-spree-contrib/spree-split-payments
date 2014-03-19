Deface::Override.new(
  virtual_path: 'spree/admin/payment_methods/_form',
  name: 'add partial payment form fields',
  insert_after: "[data-hook='active']",
  text: %q{
    <div data-hook="for_partial" class="field">
      <%= label_tag nil, Spree.t(:supports_partial_payment) %>
      <ul>
        <li>
          <%= radio_button :payment_method, :for_partial, true %>
          <%= label_tag nil, Spree.t(:say_yes) %>
        </li>
        <li>
          <%= radio_button :payment_method, :for_partial, false %>
          <%= label_tag nil, Spree.t(:say_no) %>
        </li>
      </ul>
    </div>
    <div data-hook="partial_priority" class="field">
      <%= label_tag nil, Spree.t(:partial_priority) %>
      <%= select_tag "payment_method[partial_priority]",
          options_for_select(1..5, @object.partial_priority) %>
    </div>
  })
