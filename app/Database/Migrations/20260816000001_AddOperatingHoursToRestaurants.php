<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddOperatingHoursToRestaurants extends Migration
{
    public function up()
    {
        $this->forge->addColumn('restaurants', [
            'opening_time' => ['type' => 'TIME', 'null' => true, 'after' => 'is_active'],
            'closing_time' => ['type' => 'TIME', 'null' => true, 'after' => 'opening_time'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('restaurants', ['opening_time', 'closing_time']);
    }
}
