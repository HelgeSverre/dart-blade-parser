{{--
features: [if, blade-directives, control-structures, deep-nesting]
complexity: high
lines: 45
valid: true
description: Deeply nested @if directives testing realistic permission and role-based access control with 10 levels of nesting
--}}

<div class="admin-panel">
  @if ($user->isAuthenticated())
    <div class="user-section">
      @if ($user->hasRole('admin'))
        <div class="admin-controls">
          @if ($user->hasPermission('manage_users'))
            <div class="user-management">
              @if ($organization->isActive())
                <div class="org-settings">
                  @if ($organization->hasPlan('enterprise'))
                    <div class="enterprise-features">
                      @if ($user->can('manage_billing'))
                        <div class="billing-section">
                          @if ($organization->paymentMethod->isValid())
                            <div class="payment-options">
                              @if ($user->hasPermission('view_invoices'))
                                <div class="invoice-history">
                                  @if ($invoices->count() > 0)
                                    <table class="invoice-table">
                                      <thead>
                                        <tr>
                                          <th>Invoice #</th>
                                          <th>Date</th>
                                          <th>Amount</th>
                                          <th>Status</th>
                                        </tr>
                                      </thead>
                                      <tbody>
                                        @foreach ($invoices as $invoice)
                                          <tr>
                                            <td>{{ $invoice->number }}</td>
                                            <td>{{ $invoice->date }}</td>
                                            <td>${{ $invoice->amount }}</td>
                                            <td>{{ $invoice->status }}</td>
                                          </tr>
                                        @endforeach
                                      </tbody>
                                    </table>
                                  @endif
                                </div>
                              @endif
                            </div>
                          @endif
                        </div>
                      @endif
                    </div>
                  @endif
                </div>
              @endif
            </div>
          @endif
        </div>
      @endif
    </div>
  @endif
</div>
