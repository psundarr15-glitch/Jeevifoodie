<?php

namespace App\Models;

use CodeIgniter\Model;

class CartItemModel extends Model
{
    protected $table         = 'cart_items';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['cart_id', 'menu_item_id', 'quantity', 'price'];
    protected $useTimestamps = false;

    public function itemsWithDetails($cartId)
    {
        return $this->select('cart_items.*, menu_items.name, menu_items.image, menu_items.is_veg, menu_items.is_available')
                    ->join('menu_items', 'menu_items.id = cart_items.menu_item_id')
                    ->where('cart_id', $cartId)
                    ->findAll();
    }
}
