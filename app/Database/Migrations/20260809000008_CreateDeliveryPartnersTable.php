<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateDeliveryPartnersTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'             => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'name'           => ['type' => 'VARCHAR', 'constraint' => 150],
            'phone'          => ['type' => 'VARCHAR', 'constraint' => 20],
            'vehicle_number' => ['type' => 'VARCHAR', 'constraint' => 30, 'null' => true],
            'photo'          => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'current_lat'    => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'current_lng'    => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'is_available'   => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 1],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->createTable('delivery_partners');
    }

    public function down()
    {
        $this->forge->dropTable('delivery_partners');
    }
}
