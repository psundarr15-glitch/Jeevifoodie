<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\CartModel;
use App\Models\CartItemModel;
use App\Models\MenuItemModel;

class CartController extends BaseController
{
    protected function getOrCreateCart($userId, $restaurantId)
    {
        $cartModel = new CartModel();
        $cart = $cartModel->where('user_id', $userId)->first();

        // If cart exists but is for a different restaurant, reset it
        // (Jeevi supports ordering from one restaurant at a time)
        if ($cart && $cart['restaurant_id'] != $restaurantId) {
            $cartItemModel = new CartItemModel();
            $cartItemModel->where('cart_id', $cart['id'])->delete();
            $cartModel->update($cart['id'], ['restaurant_id' => $restaurantId]);
            $cart['restaurant_id'] = $restaurantId;
            return $cart;
        }

        if (! $cart) {
            $id = $cartModel->insert(['user_id' => $userId, 'restaurant_id' => $restaurantId]);
            return $cartModel->find($id);
        }

        return $cart;
    }

    public function add()
    {
        $userId = session()->get('user_id');
        $menuItemId = $this->request->getPost('menu_item_id');
        $qty = (int) ($this->request->getPost('quantity') ?? 1);

        $menuItemModel = new MenuItemModel();
        $item = $menuItemModel->find($menuItemId);
        if (! $item) {
            return $this->response->setJSON(['success' => false, 'message' => 'Item not found']);
        }
        if (! $item['is_available']) {
            return $this->response->setJSON(['success' => false, 'message' => 'This item is currently out of stock.']);
        }

        $restaurant = (new \App\Models\RestaurantModel())->find($item['restaurant_id']);
        if (! $restaurant || ! \App\Models\RestaurantModel::isOpenNow($restaurant)) {
            return $this->response->setJSON(['success' => false, 'message' => 'This restaurant is currently closed.']);
        }

        $cart = $this->getOrCreateCart($userId, $item['restaurant_id']);

        $cartItemModel = new CartItemModel();
        $existing = $cartItemModel->where('cart_id', $cart['id'])->where('menu_item_id', $menuItemId)->first();

        if ($existing) {
            $cartItemModel->update($existing['id'], ['quantity' => $existing['quantity'] + $qty]);
            $cartItemId = $existing['id'];
        } else {
            $cartItemId = $cartItemModel->insert([
                'cart_id'      => $cart['id'],
                'menu_item_id' => $menuItemId,
                'quantity'     => $qty,
                'price'        => $item['price'],
            ]);
        }

        $cartItems = $cartItemModel->where('cart_id', $cart['id'])->findAll();
        $count = 0;
        $subtotal = 0;
        foreach ($cartItems as $ci) {
            $count += $ci['quantity'];
            $subtotal += $ci['price'] * $ci['quantity'];
        }

        $newQty = $existing ? $existing['quantity'] + $qty : $qty;

        return $this->response->setJSON([
            'success'       => true,
            'cart_item_id'  => $cartItemId,
            'new_quantity'  => $newQty,
            'cart_count'    => $count,
            'cart_subtotal' => $subtotal,
        ]);
    }

    public function update()
    {
        $itemId = $this->request->getPost('cart_item_id');
        $qty = (int) $this->request->getPost('quantity');
        $cartItemModel = new CartItemModel();

        $item = $cartItemModel->find($itemId);
        if (! $item) {
            return $this->response->setJSON(['success' => false, 'message' => 'Item not found']);
        }

        $removed = false;
        if ($qty <= 0) {
            $cartItemModel->delete($itemId);
            $removed = true;
        } else {
            $menuItem = (new MenuItemModel())->find($item['menu_item_id']);
            if (! $menuItem || ! $menuItem['is_available']) {
                return $this->response->setJSON(['success' => false, 'message' => 'This item is currently out of stock.']);
            }
            $cartItemModel->update($itemId, ['quantity' => $qty]);
        }

        $remaining = $cartItemModel->where('cart_id', $item['cart_id'])->findAll();
        $cartSubtotal = 0;
        $cartCount = 0;
        foreach ($remaining as $r) {
            $cartSubtotal += $r['price'] * $r['quantity'];
            $cartCount += $r['quantity'];
        }

        return $this->response->setJSON([
            'success'       => true,
            'removed'       => $removed,
            'new_quantity'  => $qty > 0 ? $qty : 0,
            'item_total'    => $qty > 0 ? $item['price'] * $qty : 0,
            'cart_subtotal' => $cartSubtotal,
            'cart_count'    => $cartCount,
        ]);
    }

    public function remove($cartItemId)
    {
        $cartItemModel = new CartItemModel();
        $cartItemModel->delete($cartItemId);
        return redirect()->to('/cart');
    }

    public function view()
    {
        $userId = session()->get('user_id');
        $cartModel = new CartModel();
        $cartItemModel = new CartItemModel();

        $cart = $cartModel->where('user_id', $userId)->first();
        $items = [];
        $subtotal = 0;
        $restaurant = null;

        if ($cart) {
            $items = $cartItemModel->itemsWithDetails($cart['id']);
            foreach ($items as $it) {
                $subtotal += $it['price'] * $it['quantity'];
            }
            $restaurantModel = new \App\Models\RestaurantModel();
            $restaurant = $restaurantModel->find($cart['restaurant_id']);
        }

        return view('customer/cart', [
            'cart'       => $cart,
            'items'      => $items,
            'subtotal'   => $subtotal,
            'restaurant' => $restaurant,
        ]);
    }
}
