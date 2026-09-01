<?php

namespace App\Models;

use CodeIgniter\Model;

class RestaurantLikeModel extends Model
{
    protected $table         = 'restaurant_likes';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id', 'restaurant_id'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = '';
}
