<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\MenuItemModel;
use App\Models\RestaurantModel;
use App\Models\SubCategoryModel;

class MenuItemController extends BaseController
{
    protected function isManager(): bool
    {
        return session()->get('admin_role') === 'restaurant_manager';
    }

    protected function myRestaurantId()
    {
        return session()->get('admin_restaurant_id');
    }

    /**
     * Menu items group under a sub-category ("Biryani"), which itself
     * belongs to one of the app owner's main categories ("Indian
     * Food") - see SubCategoryController. A manager only ever sees
     * their own restaurant's sub-categories here; admin sees every
     * restaurant's, each labeled with its restaurant name since they
     * might be managing several.
     */
    private function subCategoryOptions()
    {
        $model = (new SubCategoryModel())
            ->select('sub_categories.*, restaurants.name as restaurant_name')
            ->join('restaurants', 'restaurants.id = sub_categories.restaurant_id');

        if ($this->isManager()) {
            $model->where('sub_categories.restaurant_id', $this->myRestaurantId());
        }

        return $model->findAll();
    }

    public function index()
    {
        $model = new MenuItemModel();
        $query = $model->select('menu_items.*, restaurants.name as restaurant_name')
                        ->join('restaurants', 'restaurants.id = menu_items.restaurant_id');

        if ($this->isManager()) {
            $query->where('menu_items.restaurant_id', $this->myRestaurantId());
        }

        return view('admin/menu_items/index', ['items' => $query->findAll()]);
    }

    public function create()
    {
        // Managers only ever add items to their own restaurant, so the
        // restaurant dropdown is skipped entirely for them (see the view).
        $restaurants = $this->isManager()
            ? (new RestaurantModel())->where('id', $this->myRestaurantId())->findAll()
            : (new RestaurantModel())->findAll();

        return view('admin/menu_items/form', [
            'item'          => null,
            'restaurants'   => $restaurants,
            'subCategories' => $this->subCategoryOptions(),
        ]);
    }

    public function store()
    {
        $restaurantId = $this->isManager() ? $this->myRestaurantId() : $this->request->getPost('restaurant_id');

        $data = [
            'restaurant_id'    => $restaurantId,
            'sub_category_id'  => $this->request->getPost('sub_category_id') ?: null,
            'name'             => $this->request->getPost('name'),
            'description'      => $this->request->getPost('description'),
            'price'            => $this->request->getPost('price'),
            'is_veg'           => $this->request->getPost('is_veg') ? 1 : 0,
            'is_available'     => $this->request->getPost('is_available') ? 1 : 0,
        ];
        $this->attachImageIfUploaded($data);

        (new MenuItemModel())->insert($data);

        return redirect()->to('/admin/menu-items')->with('success', 'Menu item added.');
    }

    public function edit($id)
    {
        $item = (new MenuItemModel())->find($id);
        if (! $item) {
            return redirect()->to('/admin/menu-items')->with('error', 'Not found.');
        }
        if ($this->isManager() && $item['restaurant_id'] != $this->myRestaurantId()) {
            return redirect()->to('/admin/menu-items')->with('error', 'You can only manage your own restaurant\'s menu.');
        }

        $restaurants = $this->isManager()
            ? (new RestaurantModel())->where('id', $this->myRestaurantId())->findAll()
            : (new RestaurantModel())->findAll();

        return view('admin/menu_items/form', [
            'item'          => $item,
            'restaurants'   => $restaurants,
            'subCategories' => $this->subCategoryOptions(),
        ]);
    }

    public function update($id)
    {
        $model = new MenuItemModel();
        $item = $model->find($id);
        if (! $item) {
            return redirect()->to('/admin/menu-items')->with('error', 'Not found.');
        }
        if ($this->isManager() && $item['restaurant_id'] != $this->myRestaurantId()) {
            return redirect()->to('/admin/menu-items')->with('error', 'You can only manage your own restaurant\'s menu.');
        }

        $restaurantId = $this->isManager() ? $this->myRestaurantId() : $this->request->getPost('restaurant_id');

        $data = [
            'restaurant_id'   => $restaurantId,
            'sub_category_id' => $this->request->getPost('sub_category_id') ?: null,
            'name'            => $this->request->getPost('name'),
            'description'     => $this->request->getPost('description'),
            'price'           => $this->request->getPost('price'),
            'is_veg'          => $this->request->getPost('is_veg') ? 1 : 0,
            'is_available'    => $this->request->getPost('is_available') ? 1 : 0,
        ];
        $this->attachImageIfUploaded($data);

        $model->update($id, $data);

        return redirect()->to('/admin/menu-items')->with('success', 'Menu item updated.');
    }

    private function attachImageIfUploaded(array &$data): void
    {
        $file = $this->request->getFile('image');
        if ($file && $file->isValid() && ! $file->hasMoved()) {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'assets/uploads/menu_items', $newName);
            $data['image'] = base_url('assets/uploads/menu_items/' . $newName);
        }
    }

    public function delete($id)
    {
        $item = (new MenuItemModel())->find($id);
        if ($item && $this->isManager() && $item['restaurant_id'] != $this->myRestaurantId()) {
            return redirect()->to('/admin/menu-items')->with('error', 'You can only manage your own restaurant\'s menu.');
        }

        (new MenuItemModel())->delete($id);
        return redirect()->to('/admin/menu-items')->with('success', 'Menu item deleted.');
    }

    /**
     * One-click stock toggle from the list page, so a manager doesn't have
     * to open the full edit form just to mark something sold out.
     */
    public function toggleAvailability($id)
    {
        $model = new MenuItemModel();
        $item = $model->find($id);
        if (! $item) {
            return redirect()->to('/admin/menu-items')->with('error', 'Not found.');
        }
        if ($this->isManager() && $item['restaurant_id'] != $this->myRestaurantId()) {
            return redirect()->to('/admin/menu-items')->with('error', 'You can only manage your own restaurant\'s menu.');
        }

        $model->update($id, ['is_available' => $item['is_available'] ? 0 : 1]);
        return redirect()->to('/admin/menu-items')->with('success', $item['is_available'] ? 'Marked as out of stock.' : 'Marked as available.');
    }
}
