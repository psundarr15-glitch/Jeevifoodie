<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddOwnerAndComplianceFieldsToRestaurants extends Migration
{
    public function up()
    {
        $this->forge->addColumn('restaurants', [
            'owner_name'          => ['type' => 'VARCHAR', 'constraint' => 150, 'null' => true, 'after' => 'name'],
            'owner_phone'         => ['type' => 'VARCHAR', 'constraint' => 20, 'null' => true, 'after' => 'phone'],
            'restaurant_type'     => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true, 'after' => 'cuisine'],
            'food_type'           => ['type' => 'ENUM', 'constraint' => ['veg', 'non_veg', 'both'], 'default' => 'both', 'after' => 'restaurant_type'],
            'fssai_number'        => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true],
            'fssai_certificate'   => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'tin_number'          => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true],
            'tin_certificate'     => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'logo'                => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true, 'after' => 'image'],
            'bank_account_number' => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true],
            'bank_ifsc'           => ['type' => 'VARCHAR', 'constraint' => 20, 'null' => true],
            'bank_account_holder' => ['type' => 'VARCHAR', 'constraint' => 150, 'null' => true],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('restaurants', [
            'owner_name', 'owner_phone', 'restaurant_type', 'food_type',
            'fssai_number', 'fssai_certificate', 'tin_number', 'tin_certificate',
            'logo', 'bank_account_number', 'bank_ifsc', 'bank_account_holder',
        ]);
    }
}
