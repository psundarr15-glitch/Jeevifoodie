<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateOrderDeclinesTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'                  => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'order_id'            => ['type' => 'INT', 'unsigned' => true],
            'delivery_partner_id' => ['type' => 'INT', 'unsigned' => true],
            'created_at'          => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('order_id', 'orders', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addForeignKey('delivery_partner_id', 'delivery_partners', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('order_declines');
    }

    public function down()
    {
        $this->forge->dropTable('order_declines');
    }
}
