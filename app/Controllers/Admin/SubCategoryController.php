<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\CategoryModel;
use App\Models\RestaurantModel;
use App\Models\SubCategoryModel;

class SubCategoryController extends BaseController
{
    protected function isManager(): bool
    {
        return session()->get('admin_role') === 'restaurant_manager';
    }

    protected function myRestaurantId()
    {
        return session()->get('admin_restaurant_id');
    }

    public function index()
    {
        $model = new SubCategoryModel();
        $query = $model->select('sub_categories.*, categories.name as category_name, restaurants.name as restaurant_name')
            ->join('categories', 'categories.id = sub_categories.category_id')
            ->join('restaurants', 'restaurants.id = sub_categories.restaurant_id');

        if ($this->isManager()) {
            $query->where('sub_categories.restaurant_id', $this->myRestaurantId());
        }

        return view('admin/sub_categories/index', [
            'subCategories' => $query->findAll(),
            'categories'    => (new CategoryModel())->findAll(),
            'restaurants'   => $this->isManager() ? [] : (new RestaurantModel())->findAll(),
            'isManager'     => $this->isManager(),
        ]);
    }

    public function store()
    {
        $restaurantId = $this->isManager() ? $this->myRestaurantId() : $this->request->getPost('restaurant_id');

        (new SubCategoryModel())->insert([
            'category_id'   => $this->request->getPost('category_id'),
            'restaurant_id' => $restaurantId,
            'name'          => $this->request->getPost('name'),
            'name_ta'       => $this->request->getPost('name_ta') ?: null,
        ]);

        return redirect()->to('/admin/sub-categories')->with('success', 'Sub-category added.');
    }

    public function delete($id)
    {
        $model = new SubCategoryModel();
        $subCategory = $model->find($id);

        if ($this->isManager() && (! $subCategory || $subCategory['restaurant_id'] != $this->myRestaurantId())) {
            return redirect()->to('/admin/sub-categories')->with('error', 'You can only manage your own sub-categories.');
        }

        $model->delete($id);
        return redirect()->to('/admin/sub-categories')->with('success', 'Sub-category deleted.');
    }
}
