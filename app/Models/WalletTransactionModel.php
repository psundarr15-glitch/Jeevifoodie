<?php

namespace App\Models;

use CodeIgniter\Model;

class WalletTransactionModel extends Model
{
    protected $table         = 'wallet_transactions';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id', 'type', 'amount', 'description', 'order_id'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = '';

    /**
     * Credits (or debits, with a negative-safe check) a user's wallet and
     * logs the transaction — kept together so balance and history never
     * drift apart.
     */
    public function credit(int $userId, float $amount, string $description, ?int $orderId = null): void
    {
        $this->insert(['user_id' => $userId, 'type' => 'credit', 'amount' => $amount, 'description' => $description, 'order_id' => $orderId]);
        $userModel = new UserModel();
        $user = $userModel->find($userId);
        $userModel->update($userId, ['wallet_balance' => $user['wallet_balance'] + $amount]);
    }

    public function debit(int $userId, float $amount, string $description, ?int $orderId = null): bool
    {
        $userModel = new UserModel();
        $user = $userModel->find($userId);
        if ($user['wallet_balance'] < $amount) {
            return false;
        }
        $this->insert(['user_id' => $userId, 'type' => 'debit', 'amount' => $amount, 'description' => $description, 'order_id' => $orderId]);
        $userModel->update($userId, ['wallet_balance' => $user['wallet_balance'] - $amount]);
        return true;
    }
}
