<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\CouponModel;

class CouponController extends BaseController
{
    public function index()
    {
        return view('admin/coupons/index', ['coupons' => (new CouponModel())->findAll()]);
    }

    public function store()
    {
        (new CouponModel())->insert([
            'code'            => strtoupper($this->request->getPost('code')),
            'description'     => $this->request->getPost('description'),
            'discount_type'   => $this->request->getPost('discount_type'),
            'discount_value'  => $this->request->getPost('discount_value'),
            'min_order_value' => $this->request->getPost('min_order_value') ?: 0,
            'max_discount'    => $this->request->getPost('max_discount') ?: null,
            'valid_from'      => $this->request->getPost('valid_from') ?: date('Y-m-d'),
            'valid_to'        => $this->request->getPost('valid_to') ?: date('Y-m-d', strtotime('+30 days')),
            'is_active'       => 1,
        ]);

        return redirect()->to('/admin/coupons')->with('success', 'Coupon created.');
    }

    public function toggle($id)
    {
        $model = new CouponModel();
        $coupon = $model->find($id);
        if ($coupon) {
            $model->update($id, ['is_active' => $coupon['is_active'] ? 0 : 1]);
        }
        return redirect()->to('/admin/coupons');
    }

    public function delete($id)
    {
        (new CouponModel())->delete($id);
        return redirect()->to('/admin/coupons')->with('success', 'Coupon deleted.');
    }
}
