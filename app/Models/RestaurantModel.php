<?php

namespace App\Models;

use CodeIgniter\Model;

class RestaurantModel extends Model
{
    protected $table         = 'restaurants';
    protected $primaryKey    = 'id';
    protected $allowedFields = [
        'name', 'owner_name', 'phone', 'owner_phone', 'description', 'image', 'logo',
        'cuisine', 'restaurant_type', 'food_type', 'rating', 'rating_count',
        'prep_time_min', 'prep_time_max', 'cost_for_two', 'discount_label',
        'address', 'lat', 'lng', 'is_active', 'opening_time', 'closing_time',
        'fssai_number', 'fssai_certificate', 'tin_number', 'tin_certificate',
        'bank_account_number', 'bank_ifsc', 'bank_account_holder',
    ];
    protected $useTimestamps = false;

    public function active()
    {
        return $this->where('is_active', 1);
    }

    /**
     * True if the restaurant is currently open — checks the admin's manual
     * is_active switch first (off always means closed regardless of hours),
     * then compares the current time against opening_time/closing_time.
     * Handles overnight hours correctly (e.g. 18:00-02:00 spanning midnight).
     * A restaurant with no hours set is treated as always open.
     */
    public static function isOpenNow(array $restaurant): bool
    {
        if (empty($restaurant['is_active'])) {
            return false;
        }

        $open = $restaurant['opening_time'] ?? null;
        $close = $restaurant['closing_time'] ?? null;

        if (! $open || ! $close) {
            return true;
        }

        // Use IST explicitly rather than date('H:i:s') — that relies on the
        // server's PHP default timezone, which is often UTC on shared
        // hosting and would silently shift every comparison by 5.5 hours.
        $now = (new \DateTime('now', new \DateTimeZone('Asia/Kolkata')))->format('H:i:s');
        $open = substr($open, 0, 8);
        $close = substr($close, 0, 8);

        if ($open <= $close) {
            // Normal same-day window, e.g. 09:00–23:00
            return $now >= $open && $now <= $close;
        }

        // Overnight window, e.g. 18:00–02:00
        return $now >= $open || $now <= $close;
    }
}
