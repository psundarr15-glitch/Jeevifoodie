<?php

namespace App\Controllers\Api;

/**
 * The app must render About/Terms/Privacy/Refund/Shipping natively
 * in-app rather than opening the web frontend's pages, since that web
 * frontend is slated for deletion once the app ships. Content here
 * mirrors app/Views/customer/pages/*.php (kept in sync manually - there
 * are only five of these and they change rarely).
 *
 * Pass ?lang=ta for Tamil; anything else (or omitted) returns English.
 */
class StaticContentApiController extends BaseApiController
{
    private function lang(): string
    {
        return $this->request->getGet('lang') === 'ta' ? 'ta' : 'en';
    }

    public function about()
    {
        if ($this->lang() === 'ta') {
            return $this->ok(['title' => 'எங்களைப் பற்றி', 'updated' => null, 'sections' => [
                ['heading' => null, 'body' => 'Jeevi Foodie Delivery சேலம் மாவட்டம் முழுவதும் உள்ள சிறந்த உள்ளூர் உணவகங்களை உங்களுடன் இணைக்கிறது, சுவையான உணவையும் நல்ல மனநிலையையும் உங்கள் வீட்டு வாசலுக்கே கொண்டு வருகிறது.'],
                ['heading' => null, 'body' => 'ஒவ்வொரு ஆர்டரும் புதியதாகவும், விரைவாகவும், கவனத்துடனும் வந்து சேர நம்பகமான உள்ளூர் உணவகங்கள் மற்றும் அர்ப்பணிப்புள்ள டெலிவரி பார்ட்னர்கள் குழுவுடன் நாங்கள் இணைந்து செயல்படுகிறோம். உங்கள் ஆர்டர் செய்யப்பட்ட நேரம் முதல் அது சென்றடையும் வரை எங்கள் நேரடி கண்காணிப்பு உங்களை புதுப்பித்த நிலையில் வைத்திருக்கும்.'],
                ['heading' => null, 'body' => 'விரைவான மதிய உணவோ, குடும்ப இரவு உணவோ, அல்லது நள்ளிரவு பசியோ - Jeevi எப்போதும் உங்களுக்காக இருக்கிறது - நல்ல உணவு, நல்ல மனநிலை, எப்போதும்.'],
            ]]);
        }
        return $this->ok(['title' => 'About Us', 'updated' => null, 'sections' => [
            ['heading' => null, 'body' => 'Jeevi Foodie Delivery connects you with the best local restaurants across Salem district, bringing good food and great mood straight to your door.'],
            ['heading' => null, 'body' => 'We partner with trusted local restaurants and a dedicated team of delivery partners to make sure every order arrives fresh, fast, and with care. Our live tracking keeps you updated from the moment your order is placed until it reaches you.'],
            ['heading' => null, 'body' => "Whether it's a quick lunch, a family dinner, or a late-night craving, Jeevi is here to deliver - good food, great mood, every time."],
        ]]);
    }

    public function terms()
    {
        if ($this->lang() === 'ta') {
            return $this->ok(['title' => 'விதிமுறைகள் & நிபந்தனைகள்', 'updated' => date('F Y'), 'sections' => [
                ['heading' => '1. Jeevi ஐ பயன்படுத்துதல்', 'body' => 'Jeevi Foodie Delivery மூலம் ஆர்டர் செய்வதன் மூலம், சரியான டெலிவரி விவரங்களை வழங்கவும், குறிப்பிட்ட முகவரி மற்றும் நேரத்தில் உங்கள் ஆர்டரைப் பெற கிடைக்கவும் ஒப்புக்கொள்கிறீர்கள்.'],
                ['heading' => '2. ஆர்டர்கள் & விலை', 'body' => 'மெனு விலைகள், கிடைக்கும் தன்மை மற்றும் உணவக இயங்கு நேரங்கள் ஒவ்வொரு பங்குதாரர் உணவகத்தாலும் நிர்ணயிக்கப்படுகின்றன, முன்னறிவிப்பு இல்லாமல் மாறலாம். டெலிவரி கட்டணங்கள், கூப்பன்கள் மற்றும் வரிகள் பணம் செலுத்தும் முன் செக்அவுட்டில் காட்டப்படும்.'],
                ['heading' => '3. டெலிவரி', 'body' => 'மதிப்பிடப்பட்ட டெலிவரி நேரங்கள் தோராயமானவை, போக்குவரத்து, வானிலை அல்லது ஆர்டர் அளவைப் பொறுத்து மாறுபடலாம். நாங்கள் தற்போது சேலம் மாவட்டத்திற்குள் மட்டுமே டெலிவரி செய்கிறோம்.'],
                ['heading' => '4. பணம் செலுத்துதல்', 'body' => 'Cash on Delivery, UPI மற்றும் Card பணம் செலுத்துதல்களை Razorpay மூலம் பாதுகாப்பாக ஏற்கிறோம். உங்கள் கார்டு விவரங்களை நாங்கள் சேமிக்க மாட்டோம்.'],
                ['heading' => '5. ரத்து செய்தல்', 'body' => 'உணவகம் தயாரிப்பை உறுதிப்படுத்தும் முன் ஆர்டர்களை ரத்து செய்யலாம். தயாரிப்பு தொடங்கிய பிறகு, ரத்து செய்தல் சாத்தியமில்லாமல் போகலாம் - விவரங்களுக்கு எங்கள் Refund Policy-ஐப் பார்க்கவும்.'],
                ['heading' => '6. நடத்தை', 'body' => 'எங்கள் டெலிவரி பார்ட்னர்கள் மற்றும் உணவக ஊழியர்களை மரியாதையுடன் நடத்தவும். எங்கள் குழுவிடம் முரட்டுத்தனமான நடத்தை கணக்கு நிறுத்தப்படுவதற்கு வழிவகுக்கும்.'],
            ]]);
        }
        return $this->ok(['title' => 'Terms & Conditions', 'updated' => date('F Y'), 'sections' => [
            ['heading' => '1. Using Jeevi', 'body' => 'By placing an order through Jeevi Foodie Delivery, you agree to provide accurate delivery details and to be available to receive your order at the address and time indicated.'],
            ['heading' => '2. Orders & Pricing', 'body' => 'Menu prices, availability, and restaurant operating hours are set by each partner restaurant and may change without notice. Delivery fees, coupons, and taxes are shown at checkout before you confirm payment.'],
            ['heading' => '3. Delivery', 'body' => 'Estimated delivery times are approximate and can vary due to traffic, weather, or order volume. We currently deliver only within Salem district.'],
            ['heading' => '4. Payments', 'body' => 'We accept Cash on Delivery, UPI, and Card payments processed securely through Razorpay. We do not store your card details.'],
            ['heading' => '5. Cancellations', 'body' => 'Orders may be cancelled before a restaurant confirms preparation. Once preparation begins, cancellation may not be possible - please see our Refund Policy for details.'],
            ['heading' => '6. Conduct', 'body' => 'Please treat our delivery partners and restaurant staff with respect. Abusive behavior towards our team may result in account suspension.'],
        ]]);
    }

    public function privacy()
    {
        if ($this->lang() === 'ta') {
            return $this->ok(['title' => 'தனியுரிமைக் கொள்கை', 'updated' => date('F Y'), 'sections' => [
                ['heading' => 'நாங்கள் சேகரிக்கும் தகவல்', 'body' => 'எங்கள் டெலிவரி சேவையை வழங்க உங்கள் பெயர், தொலைபேசி எண், மின்னஞ்சல், டெலிவரி முகவரி மற்றும் ஆர்டர் வரலாற்றை நாங்கள் சேகரிக்கிறோம். உங்கள் டெலிவரி இருப்பிடம் உங்கள் ஆர்டரை route செய்ய மட்டுமே பயன்படுத்தப்படுகிறது, செயலில் உள்ள டெலிவரிகளின் போது உங்கள் டெலிவரி பார்ட்னருடன் மட்டும் பகிரப்படுகிறது.'],
                ['heading' => 'உங்கள் தகவலை நாங்கள் எவ்வாறு பயன்படுத்துகிறோம்', 'body' => 'உங்கள் தகவல் ஆர்டர்களை செயலாக்க, நேரடி ஆர்டர் கண்காணிப்பை வழங்க, ஆர்டர் புதுப்பிப்புகளைத் தெரிவிக்க மற்றும் எங்கள் சேவையை மேம்படுத்த பயன்படுத்தப்படுகிறது. உங்கள் தனிப்பட்ட தகவலை நாங்கள் மூன்றாம் தரப்பினருக்கு விற்க மாட்டோம்.'],
                ['heading' => 'பணம் செலுத்தும் தகவல்', 'body' => 'Card மற்றும் UPI பணம் செலுத்துதல்கள் எங்கள் பணம் செலுத்தும் பங்குதாரரான Razorpay மூலம் நேரடியாக செயலாக்கப்படுகின்றன. உங்கள் முழு கார்டு விவரங்களை நாங்கள் ஒருபோதும் பார்க்கவோ சேமிக்கவோ மாட்டோம்.'],
                ['heading' => 'உங்கள் தேர்வுகள்', 'body' => 'உங்கள் Profile பக்கத்தில் இருந்து எப்போது வேண்டுமானாலும் உங்கள் சுயவிவர விவரங்களை புதுப்பிக்கலாம் அல்லது சேமிக்கப்பட்ட முகவரியை நீக்கலாம். முழு கணக்கு நீக்கத்தைக் கோர, தயவுசெய்து support-ஐ தொடர்பு கொள்ளவும்.'],
            ]]);
        }
        return $this->ok(['title' => 'Privacy Policy', 'updated' => date('F Y'), 'sections' => [
            ['heading' => 'Information We Collect', 'body' => 'We collect your name, phone number, email, delivery address, and order history to provide our delivery service. Your delivery location is used only to route your order and is shared with your assigned delivery partner during active deliveries.'],
            ['heading' => 'How We Use Your Information', 'body' => 'Your information is used to process orders, provide live order tracking, communicate order updates, and improve our service. We do not sell your personal information to third parties.'],
            ['heading' => 'Payment Information', 'body' => 'Card and UPI payments are processed directly by Razorpay, our payment partner. We never see or store your full card details.'],
            ['heading' => 'Your Choices', 'body' => 'You can update your profile details or delete a saved address at any time from your Profile page. To request full account deletion, please contact support.'],
        ]]);
    }

    public function refundPolicy()
    {
        if ($this->lang() === 'ta') {
            return $this->ok(['title' => 'பணத்தை திரும்பப்பெறும் கொள்கை', 'updated' => date('F Y'), 'sections' => [
                ['heading' => 'திரும்பப்பெற தகுதியானவை', 'body' => "• உணவகம் தயாரிக்கத் தொடங்கும் முன் ரத்து செய்யப்பட்ட ஆர்டர்\n• தவறான பொருட்கள் டெலிவரி செய்யப்பட்டது\n• நியாயமான நேரத்திற்குள் டெலிவரி செய்யப்படாமல், தொலைந்ததாக உறுதிப்படுத்தப்பட்ட ஆர்டர்"],
                ['heading' => 'திரும்பப்பெற தகுதியற்றவை', 'body' => "• உணவகம் உங்கள் ஆர்டரைத் தயாரிக்கத் தொடங்கிய பிறகு மனம் மாறுதல்\n• வாடிக்கையாளர் வழங்கிய தவறான டெலிவரி முகவரியால் ஏற்படும் தாமதங்கள்"],
                ['heading' => 'திரும்பப்பெறுதல் எவ்வாறு செயலாக்கப்படுகிறது', 'body' => 'ஆன்லைன் பணம் செலுத்துதல்களுக்கான (UPI/Card) அங்கீகரிக்கப்பட்ட திரும்பப்பெறுதல்கள் Razorpay மூலம் உங்கள் அசல் பணம் செலுத்தும் முறைக்கு வழக்கமாக 5-7 வேலை நாட்களில் கிரெடிட் செய்யப்படும். Cash on Delivery ஆர்டர்களுக்கு திரும்பப்பெறுதல் பொருந்தாது, ஏனெனில் பணம் டெலிவரியின் போது மட்டுமே சேகரிக்கப்படுகிறது.'],
                ['heading' => 'திரும்பப்பெறுதலைக் கோருதல்', 'body' => 'உங்கள் Profile மெனுவில் உள்ள Help & Support விருப்பம் மூலம் உங்கள் ஆர்டர் எண்ணுடன் எங்கள் support குழுவைத் தொடர்பு கொள்ளவும், நாங்கள் உங்கள் கோரிக்கையை மதிப்பாய்வு செய்வோம்.'],
            ]]);
        }
        return $this->ok(['title' => 'Refund Policy', 'updated' => date('F Y'), 'sections' => [
            ['heading' => 'Eligible for Refund', 'body' => "• Order cancelled before the restaurant begins preparing it\n• Wrong items delivered\n• Order not delivered within a reasonable time and confirmed lost"],
            ['heading' => 'Not Eligible for Refund', 'body' => "• Change of mind after the restaurant has started preparing your order\n• Delays caused by an incorrect delivery address provided by the customer"],
            ['heading' => 'How Refunds Are Processed', 'body' => 'Approved refunds for online payments (UPI/Card) are credited back to your original payment method via Razorpay, typically within 5-7 business days. Cash on Delivery orders are not applicable for refunds since payment is collected only on delivery.'],
            ['heading' => 'Requesting a Refund', 'body' => "Contact our support team via the Help & Support option in your Profile menu, with your order number, and we'll review your request."],
        ]]);
    }

    public function shippingPolicy()
    {
        if ($this->lang() === 'ta') {
            return $this->ok(['title' => 'டெலிவரி கொள்கை', 'updated' => date('F Y'), 'sections' => [
                ['heading' => 'டெலிவரி பகுதி', 'body' => 'Jeevi Foodie Delivery தற்போது சேலம் மாவட்டத்திற்குள் மட்டுமே டெலிவரி செய்கிறது. செக்அவுட்டின் போது, எங்கள் சேவை எல்லைக்குள் வரைபடத்தில் ஒரு டெலிவரி இருப்பிடத்தைத் தேர்ந்தெடுக்க வேண்டும்.'],
                ['heading' => 'டெலிவரி நேரம்', 'body' => 'மதிப்பிடப்பட்ட டெலிவரி நேரம் உங்கள் ஆர்டர் கண்காணிப்பு பக்கத்தில் காட்டப்படும், பொதுவாக உணவக தயாரிப்பு நேரம் மற்றும் உங்கள் இருப்பிடத்திற்கான தூரத்தைப் பொறுத்து 20-40 நிமிடங்கள் ஆகும்.'],
                ['heading' => 'டெலிவரி கட்டணம்', 'body' => '₹199-க்கு மேல் உள்ள ஆர்டர்கள் இலவச டெலிவரிக்கு தகுதி பெறுகின்றன. சிறிய ஆர்டர்களுக்கு ₹30 நேரடி டெலிவரி கட்டணம் பொருந்தும்.'],
                ['heading' => 'நேரடி கண்காணிப்பு', 'body' => 'உங்கள் ஆர்டர் டெலிவரிக்கு புறப்பட்டவுடன், உங்கள் Order Tracking பக்கத்தில் இருந்து உங்கள் டெலிவரி பார்ட்னரின் நேரடி இருப்பிடத்தை கண்காணிக்கலாம்.'],
            ]]);
        }
        return $this->ok(['title' => 'Shipping / Delivery Policy', 'updated' => date('F Y'), 'sections' => [
            ['heading' => 'Delivery Area', 'body' => "Jeevi Foodie Delivery currently delivers only within Salem district. During checkout, you'll need to pick a delivery location on the map within our serviceable boundary."],
            ['heading' => 'Delivery Time', 'body' => "Estimated delivery time is shown on your order tracking page and typically ranges from 20-40 minutes, depending on the restaurant's preparation time and distance to your location."],
            ['heading' => 'Delivery Fee', 'body' => 'Orders above ₹199 qualify for free delivery. A flat delivery fee of ₹30 applies to smaller orders.'],
            ['heading' => 'Live Tracking', 'body' => "Once your order is out for delivery, you can track your delivery partner's live location from your Order Tracking page."],
        ]]);
    }
}
