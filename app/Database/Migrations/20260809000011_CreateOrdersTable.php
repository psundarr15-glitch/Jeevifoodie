<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateOrdersTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'                     => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'order_code'             => ['type' => 'VARCHAR', 'constraint' => 20],
            'user_id'                => ['type' => 'INT', 'unsigned' => true],
            'restaurant_id'          => ['type' => 'INT', 'unsigned' => true],
            'address_id'             => ['type' => 'INT', 'unsigned' => true, 'null' => true],
            'delivery_partner_id'    => ['type' => 'INT', 'unsigned' => true, 'null' => true],
            'coupon_id'              => ['type' => 'INT', 'unsigned' => true, 'null' => true],
            'subtotal'               => ['type' => 'DECIMAL', 'constraint' => '8,2', 'default' => 0],
            'discount'               => ['type' => 'DECIMAL', 'constraint' => '8,2', 'default' => 0],
            'delivery_fee'           => ['type' => 'DECIMAL', 'constraint' => '8,2', 'default' => 0],
            'total'                  => ['type' => 'DECIMAL', 'constraint' => '8,2', 'default' => 0],
            'payment_method'         => ['type' => 'ENUM', 'constraint' => ['cod', 'card', 'upi'], 'default' => 'cod'],
            'payment_status'         => ['type' => 'ENUM', 'constraint' => ['pending', 'paid', 'failed'], 'default' => 'pending'],
            'order_status'           => ['type' => 'ENUM', 'constraint' => ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'], 'default' => 'placed'],
            'estimated_delivery_min' => ['type' => 'INT', 'unsigned' => true, 'default' => 30],
            'placed_at'              => ['type' => 'DATETIME', 'null' => true],
            'delivered_at'           => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addUniqueKey('order_code');
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addForeignKey('restaurant_id', 'restaurants', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('orders');
    }

    public function down()
    {
        $this->forge->dropTable('orders');
    }
}
