<?php

namespace App\Models;

use CodeIgniter\Model;

class OrderDeclineModel extends Model
{
    protected $table         = 'order_declines';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['order_id', 'delivery_partner_id'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = '';
}
