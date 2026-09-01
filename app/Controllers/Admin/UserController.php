<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\UserModel;
use App\Models\OrderModel;
use App\Models\AddressModel;

class UserController extends BaseController
{
    public function index()
    {
        $userModel = new UserModel();
        $orderModel = new OrderModel();

        $users = $userModel->findAll();
        foreach ($users as &$u) {
            $u['order_count'] = $orderModel->where('user_id', $u['id'])->countAllResults();
        }

        return view('admin/users/index', ['users' => $users]);
    }

    public function view($id)
    {
        $userModel = new UserModel();
        $orderModel = new OrderModel();
        $addressModel = new AddressModel();

        $user = $userModel->find($id);
        if (! $user) {
            return redirect()->to('/admin/users')->with('error', 'User not found.');
        }

        return view('admin/users/view', [
            'user'      => $user,
            'orders'    => $orderModel->where('user_id', $id)->orderBy('id', 'DESC')->findAll(),
            'addresses' => $addressModel->where('user_id', $id)->findAll(),
        ]);
    }

    public function edit($id)
    {
        $userModel = new UserModel();
        $user = $userModel->find($id);
        if (! $user) {
            return redirect()->to('/admin/users')->with('error', 'User not found.');
        }

        return view('admin/users/form', ['user' => $user]);
    }

    public function update($id)
    {
        $userModel = new UserModel();
        $user = $userModel->find($id);
        if (! $user) {
            return redirect()->to('/admin/users')->with('error', 'User not found.');
        }

        $rules = [
            'name'  => 'required|min_length[2]',
            'email' => 'required|valid_email|is_unique[users.email,id,' . $id . ']',
            'phone' => 'required|min_length[10]',
        ];

        if (! $this->validate($rules)) {
            return redirect()->back()->withInput()->with('error', implode(' ', $this->validator->getErrors()));
        }

        $data = [
            'name'  => $this->request->getPost('name'),
            'email' => $this->request->getPost('email'),
            'phone' => $this->request->getPost('phone'),
        ];

        $newPassword = $this->request->getPost('new_password');
        if ($newPassword) {
            $data['password'] = password_hash($newPassword, PASSWORD_DEFAULT);
        }

        $userModel->update($id, $data);

        return redirect()->to('/admin/users')->with('success', 'User updated.');
    }

    public function delete($id)
    {
        (new UserModel())->delete($id);
        return redirect()->to('/admin/users')->with('success', 'User deleted.');
    }
}
