<?= $this->extend('customer/layouts/main') ?>
<?= $this->section('content') ?>

<div class="row justify-content-center">
    <div class="col-md-6">
        <div class="card card-jeevi p-4 text-center">
            <h4 class="section-title mb-3">Complete Your Payment</h4>
            <h2 class="fw-bold mb-4">₹<?= number_format($total, 2) ?></h2>

            <button id="payNowBtn" class="btn btn-jeevi btn-lg w-100">Pay Now</button>
            <p class="small text-muted mt-3 mb-0">Your order will be placed only after payment is confirmed. You'll be redirected to complete payment securely via Razorpay.</p>

            <div id="payError" class="alert alert-danger mt-3" style="display:none;"></div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
<script>
document.getElementById('payNowBtn').addEventListener('click', function () {
    const options = {
        key: "<?= esc($razorpayKeyId, 'js') ?>",
        amount: <?= (int) round($total * 100) ?>,
        currency: "INR",
        name: "Jeevi Foodie Delivery",
        description: "Order payment",
        order_id: "<?= esc($razorpayOrderId, 'js') ?>",
        handler: function (response) {
            fetch("<?= base_url('checkout/payment/verify') ?>", {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    razorpay_order_id: response.razorpay_order_id,
                    razorpay_payment_id: response.razorpay_payment_id,
                    razorpay_signature: response.razorpay_signature,
                    "<?= csrf_token() ?>": "<?= csrf_hash() ?>"
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    window.location.href = data.redirect_url;
                } else {
                    document.getElementById('payError').textContent = data.message || 'Payment verification failed. Your order was NOT placed.';
                    document.getElementById('payError').style.display = 'block';
                }
            });
        },
        prefill: {
            name: "<?= esc(session()->get('user_name'), 'js') ?>"
        },
        theme: { color: "#E31E24" },
        modal: {
            ondismiss: function () {
                // Customer closed the popup without paying — nothing was ever
                // created, so just leave them here to try again if they want.
            }
        }
    };

    const rzp = new Razorpay(options);
    rzp.on('payment.failed', function (response) {
        document.getElementById('payError').textContent = 'Payment failed: ' + response.error.description + '. Your order was NOT placed.';
        document.getElementById('payError').style.display = 'block';
    });
    rzp.open();
});
</script>
<?= $this->endSection() ?>
