<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddRoutingToChatMessages extends Migration
{
    public function up()
    {
        $this->forge->addColumn('chat_messages', [
            // Which inbox this thread belongs to: the app owner's general
            // support inbox, or a specific restaurant's manager inbox.
            'recipient_role' => ['type' => 'ENUM', 'constraint' => ['admin', 'manager'], 'default' => 'admin', 'after' => 'user_id'],
            // Set only for recipient_role = 'manager' threads — which
            // restaurant this conversation is about. NULL for admin threads.
            'restaurant_id'  => ['type' => 'INT', 'unsigned' => true, 'null' => true, 'after' => 'recipient_role'],
        ]);
        $this->forge->addKey('restaurant_id', false, false, 'chat_messages');
        $this->forge->addForeignKey('restaurant_id', 'restaurants', 'id', 'CASCADE', 'CASCADE', 'chat_messages');
    }

    public function down()
    {
        $this->forge->dropForeignKey('chat_messages', 'chat_messages_restaurant_id_foreign');
        $this->forge->dropColumn('chat_messages', ['recipient_role', 'restaurant_id']);
    }
}
