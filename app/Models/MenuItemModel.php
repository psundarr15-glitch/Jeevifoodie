<?php

namespace App\Models;

use CodeIgniter\Model;

class MenuItemModel extends Model
{
    protected $table         = 'menu_items';
    protected $primaryKey    = 'id';
    protected $allowedFields = [
        'restaurant_id', 'category_id', 'sub_category_id', 'name', 'description', 'price',
        'image', 'rating', 'rating_count', 'is_veg', 'is_available',
    ];
    protected $useTimestamps = false;

    public function forRestaurant($restaurantId)
    {
        // Show every item, in/out of stock — the customer-facing views mark
        // unavailable ones as "Out of Stock" with ordering disabled rather
        // than hiding them, so people can see the full menu and check back.
        return $this->where('restaurant_id', $restaurantId);
    }
}
