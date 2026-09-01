<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateCouponsTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'              => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'code'            => ['type' => 'VARCHAR', 'constraint' => 30],
            'description'     => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'discount_type'   => ['type' => 'ENUM', 'constraint' => ['flat', 'percent']],
            'discount_value'  => ['type' => 'DECIMAL', 'constraint' => '8,2'],
            'min_order_value' => ['type' => 'DECIMAL', 'constraint' => '8,2', 'default' => 0],
            'max_discount'    => ['type' => 'DECIMAL', 'constraint' => '8,2', 'null' => true],
            'valid_from'      => ['type' => 'DATE', 'null' => true],
            'valid_to'        => ['type' => 'DATE', 'null' => true],
            'is_active'       => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 1],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addUniqueKey('code');
        $this->forge->createTable('coupons');
    }

    public function down()
    {
        $this->forge->dropTable('coupons');
    }
}
