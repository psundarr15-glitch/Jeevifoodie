<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateCartItemsTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'           => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'cart_id'      => ['type' => 'INT', 'unsigned' => true],
            'menu_item_id' => ['type' => 'INT', 'unsigned' => true],
            'quantity'     => ['type' => 'INT', 'unsigned' => true, 'default' => 1],
            'price'        => ['type' => 'DECIMAL', 'constraint' => '8,2'],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('cart_id', 'carts', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addForeignKey('menu_item_id', 'menu_items', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('cart_items');
    }

    public function down()
    {
        $this->forge->dropTable('cart_items');
    }
}
