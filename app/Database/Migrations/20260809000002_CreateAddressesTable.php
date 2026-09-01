<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateAddressesTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'           => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'user_id'      => ['type' => 'INT', 'unsigned' => true],
            'label'        => ['type' => 'VARCHAR', 'constraint' => 50, 'default' => 'Home'],
            'address_line' => ['type' => 'VARCHAR', 'constraint' => 255],
            'city'         => ['type' => 'VARCHAR', 'constraint' => 100],
            'state'        => ['type' => 'VARCHAR', 'constraint' => 100],
            'pincode'      => ['type' => 'VARCHAR', 'constraint' => 10],
            'lat'          => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'lng'          => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'is_default'   => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 0],
            'created_at'   => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('addresses');
    }

    public function down()
    {
        $this->forge->dropTable('addresses');
    }
}
