<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateMenuItemsTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'            => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'restaurant_id' => ['type' => 'INT', 'unsigned' => true],
            'category_id'   => ['type' => 'INT', 'unsigned' => true, 'null' => true],
            'name'          => ['type' => 'VARCHAR', 'constraint' => 150],
            'description'   => ['type' => 'TEXT', 'null' => true],
            'price'         => ['type' => 'DECIMAL', 'constraint' => '8,2'],
            'image'         => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'rating'        => ['type' => 'DECIMAL', 'constraint' => '2,1', 'default' => 0],
            'rating_count'  => ['type' => 'INT', 'unsigned' => true, 'default' => 0],
            'is_veg'        => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 1],
            'is_available'  => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 1],
            'created_at'    => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('restaurant_id', 'restaurants', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addForeignKey('category_id', 'categories', 'id', 'SET NULL', 'CASCADE');
        $this->forge->createTable('menu_items');
    }

    public function down()
    {
        $this->forge->dropTable('menu_items');
    }
}
