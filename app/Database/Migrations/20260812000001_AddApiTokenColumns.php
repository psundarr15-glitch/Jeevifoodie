<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddApiTokenColumns extends Migration
{
    public function up()
    {
        $this->forge->addColumn('users', [
            'api_token' => ['type' => 'VARCHAR', 'constraint' => 64, 'null' => true, 'after' => 'password'],
        ]);
        $this->forge->addColumn('delivery_partners', [
            'api_token' => ['type' => 'VARCHAR', 'constraint' => 64, 'null' => true, 'after' => 'password'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('users', ['api_token']);
        $this->forge->dropColumn('delivery_partners', ['api_token']);
    }
}
