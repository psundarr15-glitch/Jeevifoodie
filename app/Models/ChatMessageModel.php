<?php

namespace App\Models;

use CodeIgniter\Model;

class ChatMessageModel extends Model
{
    protected $table         = 'chat_messages';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id', 'sender', 'message', 'is_read', 'recipient_role', 'restaurant_id'];
    protected $useTimestamps = false;

    protected $beforeInsert = ['setCreatedAt'];

    protected function setCreatedAt(array $data): array
    {
        $data['data']['created_at'] = date('Y-m-d H:i:s');
        return $data;
    }

    /**
     * One customer can have two independent threads: a general one with
     * the app admin (restaurant_id is NULL) and, separately, a per-order
     * one with a specific restaurant's manager. This scopes to exactly
     * one of those threads.
     */
    public function forThread($userId, ?int $restaurantId)
    {
        $q = $this->where('user_id', $userId);
        return $restaurantId
            ? $q->where('recipient_role', 'manager')->where('restaurant_id', $restaurantId)
            : $q->where('recipient_role', 'admin')->where('restaurant_id', null);
    }
}
