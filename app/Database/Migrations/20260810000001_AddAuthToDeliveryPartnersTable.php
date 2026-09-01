<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddAuthToDeliveryPartnersTable extends Migration
{
    public function up()
    {
        $this->forge->addColumn('delivery_partners', [
            'email'    => ['type' => 'VARCHAR', 'constraint' => 150, 'null' => true, 'after' => 'name'],
            'password' => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true, 'after' => 'email'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('delivery_partners', ['email', 'password']);
    }
}
