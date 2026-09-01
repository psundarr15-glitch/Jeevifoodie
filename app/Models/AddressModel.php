<?php

namespace App\Models;

use CodeIgniter\Model;

class AddressModel extends Model
{
    protected $table         = 'addresses';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id', 'label', 'address_line', 'city', 'state', 'pincode', 'lat', 'lng', 'is_default'];
    protected $useTimestamps = false;
    protected $dateFormat    = 'datetime';
}
