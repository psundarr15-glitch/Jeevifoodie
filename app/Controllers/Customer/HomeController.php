<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\CategoryModel;
use App\Models\RestaurantModel;
use App\Models\CouponModel;
use App\Models\RestaurantLikeModel;

class HomeController extends BaseController
{
    public function index()
    {
        $categoryModel   = new CategoryModel();
        $restaurantModel = new RestaurantModel();
        $couponModel     = new CouponModel();

        $restaurants = $restaurantModel->active()->orderBy('rating', 'DESC')->findAll(8);

        $data = [
            'categories'   => $categoryModel->findAll(),
            'restaurants'  => $restaurants,
            'coupons'      => $couponModel->where('is_active', 1)->findAll(4),
            'like_counts'  => $this->likeCountsFor($restaurants),
            'liked_by_me'  => $this->likedByCurrentUser($restaurants),
        ];

        return view('customer/home', $data);
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
