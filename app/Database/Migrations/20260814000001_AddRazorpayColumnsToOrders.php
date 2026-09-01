<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddRazorpayColumnsToOrders extends Migration
{
    public function up()
    {
        $this->forge->addColumn('orders', [
            'razorpay_order_id'   => ['type' => 'VARCHAR', 'constraint' => 60, 'null' => true, 'after' => 'payment_status'],
            'razorpay_payment_id' => ['type' => 'VARCHAR', 'constraint' => 60, 'null' => true, 'after' => 'razorpay_order_id'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('orders', ['razorpay_order_id', 'razorpay_payment_id']);
    }
}
