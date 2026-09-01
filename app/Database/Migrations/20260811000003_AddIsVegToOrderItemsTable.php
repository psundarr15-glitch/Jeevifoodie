<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddIsVegToOrderItemsTable extends Migration
{
    public function up()
    {
        $this->forge->addColumn('order_items', [
            'is_veg' => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 1, 'after' => 'item_name'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('order_items', ['is_veg']);
    }
}
