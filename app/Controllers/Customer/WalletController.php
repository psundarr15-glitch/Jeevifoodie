<?php

namespace App\Controllers\Customer;

use App\Controllers\BaseController;
use App\Models\UserModel;
use App\Models\WalletTransactionModel;
use App\Models\CouponModel;

class WalletController extends BaseController
{
    public function index()
    {
        $userId = session()->get('user_id');
        $user = (new UserModel())->find($userId);
        $transactions = (new WalletTransactionModel())->where('user_id', $userId)->orderBy('id', 'DESC')->findAll(30);

        return view('customer/wallet', [
            'balance'      => $user['wallet_balance'] ?? 0,
            'transactions' => $transactions,
        ]);
    }

    public function coupons()
    {
        $couponModel = new CouponModel();
        $coupons = $couponModel->where('is_active', 1)
                                ->groupStart()
                                    ->where('valid_to >=', date('Y-m-d'))
                                    ->orWhere('valid_to', null)
                                ->groupEnd()
                                ->findAll();

        return view('customer/coupons', ['coupons' => $coupons]);
    }
}
