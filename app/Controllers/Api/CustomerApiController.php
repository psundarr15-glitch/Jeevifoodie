<?php

namespace App\Controllers\Api;

use App\Models\CategoryModel;
use App\Models\RestaurantModel;
use App\Models\CouponModel;
use App\Models\MenuItemModel;
use App\Models\RestaurantLikeModel;
use App\Models\UserModel;
use App\Models\SentNotificationModel;
use App\Models\SubCategoryModel;

class CustomerApiController extends BaseApiController
{
    /**
     * Resolves the Bearer token to a user id if present, without failing
     * the request when it's missing/invalid — these endpoints are
     * browsable without login, but personalise "liked_by_me" when a
     * valid token is sent.
     */
    private function optionalUserId(): ?int
    {
        $token = $this->bearerToken();
        if (! $token) {
            return null;
        }
        $user = (new UserModel())->where('api_token', $token)->first();
        return $user['id'] ?? null;
    }

    /**
     * Adds is_open / like_count / liked_by_me to each restaurant row so
     * the app can render the same card the website does in one call.
     */
    private function decorate(array $restaurants): array
    {
        $userId = $this->optionalUserId();
        $likeModel = new RestaurantLikeModel();

        $likedIds = [];
        if ($userId) {
            foreach ($likeModel->where('user_id', $userId)->findAll() as $row) {
                $likedIds[$row['restaurant_id']] = true;
            }
        }

        foreach ($restaurants as &$r) {
            $r['is_open'] = RestaurantModel::isOpenNow($r);
            $r['like_count'] = $likeModel->where('restaurant_id', $r['id'])->countAllResults();
            $r['liked_by_me'] = isset($likedIds[$r['id']]);
        }

        return $restaurants;
    }

    public function home()
    {
        return $this->ok([
            'categories'  => (new CategoryModel())->findAll(),
            'restaurants' => $this->decorate((new RestaurantModel())->active()->orderBy('rating', 'DESC')->findAll(8)),
            'coupons'     => (new CouponModel())->where('is_active', 1)->findAll(4),
        ]);
    }

    public function restaurants()
    {
        $keyword = $this->request->getGet('q');
        $model = (new RestaurantModel())->active();

        if ($keyword) {
            $model->groupStart()->like('name', $keyword)->orLike('cuisine', $keyword)->groupEnd();
        }

        return $this->ok(['restaurants' => $this->decorate($model->orderBy('rating', 'DESC')->findAll())]);
    }

    public function restaurantMenu($id)
    {
        $restaurant = (new RestaurantModel())->find($id);
        if (! $restaurant) {
            return $this->fail('Restaurant not found.', 404);
        }

        [$restaurant] = $this->decorate([$restaurant]);

        $items = (new MenuItemModel())->forRestaurant($id)->findAll();

        // Items group under this restaurant's own sub-categories (e.g.
        // "Biryani") rather than the app owner's main categories (e.g.
        // "Indian Food") - a main category is too broad to be a useful
        // menu section heading.
        $subCategories = (new SubCategoryModel())->forRestaurant($id);
        $catMap = [];
        foreach ($subCategories as $c) {
            $catMap[$c['id']] = $c['name'];
        }

        $grouped = [];
        foreach ($items as $item) {
            $catName = $catMap[$item['sub_category_id']] ?? 'Other';
            $grouped[$catName][] = $item;
        }

        // PHP's json_encode turns an empty array into JSON `[]`, not `{}` -
        // that breaks clients expecting an object (a restaurant with zero
        // menu items would otherwise send a type mobile can't parse as a map).
        return $this->ok(['restaurant' => $restaurant, 'menu' => empty($grouped) ? new \stdClass() : $grouped]);
    }

    /**
     * Like/unlike toggle - mirrors Customer\RestaurantLikeController but
     * for the mobile API (Bearer-token auth instead of session).
     */
    public function toggleLike($restaurantId)
    {
        $user = $this->authCustomer();
        if (! $user) return $this->response;

        $likeModel = new RestaurantLikeModel();
        $existing = $likeModel->where('user_id', $user['id'])->where('restaurant_id', $restaurantId)->first();

        if ($existing) {
            $likeModel->delete($existing['id']);
            $liked = false;
        } else {
            $likeModel->insert(['user_id' => $user['id'], 'restaurant_id' => $restaurantId]);
            $liked = true;
        }

        $count = $likeModel->where('restaurant_id', $restaurantId)->countAllResults();

        return $this->ok(['liked' => $liked, 'like_count' => $count]);
    }

    /**
     * History for the notification bell in the app: the most recent
     * "send to all customers" broadcasts from the admin panel (title,
     * body, optional banner image, when it was sent). No login
     * required - same reasoning as home()/restaurants(): these are
     * public promotional broadcasts, not per-user data.
     */
    public function notifications()
    {
        return $this->ok(['notifications' => (new SentNotificationModel())->recent(20)]);
    }

    /**
     * Full list of currently-active coupons for the "My Coupons" screen
     * in the profile menu (home() only sends a preview of 4 for the
     * deals carousel).
     */
    public function coupons()
    {
        return $this->ok(['coupons' => (new CouponModel())->where('is_active', 1)->findAll()]);
    }
}
