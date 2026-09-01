<?php

namespace App\Models;

use CodeIgniter\Model;

/**
 * A record of every broadcast/promotional push sent from the admin
 * panel, so the customer app's notification bell can show real
 * history instead of a "No notifications yet" stub. Order-specific
 * pushes (via PushNotificationService::sendToUser) aren't logged
 * here - only the "send to all customers" broadcasts, which is what
 * the bell/history screen is for.
 */
class SentNotificationModel extends Model
{
    protected $table         = 'sent_notifications';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['title', 'body', 'image_url'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = '';

    public function recent(int $limit = 20): array
    {
        return $this->orderBy('id', 'DESC')->findAll($limit);
    }
}
