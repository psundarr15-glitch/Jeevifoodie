<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateOrderTrackingTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'         => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'order_id'   => ['type' => 'INT', 'unsigned' => true],
            'status'     => ['type' => 'VARCHAR', 'constraint' => 40],
            'lat'        => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'lng'        => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'note'       => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('order_id', 'orders', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('order_tracking');
    }

    public function down()
    {
        $this->forge->dropTable('order_tracking');
    }
}
