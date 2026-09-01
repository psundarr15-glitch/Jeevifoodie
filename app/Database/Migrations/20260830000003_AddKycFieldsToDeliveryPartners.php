<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddKycFieldsToDeliveryPartners extends Migration
{
    public function up()
    {
        $this->forge->addColumn('delivery_partners', [
            'dob'                 => ['type' => 'DATE', 'null' => true, 'after' => 'phone'],
            'city'                => ['type' => 'VARCHAR', 'constraint' => 100, 'null' => true],
            'district'            => ['type' => 'VARCHAR', 'constraint' => 100, 'null' => true],
            'pincode'             => ['type' => 'VARCHAR', 'constraint' => 10, 'null' => true],
            'address_lat'         => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'address_lng'         => ['type' => 'DECIMAL', 'constraint' => '10,7', 'null' => true],
            'aadhaar_number'      => ['type' => 'VARCHAR', 'constraint' => 20, 'null' => true],
            'id_proof_document'   => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'license_number'      => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true],
            'vehicle_type'        => ['type' => 'VARCHAR', 'constraint' => 30, 'null' => true],
            'rc_number'           => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true],
            'rc_document'         => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => true],
            'bank_account_number' => ['type' => 'VARCHAR', 'constraint' => 50, 'null' => true],
            'bank_ifsc'           => ['type' => 'VARCHAR', 'constraint' => 20, 'null' => true],
            'bank_account_holder' => ['type' => 'VARCHAR', 'constraint' => 150, 'null' => true],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('delivery_partners', [
            'dob', 'city', 'district', 'pincode', 'address_lat', 'address_lng',
            'aadhaar_number', 'id_proof_document', 'license_number', 'vehicle_type',
            'rc_number', 'rc_document', 'bank_account_number', 'bank_ifsc', 'bank_account_holder',
        ]);
    }
}
