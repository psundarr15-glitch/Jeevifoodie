<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddPartnerRatingColumns extends Migration
{
    public function up()
    {
        // Reviews now optionally rate the delivery partner too, alongside
        // the restaurant rating that was already there.
        $this->forge->addColumn('reviews', [
            'delivery_partner_id' => ['type' => 'INT', 'unsigned' => true, 'null' => true, 'after' => 'restaurant_id'],
            'partner_rating'      => ['type' => 'TINYINT', 'unsigned' => true, 'null' => true, 'after' => 'rating'],
        ]);

        // delivery_partners never had rating columns at all — add them so
        // there's somewhere to store the recomputed average.
        $this->forge->addColumn('delivery_partners', [
            'rating'       => ['type' => 'DECIMAL', 'constraint' => '2,1', 'default' => 0, 'after' => 'is_available'],
            'rating_count' => ['type' => 'INT', 'unsigned' => true, 'default' => 0, 'after' => 'rating'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('reviews', ['delivery_partner_id', 'partner_rating']);
        $this->forge->dropColumn('delivery_partners', ['rating', 'rating_count']);
    }
}
