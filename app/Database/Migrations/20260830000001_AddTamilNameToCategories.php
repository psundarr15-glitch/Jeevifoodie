<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddTamilNameToCategories extends Migration
{
    public function up()
    {
        $this->forge->addColumn('categories', [
            'name_ta' => ['type' => 'VARCHAR', 'constraint' => 100, 'null' => true, 'after' => 'name'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('categories', ['name_ta']);
    }
}
