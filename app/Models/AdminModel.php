<?php

namespace App\Models;

use CodeIgniter\Model;

class AdminModel extends Model
{
    protected $table         = 'admins';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['name', 'email', 'password', 'role', 'restaurant_id'];
    protected $useTimestamps = false;
}
