<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddPasswordResetToUsers extends Migration
{
    public function up()
    {
        $this->forge->addColumn('users', [
            'reset_otp'            => ['type' => 'VARCHAR', 'constraint' => 6, 'null' => true, 'after' => 'api_token'],
            'reset_otp_expires_at' => ['type' => 'DATETIME', 'null' => true, 'after' => 'reset_otp'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('users', ['reset_otp', 'reset_otp_expires_at']);
    }
}
