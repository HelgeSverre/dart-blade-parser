---
description: Dynamic form fields based on selection with Livewire model binding
features:
  - switch-directive
  - livewire-model
difficulty: level-1-simple
---
<div class="contact-form">
    <h2>Contact Us</h2>

    <div class="form-group">
        <label for="inquiry-type">Inquiry Type</label>
        <select wire:model="inquiryType" id="inquiry-type" class="form-control">
            <option value="general">General Question</option>
            <option value="support">Technical Support</option>
            <option value="sales">Sales Inquiry</option>
            <option value="billing">Billing Issue</option>
        </select>
    </div>

    @switch($inquiryType)
        @case('general')
            <div class="form-group">
                <label for="subject">Subject</label>
                <input wire:model="subject" type="text" id="subject" class="form-control">
            </div>
            <div class="form-group">
                <label for="message">Your Message</label>
                <textarea wire:model="message" id="message" rows="5" class="form-control"></textarea>
            </div>
            @break

        @case('support')
            <div class="form-group">
                <label for="product">Product</label>
                <select wire:model="productId" id="product" class="form-control">
                    <option value="">Select a product</option>
                </select>
            </div>
            <div class="form-group">
                <label for="issue">Describe the Issue</label>
                <textarea wire:model="issueDescription" id="issue" rows="6" class="form-control"></textarea>
            </div>
            <div class="form-group">
                <label for="priority">Priority</label>
                <select wire:model="priority" id="priority" class="form-control">
                    <option value="low">Low</option>
                    <option value="medium">Medium</option>
                    <option value="high">High</option>
                </select>
            </div>
            @break

        @case('sales')
            <div class="form-group">
                <label for="company">Company Name</label>
                <input wire:model="companyName" type="text" id="company" class="form-control">
            </div>
            <div class="form-group">
                <label for="employees">Number of Employees</label>
                <select wire:model="employeeCount" id="employees" class="form-control">
                    <option value="1-10">1-10</option>
                    <option value="11-50">11-50</option>
                    <option value="51-200">51-200</option>
                    <option value="200+">200+</option>
                </select>
            </div>
            <div class="form-group">
                <label for="budget">Estimated Budget</label>
                <input wire:model="budget" type="text" id="budget" class="form-control">
            </div>
            @break

        @case('billing')
            <div class="form-group">
                <label for="invoice">Invoice Number</label>
                <input wire:model="invoiceNumber" type="text" id="invoice" class="form-control">
            </div>
            <div class="form-group">
                <label for="issue-type">Issue Type</label>
                <select wire:model="billingIssueType" id="issue-type" class="form-control">
                    <option value="payment">Payment Problem</option>
                    <option value="refund">Refund Request</option>
                    <option value="incorrect">Incorrect Charge</option>
                </select>
            </div>
            @break
    @endswitch

    <button wire:click="submit" class="btn btn-primary">Submit Inquiry</button>
</div>
