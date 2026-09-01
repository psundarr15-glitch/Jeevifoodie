<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\AdminModel;
use App\Models\RestaurantModel;

/**
 * Superadmin-only: create/manage restaurant_manager login accounts, each
 * tied to exactly one restaurant. A restaurant_manager who logs in only
 * ever sees/edits that one restaurant (enforced in RestaurantController,
 * MenuItemController, OrderController, DashboardController).
 */
class ManagerController extends BaseController
{
    protected function guardSuperadmin()
    {
        if (session()->get('admin_role') !== 'superadmin') {
            return redirect()->to('/admin/dashboard')->with('error', 'Only superadmins can manage restaurant manager accounts.');
        }
        return null;
    }

    public function index()
    {
        if ($guard = $this->guardSuperadmin()) return $guard;

        $model = new AdminModel();
        $managers = $model->select('admins.*, restaurants.name as restaurant_name')
                           ->join('restaurants', 'restaurants.id = admins.restaurant_id', 'left')
                           ->where('admins.role', 'restaurant_manager')
                           ->findAll();

        return view('admin/managers/index', [
            'managers'    => $managers,
            'restaurants' => (new RestaurantModel())->findAll(),
        ]);
    }

    public function store()
    {
        if ($guard = $this->guardSuperadmin()) return $guard;

        $rules = [
            'name'          => 'required|min_length[2]',
            'email'         => 'required|valid_email|is_unique[admins.email]',
            'password'      => 'required|min_length[6]',
            'restaurant_id' => 'required',
        ];

        if (! $this->validate($rules)) {
            return redirect()->to('/admin/managers')->with('error', implode(' ', $this->validator->getErrors()));
        }

        (new AdminModel())->insert([
            'name'          => $this->request->getPost('name'),
            'email'         => $this->request->getPost('email'),
            'password'      => password_hash($this->request->getPost('password'), PASSWORD_DEFAULT),
            'role'          => 'restaurant_manager',
            'restaurant_id' => $this->request->getPost('restaurant_id'),
        ]);

        return redirect()->to('/admin/managers')->with('success', 'Restaurant manager account created.');
    }

    public function delete($id)
    {
        if ($guard = $this->guardSuperadmin()) return $guard;

        $model = new AdminModel();
        $manager = $model->find($id);
        if ($manager && $manager['role'] === 'restaurant_manager') {
            $model->delete($id);
        }

        return redirect()->to('/admin/managers')->with('success', 'Manager account removed.');
    }
}
