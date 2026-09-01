<?php

namespace App\Models;

use CodeIgniter\Model;

class DeliveryPartnerModel extends Model
{
    protected $table         = 'delivery_partners';
    protected $primaryKey    = 'id';
    protected $allowedFields = [
        'name', 'email', 'password', 'api_token', 'phone', 'dob', 'vehicle_number', 'photo',
        'current_lat', 'current_lng', 'is_available', 'rating', 'rating_count',
        'city', 'district', 'pincode', 'address_lat', 'address_lng',
        'aadhaar_number', 'id_proof_document', 'license_number', 'vehicle_type',
        'rc_number', 'rc_document', 'bank_account_number', 'bank_ifsc', 'bank_account_holder',
    ];
    protected $useTimestamps = false;
}
