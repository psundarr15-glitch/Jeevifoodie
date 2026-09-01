<?php

namespace App\Models;

use CodeIgniter\Model;

class DeviceTokenModel extends Model
{
    protected $table         = 'device_tokens';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id', 'fcm_token', 'platform'];
    protected $useTimestamps = true;

    /**
     * Saves (or refreshes) a token for a user. One row per (user_id,
     * fcm_token) pair - the same physical device re-registering just
     * bumps updated_at instead of creating a duplicate row.
     */
    public function saveToken(int $userId, string $token, string $platform = 'android'): void
    {
        $existing = $this->where('user_id', $userId)->where('fcm_token', $token)->first();
        if ($existing) {
            $this->update($existing['id'], ['platform' => $platform]);
            return;
        }
        $this->insert(['user_id' => $userId, 'fcm_token' => $token, 'platform' => $platform]);
    }

    public function tokensFor(int $userId): array
    {
        return array_column($this->where('user_id', $userId)->findAll(), 'fcm_token');
    }
}
