<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddWalletToUsers extends Migration
{
    public function up()
    {
        $this->forge->addColumn('users', [
            'wallet_balance' => ['type' => 'DECIMAL', 'constraint' => '10,2', 'default' => 0.00, 'after' => 'phone'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('users', ['wallet_balance']);
    }
}
