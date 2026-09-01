<?php

namespace App\Models;

use CodeIgniter\Model;

class UserModel extends Model
{
    protected $table            = 'users';
    protected $primaryKey       = 'id';
    protected $allowedFields    = ['name', 'email', 'phone', 'password', 'api_token', 'wallet_balance', 'reset_otp', 'reset_otp_expires_at'];
    protected $useTimestamps    = true;
    protected $createdField     = 'created_at';
    protected $updatedField     = 'updated_at';
    protected $validationRules  = [
        'name'  => 'required|min_length[2]',
        'email' => 'required|valid_email|is_unique[users.email,id,{id}]',
        'phone' => 'required|min_length[10]',
    ];
}
