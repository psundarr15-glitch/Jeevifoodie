<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\RestaurantModel;
use App\Models\MenuItemModel;
use App\Models\CategoryModel;
use App\Models\RestaurantLikeModel;

class RestaurantController extends BaseController
{
    public function index()
    {
        $restaurantModel = new RestaurantModel();

        $keyword = $this->request->getGet('q');
        $query = $restaurantModel->active();

        if ($keyword) {
            $query->groupStart()
                  ->like('name', $keyword)
                  ->orLike('cuisine', $keyword)
                  ->groupEnd();
        }

        $restaurants = $query->orderBy('rating', 'DESC')->findAll();

        $data = [
            'restaurants' => $restaurants,
            'keyword'     => $keyword,
            'like_counts' => $this->likeCountsFor($restaurants),
            'liked_by_me' => $this->likedByCurrentUser($restaurants),
        ];

        return view('customer/restaurant_list', $data);
    }

    public function view($id)
    {
        $restaurantModel = new RestaurantModel();
        $menuItemModel   = new MenuItemModel();
        $categoryModel   = new CategoryModel();

        $restaurant = $restaurantModel->find($id);
        if (! $restaurant) {
            return redirect()->to('/restaurants')->with('error', 'Restaurant not found.');
        }

        $items = $menuItemModel->forRestaurant($id)->findAll();

        // group items by category name for menu display
        $categories = $categoryModel->findAll();
        $catMap = [];
        foreach ($categories as $c) {
            $catMap[$c['id']] = $c['name'];
        }
        $grouped = [];
        foreach ($items as $item) {
            $catName = $catMap[$item['category_id']] ?? 'Other';
            $grouped[$catName][] = $item;
        }

        // Existing cart state for this restaurant (so the floating "View Cart"
        // bar and each item's quantity stepper already show correctly if the
        // user comes back to this page).
        $cartCount = 0;
        $cartSubtotal = 0;
        $itemCartState = []; // menu_item_id => ['cart_item_id' => ..., 'quantity' => ...]
        if (session()->get('logged_in')) {
            $cartModel = new \App\Models\CartModel();
            $cartItemModel = new \App\Models\CartItemModel();
            $cart = $cartModel->where('user_id', session()->get('user_id'))
                               ->where('restaurant_id', $id)
                               ->first();
            if ($cart) {
                foreach ($cartItemModel->where('cart_id', $cart['id'])->findAll() as $ci) {
                    $cartCount += $ci['quantity'];
                    $cartSubtotal += $ci['price'] * $ci['quantity'];
                    $itemCartState[$ci['menu_item_id']] = [
                        'cart_item_id' => $ci['id'],
                        'quantity'     => $ci['quantity'],
                    ];
                }
            }
        }

        $likeModel = new RestaurantLikeModel();
        $userId = session()->get('user_id');

        return view('customer/restaurant_menu', [
            'restaurant'      => $restaurant,
            'grouped'         => $grouped,
            'cart_count'      => $cartCount,
            'cart_subtotal'   => $cartSubtotal,
            'item_cart_state' => $itemCartState,
            'like_count'      => $likeModel->where('restaurant_id', $id)->countAllResults(),
            'liked_by_me'     => $userId ? (bool) $likeModel->where('user_id', $userId)->where('restaurant_id', $id)->first() : false,
        ]);
    }

    protected function likeCountsFor(array $restaurants): array
    {
        if (empty($restaurants)) return [];
        $ids = array_column($restaurants, 'id');
        $rows = (new RestaurantLikeModel())->select('restaurant_id, COUNT(*) as cnt')
                                            ->whereIn('restaurant_id', $ids)
                                            ->groupBy('restaurant_id')
                                            ->findAll();
        $counts = [];
        foreach ($rows as $r) {
            $counts[$r['restaurant_id']] = (int) $r['cnt'];
        }
        return $counts;
    }

    protected function likedByCurrentUser(array $restaurants): array
    {
        $userId = session()->get('user_id');
        if (! $userId || empty($restaurants)) return [];
        $ids = array_column($restaurants, 'id');
        $liked = (new RestaurantLikeModel())->where('user_id', $userId)->whereIn('restaurant_id', $ids)->findColumn('restaurant_id');
        return $liked ? array_flip($liked) : [];
    }
}
