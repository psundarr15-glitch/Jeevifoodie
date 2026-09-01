<?php

namespace App\Models;

use CodeIgniter\Model;

class SubCategoryModel extends Model
{
    protected $table         = 'sub_categories';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['category_id', 'restaurant_id', 'name', 'name_ta'];
    protected $useTimestamps = false;

    public function forRestaurant($restaurantId)
    {
        return $this->where('restaurant_id', $restaurantId)->findAll();
    }
}
