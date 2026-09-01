<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateRestaurantsTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'             => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'name'           => ['type' => 'VARCHAR', 'constraint' => 150],
            'description'    => ['type' => 'TEXT', 'null' => true],
            'image'          => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'cuisine'        => ['type' => 'VARCHAR', 'constraint' => 150, 'null' => true],
            'rating'         => ['type' => 'DECIMAL', 'constraint' => '2,1', 'default' => 0],
            'rating_count'   => ['type' => 'INT', 'unsigned' => true, 'default' => 0],
            'prep_time_min'  => ['type' => 'INT', 'unsigned' => true, 'default' => 20],
            'prep_time_max'  => ['type' => 'INT', 'unsigned' => true, 'default' => 40],
            'cost_for_two'   => ['type' => 'INT', 'unsigned' => true, 'default' => 0],
            'discount_label' => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true],
            'address'        => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'lat'            => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'lng'            => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'is_active'      => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 1],
            'created_at'     => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->createTable('restaurants');
    }

    public function down()
    {
        $this->forge->dropTable('restaurants');
    }
}
