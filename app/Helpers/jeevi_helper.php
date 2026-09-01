<?php

if (! function_exists('rupees')) {
    /**
     * Formats a number as Indian Rupees, e.g. rupees(229) => "₹229"
     */
    function rupees($amount): string
    {
        return '₹' . number_format((float) $amount, (fmod((float) $amount, 1) == 0) ? 0 : 2);
    }
}

if (! function_exists('order_status_label')) {
    function order_status_label(string $status): string
    {
        $labels = [
            'placed'           => 'Placed',
            'confirmed'        => 'Confirmed',
            'preparing'        => 'Preparing',
            'out_for_delivery' => 'Out for Delivery',
            'delivered'        => 'Delivered',
            'cancelled'        => 'Cancelled',
        ];

        return $labels[$status] ?? ucfirst($status);
    }
}

if (! function_exists('distance_km')) {
    /**
     * Straight-line (haversine) distance in km between two lat/lng points.
     * Returns null if any coordinate is missing.
     */
    function distance_km($lat1, $lon1, $lat2, $lon2): ?float
    {
        if ($lat1 === null || $lon1 === null || $lat2 === null || $lon2 === null
            || $lat1 === '' || $lon1 === '' || $lat2 === '' || $lon2 === '') {
            return null;
        }

        $earthRadiusKm = 6371;
        $dLat = deg2rad((float) $lat2 - (float) $lat1);
        $dLon = deg2rad((float) $lon2 - (float) $lon1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad((float) $lat1)) * cos(deg2rad((float) $lat2)) * sin($dLon / 2) ** 2;
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($earthRadiusKm * $c, 1);
    }
}
