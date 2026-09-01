<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateDeviceTokensTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'         => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'auto_increment' => true],
            'user_id'    => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true],
            'fcm_token'  => ['type' => 'VARCHAR', 'constraint' => 255],
            'platform'   => ['type' => 'VARCHAR', 'constraint' => 20, 'default' => 'android'],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addKey('user_id');
        $this->forge->addUniqueKey(['user_id', 'fcm_token']);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('device_tokens');
    }

    public function down()
    {
        $this->forge->dropTable('device_tokens');
    }
}
