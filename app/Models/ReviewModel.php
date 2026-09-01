<?php

namespace App\Models;

use CodeIgniter\Model;

class ReviewModel extends Model
{
    protected $table         = 'reviews';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id', 'restaurant_id', 'delivery_partner_id', 'order_id', 'rating', 'partner_rating', 'comment'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = '';
}
