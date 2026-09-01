<?php

namespace App\Models;

use CodeIgniter\Model;

class OrderTrackingModel extends Model
{
    protected $table         = 'order_tracking';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['order_id', 'status', 'lat', 'lng', 'note'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = '';

    public function historyFor($orderId)
    {
        return $this->where('order_id', $orderId)->orderBy('id', 'ASC')->findAll();
    }

    public function latestFor($orderId)
    {
        return $this->where('order_id', $orderId)->orderBy('id', 'DESC')->first();
    }
}
