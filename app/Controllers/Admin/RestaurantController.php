<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\RestaurantModel;

class RestaurantController extends BaseController
{
    /**
     * True for restaurant_manager admins — they only ever see/edit their
     * own restaurant, never the full list.
     */
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
        $model = new RestaurantModel();

        if ($this->isManager()) {
            // A manager has exactly one restaurant — send them straight to
            // its edit form instead of a list they can't use anyway.
            return redirect()->to('/admin/restaurants/edit/' . $this->myRestaurantId());
        }

        return view('admin/restaurants/index', ['restaurants' => $model->findAll()]);
    }

    public function create()
    {
        if ($this->isManager()) {
            return redirect()->to('/admin/dashboard')->with('error', 'Restaurant managers cannot create new restaurants.');
        }

        return view('admin/restaurants/form', ['restaurant' => null]);
    }

    public function store()
    {
        if ($this->isManager()) {
            return redirect()->to('/admin/dashboard')->with('error', 'Restaurant managers cannot create new restaurants.');
        }

        $model = new RestaurantModel();
        $data = [
            'name'                => $this->request->getPost('name'),
            'owner_name'          => $this->request->getPost('owner_name'),
            'owner_phone'         => $this->request->getPost('owner_phone'),
            'description'         => $this->request->getPost('description'),
            'cuisine'             => $this->request->getPost('cuisine'),
            'restaurant_type'     => $this->request->getPost('restaurant_type'),
            'food_type'           => $this->request->getPost('food_type') ?: 'both',
            'phone'               => $this->request->getPost('phone'),
            'opening_time'        => $this->request->getPost('opening_time') ?: null,
            'closing_time'        => $this->request->getPost('closing_time') ?: null,
            'prep_time_min'       => $this->request->getPost('prep_time_min') ?: 20,
            'prep_time_max'       => $this->request->getPost('prep_time_max') ?: 40,
            'cost_for_two'        => $this->request->getPost('cost_for_two') ?: 0,
            'discount_label'      => $this->request->getPost('discount_label'),
            'address'             => $this->request->getPost('address'),
            'lat'                 => $this->request->getPost('lat') ?: null,
            'lng'                 => $this->request->getPost('lng') ?: null,
            'fssai_number'        => $this->request->getPost('fssai_number'),
            'tin_number'          => $this->request->getPost('tin_number'),
            'bank_account_number' => $this->request->getPost('bank_account_number'),
            'bank_ifsc'           => $this->request->getPost('bank_ifsc'),
            'bank_account_holder' => $this->request->getPost('bank_account_holder'),
            'is_active'           => $this->request->getPost('is_active') ? 1 : 0,
        ];

        $this->attachImageIfUploaded($data);

        $model->insert($data);

        return redirect()->to('/admin/restaurants')->with('success', 'Restaurant added.');
    }

    public function edit($id)
    {
        if ($this->isManager() && $id != $this->myRestaurantId()) {
            return redirect()->to('/admin/dashboard')->with('error', 'You can only manage your own restaurant.');
        }

        $model = new RestaurantModel();
        $restaurant = $model->find($id);
        if (! $restaurant) {
            return redirect()->to('/admin/dashboard')->with('error', 'Not found.');
        }
        return view('admin/restaurants/form', ['restaurant' => $restaurant]);
    }

    public function update($id)
    {
        if ($this->isManager() && $id != $this->myRestaurantId()) {
            return redirect()->to('/admin/dashboard')->with('error', 'You can only manage your own restaurant.');
        }

        $model = new RestaurantModel();
        $data = [
            'name'                => $this->request->getPost('name'),
            'owner_name'          => $this->request->getPost('owner_name'),
            'owner_phone'         => $this->request->getPost('owner_phone'),
            'description'         => $this->request->getPost('description'),
            'cuisine'             => $this->request->getPost('cuisine'),
            'restaurant_type'     => $this->request->getPost('restaurant_type'),
            'food_type'           => $this->request->getPost('food_type') ?: 'both',
            'phone'               => $this->request->getPost('phone'),
            'opening_time'        => $this->request->getPost('opening_time') ?: null,
            'closing_time'        => $this->request->getPost('closing_time') ?: null,
            'prep_time_min'       => $this->request->getPost('prep_time_min') ?: 20,
            'prep_time_max'       => $this->request->getPost('prep_time_max') ?: 40,
            'cost_for_two'        => $this->request->getPost('cost_for_two') ?: 0,
            'discount_label'      => $this->request->getPost('discount_label'),
            'address'             => $this->request->getPost('address'),
            'lat'                 => $this->request->getPost('lat') ?: null,
            'lng'                 => $this->request->getPost('lng') ?: null,
            'fssai_number'        => $this->request->getPost('fssai_number'),
            'tin_number'          => $this->request->getPost('tin_number'),
            'bank_account_number' => $this->request->getPost('bank_account_number'),
            'bank_ifsc'           => $this->request->getPost('bank_ifsc'),
            'bank_account_holder' => $this->request->getPost('bank_account_holder'),
        ];

        // Managers can't deactivate/reactivate their own listing — that stays
        // a superadmin-only switch.
        if (! $this->isManager()) {
            $data['is_active'] = $this->request->getPost('is_active') ? 1 : 0;
        }

        $this->attachImageIfUploaded($data);

        $model->update($id, $data);

        $redirect = $this->isManager() ? '/admin/restaurants/edit/' . $id : '/admin/restaurants';
        return redirect()->to($redirect)->with('success', 'Restaurant updated.');
    }

    /**
     * Shared by store() and update() - both superadmin's "Add/Edit
     * Restaurant" form and the restaurant manager's own edit page use
     * the exact same form/controller, so this one upload path covers
     * both surfaces. Each restaurant keeps its own independent image;
     * uploading a new one only ever replaces that single restaurant's
     * row, never anything shared across restaurants.
     */
    private function attachImageIfUploaded(array &$data): void
    {
        $this->attachUpload($data, 'image', 'image', 'restaurants');
        $this->attachUpload($data, 'logo', 'logo', 'restaurants');
        $this->attachUpload($data, 'fssai_certificate', 'fssai_certificate', 'restaurants/documents');
        $this->attachUpload($data, 'tin_certificate', 'tin_certificate', 'restaurants/documents');
    }

    private function attachUpload(array &$data, string $dataKey, string $fieldName, string $subdir): void
    {
        $file = $this->request->getFile($fieldName);
        if ($file && $file->isValid() && ! $file->hasMoved()) {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'assets/uploads/' . $subdir, $newName);
            $data[$dataKey] = base_url('assets/uploads/' . $subdir . '/' . $newName);
        }
    }

    public function delete($id)
    {
        if ($this->isManager()) {
            return redirect()->to('/admin/dashboard')->with('error', 'Restaurant managers cannot delete restaurants.');
        }

        (new RestaurantModel())->delete($id);
        return redirect()->to('/admin/restaurants')->with('success', 'Restaurant deleted.');
    }
}
