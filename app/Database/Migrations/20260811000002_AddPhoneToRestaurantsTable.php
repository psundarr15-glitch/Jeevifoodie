<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddPhoneToRestaurantsTable extends Migration
{
    public function up()
    {
        $this->forge->addColumn('restaurants', [
            'phone' => ['type' => 'VARCHAR', 'constraint' => 20, 'null' => true, 'after' => 'name'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('restaurants', ['phone']);
    }
}
