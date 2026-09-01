<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\AdminModel;

class AuthController extends BaseController
{
    public function showLogin()
    {
        return view('admin/login');
    }

    public function login()
    {
        $model = new AdminModel();
        $admin = $model->where('email', $this->request->getPost('email'))->first();

        if (! $admin || ! password_verify($this->request->getPost('password'), $admin['password'])) {
            return redirect()->back()->with('error', 'Invalid credentials.');
        }

        session()->set([
            'admin_id'            => $admin['id'],
            'admin_name'          => $admin['name'],
            'admin_role'          => $admin['role'],
            'admin_restaurant_id' => $admin['restaurant_id'],
        ]);

        return redirect()->to('/admin/dashboard');
    }

    public function logout()
    {
        session()->remove(['admin_id', 'admin_name', 'admin_role', 'admin_restaurant_id']);
        return redirect()->to('/admin/login');
    }
}
