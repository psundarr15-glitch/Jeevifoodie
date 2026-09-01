<?php

namespace App\Models;

use CodeIgniter\Model;

class CartModel extends Model
{
    protected $table         = 'carts';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id', 'restaurant_id'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    public function activeCartFor($userId)
    {
        return $this->where('user_id', $userId)->orderBy('id', 'DESC')->first();
    }
}
